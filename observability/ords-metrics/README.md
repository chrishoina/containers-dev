# ORDS metrics and OCI logging

This project documents two separate telemetry paths for ORDS:

- ORDS Standalone access logs → ords-metrics → OCI Monitoring custom metrics and alarms.
- ORDS Java application logs in JSON → OCI Unified Monitoring Agent → OCI Logging custom logs and Log Search.
- Optional raw-log delivery: OCI Logging → Connector Hub → OCI Streaming. This forwards log records, not ords-metrics metric points.

## Prerequisites

- Use the ORDS distribution and ords-metrics utility from the same pinned ORDS release. This guide follows the [ORDS 26.3 deployment and monitoring guide](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/26.3/ordig/deploying-and-monitoring-oracle-rest-data-services.html#GUID-6470993D-B904-46B8-ABAB-DFAF8CF7F258).
- Decide the OCI region, metrics compartment, metrics namespace, resource group, log compartment, log group, and log name.
- For OCI Compute, use a supported host OS and enable or install the OCI Unified Monitoring Agent (also called the Custom Logs Monitoring plugin). Agent configurations collect files through host paths; a named volume mounted only inside the container does not provide a path the host agent can use. Docker stores named-volume data on the host, but use a bind mount to expose the logs at an explicit host path.
- Compose starts Database Free and ORDS by default. An opt-in `oci-metrics` profile runs `ords-metrics`; the OCI Logging agent remains a host-managed service. For JMX groups, verify that the container runtime supports Java attach before enabling them.
- For local Compose work, use a host bind mount for logs if you need to inspect them from the host. To deliver logs to OCI Logging, the agent must run on a supported host with access to those files; macOS Compose alone does not provide that agent path.

The Compose setup covers ORDS access logs, JSON runtime log files, and the metrics exposed by `ords-metrics` (HTTP status, response time, heartbeat, and selected JMX groups). The internal diagnostics guide also calls for host and VNIC metrics, active/in-flight requests, HTTP worker saturation, front-end diagnostics, scheduled thread dumps, probes, dashboards, alarms, and traces. Those require separate OCI or platform instrumentation and are not created by this Compose project.

## 1. Enable ORDS access logs

The metrics utility needs ORDS Standalone access logs. The Compose image applies these settings at startup to the same persistent ORDS config directory used by the server:

    ords --config /etc/ords/config config set --global standalone.access.log /var/log/ords/access
    ords --config /etc/ords/config config set --global standalone.access.log.retainDays 10

The startup hook at `ords-entrypoint.d/10-configure-access-logs.sh` creates `/var/log/ords/access` and `/var/log/ords/service`, then applies the settings on each container start. It also enables `instance.api.enabled` for the ORDS instance readiness endpoint. Verify the settings with `ords --config /etc/ords/config config get --global standalone.access.log`, `ords --config /etc/ords/config config get --global standalone.access.log.retainDays`, and `ords --config /etc/ords/config config get --global instance.api.enabled`. Confirm the ORDS runtime user can write to both log directories and that they are persistent.

standalone.access.log.retainDays controls local retention. Keep rotated access logs available long enough for ords-metrics and any configured log collector to process them.

### Container and Compose note

The current Compose file bind-mounts `${ORDS_LOG_DIR:-./logs}` to `/var/log/ords`, so access logs are visible on the host under `access` and Java service logs under `service`. For OCI Compute, set an explicit persistent host path in `.env`:

    ORDS_LOG_DIR=/opt/ords-metrics/logs

Create `/opt/ords-metrics/logs` on the OCI Compute VM before starting Compose. The ORDS runtime user must be able to create and write both subdirectories, and the OCI agent must be able to read them. With this mount, `/var/log/ords/access` and `/var/log/ords/service` map to `/opt/ords-metrics/logs/access` and `/opt/ords-metrics/logs/service` on the host.

### OCI CLI in the ORDS container

Compose builds an ORDS image variant with the OCI CLI installed. The project-local `.oci` directory is mounted at `/home/oracle/.oci`, and `OCI_CLI_CONFIG_FILE` points the CLI to `/home/oracle/.oci/config`. The directory is excluded from Git and the Docker build context so it can hold the API key alongside the config without copying credentials into the image.

By default, Compose uses `./.oci`. To mount an existing OCI directory instead, set its **host directory path** in the project `.env` file:

    OCI_CONFIG_DIR=/Users/your-user/.oci

That directory must contain both `config` and the key file referenced by `key_file`. `OCI_CONFIG_DIR` is the host-side mount source; the CLI config path inside the container remains `/home/oracle/.oci/config`. In the config, use a container-resolvable key path such as `key_file=~/.oci/oci_api_key.pem`, not an absolute host path.

The mounted files must be readable by the container's `oracle:oinstall` user. After the ORDS container is running, set the group and permissions on the bind mount while preserving the host owner:

    docker compose exec --user 0 ords sh -c 'chgrp -R oinstall /home/oracle/.oci && chmod 750 /home/oracle/.oci && find /home/oracle/.oci -type f -exec chmod 640 {} +'

Run OCI CLI commands as the default `oracle` user:

    docker compose exec --user oracle ords oci --version

Start or rebuild the stack, then create or update the OCI profile in the host directory selected above. You can create it with a host OCI CLI or edit the starter file:

    docker compose up -d --build

The starter config is in `.oci/config.example`; replace its placeholder values and put the API signing key in the same host directory. Apply the group permissions above so the `oracle:oinstall` container user can read both files.

The OCI CLI version defaults to `3.68.1`. Set `OCI_CLI_VERSION` in `.env` to use another release, then rebuild the service.

## 2. Configure OCI identity for metrics publishing

Choose one authentication method:

- **OCI profile/API signing key:** create a profile in the OCI configuration file available to the OS user running ords-metrics. Restrict access to the config and private key to your user with `chmod 600 ~/.oci/config ~/.oci/oci_api_key.pem`; replace the key filename with the path configured by `key_file` if needed. Use -p <profile> when starting the utility.
- **Instance principal:** on OCI Compute, add the instance to a dynamic group and grant that group permission to publish to the chosen metric namespace. A namespace-scoped policy example is:

        Allow dynamic-group ords-metrics-publishers to use metrics in tenancy
          where target.metrics.namespace='dbtools_ords'

  Adapt the dynamic group, scope, and namespace to your tenancy policy. Omit -p when using instance principal.

These options authenticate the metrics publisher. They are separate from the OCI Logging agent's host group and Logging permissions.

## 3. Configure and run ords-metrics

The utility is included under `bin/ords-metrics` in the ORDS distribution. Its documented defaults are namespace `dbtools_ords`, resource group `ords`, access-log directory `/var/log/ords/access`, and a 60-second heartbeat. The metric compartment OCID is required. The utility accepts command-line options; the project's wrapper below reads the internal guide's config keys and translates them to those options.

### Compose publisher

The internal diagnostics guide provides the `logdir`, `namespace`, `compartment`, `resource`, `time`, `jmx`, and `pidfile` settings. This project’s `run-ords-metrics` wrapper reads those keys from `ords-metrics.conf` and passes the corresponding supported options to the ORDS utility. It also accepts `profile` for API-key authentication and `host` for a stable metric dimension.

Edit the local, Git-ignored `ords-metrics.conf` (start from `ords-metrics.conf.example` if needed). At minimum, set `compartment` to the OCID where metrics should be published. Set `profile` to a profile in the mounted `.oci/config`; leave it empty when using instance principal on OCI Compute. Set `host` to a stable node identity when the default container hostname is unsuitable. The default config enables response-time and JMX groups from the internal diagnostics guide, which is marked for ORDS team review. The guide also calls for active/in-flight request and HTTP worker saturation signals; the documented `ords-metrics` options do not expose those signals, so provide them through an approved platform or ORDS instrumentation source if required.

For OCI Compute, set both host paths in `.env`:

    ORDS_LOG_DIR=/opt/ords-metrics/logs
    OCI_CONFIG_DIR=/home/oracle/.oci

If the metrics config is stored elsewhere, set `ORDS_METRICS_CONFIG` to its host path. The default is the project-local `./ords-metrics.conf`.

The metrics service uses the same log mount and credentials, shares the ORDS process namespace and `/tmp` for JMX attach, and starts only when the `oci-metrics` Compose profile is selected:

    docker compose --profile oci-metrics up -d --build
    docker compose logs -f ords-metrics

The OCI Monitoring policy must allow the configured identity to publish metrics in the target compartment. If JMX attach is not supported by the chosen runtime, clear `jmx` while validating access-log metrics, then resolve the attach setup before enabling those groups.

If more than one ORDS process runs on the host, use the documented `-f <pidfile>` option to select the target process. Avoid high-cardinality path dimensions; only configure paths for stable base paths.

Run it interactively first, using either a profile or instance principal:

    # OCI profile/API key
    /path/to/ords/bin/ords-metrics -d /var/log/ords/access -p <profile> -c <metrics-compartment-ocid> -t -m jvm,os,thread,ucp

    # OCI Compute instance principal: omit -p
    /path/to/ords/bin/ords-metrics -d /var/log/ords/access -c <metrics-compartment-ocid> -t -m jvm,os,thread,ucp

After the foreground run publishes successfully, install it as a service on each ORDS node:

1. Copy examples/ords-metrics/ords-metrics.service from the ORDS distribution to /etc/systemd/system/ords-metrics.service.
2. Update WorkingDirectory, ExecStart, User, and Group for the installation. Put the documented `ords-metrics` options in `ExecStart`; include `-c` and use `-p <profile>` when using an OCI profile.
3. If `ExecStart` uses `-f`, create its PID file directory and make it writable by the service user. Ensure the access-log directory is readable by that user.
4. Run sudo systemctl daemon-reload, then sudo systemctl enable --now ords-metrics.
5. Check sudo systemctl status ords-metrics and the service journal for errors.

## 4. Verify metrics in OCI Monitoring

In the OCI Console, open **Observability & Management → Monitoring → Metrics Explorer** and select the metric compartment and namespace.

Check that:

- HttpStatus<code> metrics appear after requests reach ORDS.
- Heartbeat arrives at the configured interval (60 seconds by default).
- Host and any configured availability-domain, fault-domain, or path dimensions identify the expected instance.
- Response-time metrics appear when enabled with time=true or -t.
- JMX metrics appear for the selected groups: jvm, os, thread, and ucp.

Create alarms after confirming normal traffic and metric cadence. The ORDS distribution includes examples/ords-metrics/create_alarms.sh. The documented flow is to create an OCI Notifications topic, copy and customize the script's compartment, topic, and namespace values, adjust thresholds, then run it. Configure an absent-heartbeat alarm so a stopped or stuck publisher is visible.

## 5. Configure ORDS Java application logs for OCI Logging

ORDS access logs and Java application logs are separate files. ords-metrics reads the access logs. OCI Logging uses the Java Util Logging (JUL) file handler below.

Create /etc/ords/logging.properties on the ORDS host:

    handlers=java.util.logging.FileHandler,java.util.logging.ConsoleHandler
    java.util.logging.FileHandler.level=ALL
    java.util.logging.FileHandler.pattern=/var/log/ords/service/ords_service_%g.log
    java.util.logging.FileHandler.limit=10485760
    java.util.logging.FileHandler.count=10
    java.util.logging.FileHandler.append=true
    java.util.logging.FileHandler.formatter=oracle.dbtools.logging.JSONLogFormatter

Create `/var/log/ords/service`, grant the ORDS process write access, and allow the host agent read access. With `count=10`, Java rotates through generations such as `ords_service_0.log`; the separate `/var/log/ords/access` directory holds the HTTP access logs. The project `logging.properties` sets the root logger to `SEVERE` and `oracle.dbtools` to `INFO`, matching the internal diagnostics baseline.

Set this JVM option before ORDS starts:

    export JDK_JAVA_OPTIONS="-Djava.util.logging.config.file=/etc/ords/logging.properties"
    ords --config /path/to/ords/config serve

For systemd, set the equivalent Environment="JDK_JAVA_OPTIONS=..." in the ORDS service unit and restart ORDS. For Compose, use the environment variable and read-only configuration-file mount shown above. Send a test request, then confirm the file contains one JSON event per line before configuring OCI Logging.

## 6. Create the OCI Logging custom log and agent configuration

Use OCI Logging's Unified Monitoring Agent / Custom Logs Monitoring plugin on the OCI host that can read the host-mounted service log files. With the example bind mount, use `/opt/ords-metrics/logs/service/ords_service_*.log*` as the log path. This agent is configured on the OCI host and is not a Compose service.

1. In OCI Logging, create or choose a **Log Group**, then create a **Custom Log** in that group.
2. Confirm the agent is installed or the Oracle Cloud Agent's **Custom Logs Monitoring** plugin is enabled for each ORDS Compute host.
3. In **Observability & Management → Logging → Agent Configurations**, create an agent configuration and select the dynamic group or user group that identifies the target hosts.
4. Add a **Log path** input for `/opt/ords-metrics/logs/service/ords_service_*.log*`. If using Compose, enter the host path for the bind-mounted directory, not the container path.
5. Select the JSON parser and configure its timestamp handling to match the actual ORDS JSON event format. Validate the parser with a sample event.
6. Select the Log Group and Custom Log created in step 1, then enable the configuration.
7. Grant the applicable host group / agent identity the documented Logging permissions in the destination compartment. Restrict the policy to the destination compartment and log content needed by the agent.
8. In **Logging → Log Search**, query the Custom Log and confirm new events arrive with the expected timestamp and fields. Enable agent operational metrics in the agent configuration to monitor its heartbeat and emitted-record counts.

Optionally add `/opt/ords-metrics/logs/access/*` as a second log input if access-log search in OCI Logging is required. Keep it separate from the JSON service-log input and select a parser based on the actual access-log format. This is optional for ords-metrics; it must continue to read the local access-log files.

## 7. Optional: forward raw logs to OCI Streaming

If a downstream consumer needs raw ORDS application-log records in OCI Streaming, use an OCI Logging source in Connector Hub and configure OCI Streaming as the target. This sends log records, not ords-metrics metric points. Keep OCI Monitoring publication independent so Logging or Streaming delivery issues do not stop metric alarms.

## Troubleshooting checklist

- **No HttpStatus metrics:** confirm the access-log path, service-user read permission, metric compartment, OCI region/profile, and IAM namespace policy.
- **No heartbeat:** inspect the ords-metrics service journal, IAM authorization, connectivity to the regional Monitoring ingestion endpoint, and system clock.
- **No OCI log events:** confirm the application log file is host-visible, the agent configuration is active, the file path includes rotated files, permissions allow reading, and the parser matches the JSON.
- **No events after rotation:** ensure the agent path includes rotated filenames and increase ORDS retention if the agent cannot keep up.
- **Container test works but OCI Logging does not:** confirm Compose uses a persistent host bind mount on a supported OCI Compute host and configure the OCI agent with that host path.

## References

### ORDS and project guidance

- [ORDS 26.3: Deploying and Monitoring ORDS](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/26.3/ordig/deploying-and-monitoring-oracle-rest-data-services.html#GUID-6470993D-B904-46B8-ABAB-DFAF8CF7F258)
- [ORDS OCI Metrics Functional Specification — Han Shum](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=8871063672)
- [ORDS Documentation - ORDS Monitoring and Diagnostics — Han Shum](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=10697716013)
- [ORDS Diagnostics Configuration for Internal Deployments — Han Shum](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=21275930894)

### OCI services

- [OCI Monitoring: Publishing custom metrics](https://docs.oracle.com/en-us/iaas/Content/Monitoring/Tasks/publishingcustommetrics.htm)
- [OCI Monitoring: Securing Monitoring](https://docs.oracle.com/en-us/iaas/Content/Security/Reference/monitoring_security.htm)
- [OCI Logging: Agent Management Overview](https://docs.oracle.com/en-us/iaas/Content/Logging/Concepts/agent_management.htm)
- [OCI Logging: Installing the Agent](https://docs.oracle.com/en-us/iaas/Content/Logging/Task/installing_the_agent.htm)
- [OCI Logging: Creating an Agent Configuration](https://docs.oracle.com/en-us/iaas/Content/Logging/Task/create-logging-agent-configuration.htm)
- [OCI Logging: Log Inputs and Parsers](https://docs.oracle.com/en-us/iaas/Content/Logging/Concepts/log_inputs_and_parsers.htm)
- [OCI Logging: Custom Logs](https://docs.oracle.com/en-us/iaas/Content/Logging/Concepts/custom_logs.htm)

