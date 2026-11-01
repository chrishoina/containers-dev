# ORDS with OpenTelemetry and Grafana LGTM

This is a local learning and proof-of-concept stack for seeing telemetry from Oracle REST Data Services (ORDS). Docker Compose starts Oracle AI Database Free, ORDS, and Grafana LGTM. The OpenTelemetry Java agent runs inside the ORDS Java process, so ORDS does not need application code changes to emit its standard telemetry.

## What you get

The stack collects three kinds of telemetry:

- **Traces** show one request as a sequence of timed operations. Use them to see how long an ORDS HTTP request took and, when the request accesses the database, which database operations happened underneath it.
- **Metrics** are measurements collected over time. The supplied dashboard includes HTTP request rate, p95 latency, JVM CPU and memory, and ORDS connection-pool metrics.
- **Logs** are individual runtime messages. ORDS uses Java Util Logging (JUL); the Java agent bridges those records into OpenTelemetry logs.

Grafana is the browser interface. In this LGTM image, the bundled OpenTelemetry Collector receives OTLP data, Tempo stores traces, Prometheus stores metrics, and Loki stores logs. OTLP is the OpenTelemetry protocol used to send those signals. The dashboard is provisioned when Grafana starts, so you do not need to import it by hand.

The dashboard is adapted from the ORDS observability example in [anders-swanson/oracle-database-code-samples](https://github.com/anders-swanson/oracle-database-code-samples/tree/main/oracledb-e2e-observability).

## Before you start

- Install Docker Desktop or Docker Engine with Docker Compose v2.
- Sign in to [Oracle Container Registry](https://container-registry.oracle.com/) with an Oracle account. Accept the terms for the `database/free` and `database/ords` images, then authenticate Docker from a terminal:

  ```sh
  docker login container-registry.oracle.com
  ```

  Docker prompts for your registry username and password. It stores the login for Docker to use when it pulls the Oracle images.
- The first ORDS image build downloads the pinned OpenTelemetry Java agent from GitHub Releases and verifies its SHA-256 checksum, so the build needs network access to GitHub.
- Oracle Database Free uses more memory than the other services. If Docker Desktop reports that a container exits or becomes unhealthy during database startup, make sure Docker has enough memory allocated; 8 GB is a practical starting point for this full local stack.

## Recommended container VM settings

For this full local stack, start with these Docker Desktop settings under **Settings → Resources**:

- **CPU:** 4 virtual CPUs.
- **Memory:** 8 GiB.
- **Disk:** at least 30 GB available for container images and named volumes. Leave more space if you plan to keep database data or many downloaded images.

These are practical starting values for the whole stack. Oracle Database Free is limited internally to two processing cores and 2 GiB of RAM; ORDS, Grafana LGTM, and the container VM need resources too. Leave enough memory for macOS or your host operating system and other open applications. On a host with 16 GB of RAM, allocating 8 GB to Docker is a reasonable starting point. See [Docker Desktop resource settings](https://docs.docker.com/desktop/settings-and-maintenance/settings/) and [Oracle Database Free resource limits](https://docs.oracle.com/en/database/oracle/oracle-database/26/xeinw/licensing-restrictions.html).

## Start the stack

Open a terminal in this directory. If you do not already have a `.env` file, create one from the sample. The `-n` option leaves an existing `.env` unchanged:

```sh
cp -n .env.example .env
```

For a new setup, open `.env` in a text editor and replace the two sample passwords with local demo passwords. `ORACLE_PWD` sets the database administrator password; `ORACLE_USER_PWD` is used by the ORDS container during setup. Keep `.env` on your machine: it is ignored by Git.

Start the services in the background and check their status:

```sh
docker compose up -d
docker compose ps
```

Compose builds a small custom ORDS image from `ords/Dockerfile`. The build downloads OpenTelemetry Java agent 2.33.1 and checks its SHA-256 checksum. The image replaces the ORDS command with a wrapper that adds the agent only when ORDS starts `serve`; database connection checks and installation commands run without the agent. This avoids applying `JAVA_TOOL_OPTIONS` to every Java process launched during container setup.

The first database startup and ORDS installation can take several minutes. ORDS starts after the database and Grafana LGTM report healthy. The `db`, `grafana-lgtm`, and `ords` services have health checks; wait until they show `healthy` before sending requests. To follow startup messages, run:

```sh
docker compose logs -f db ords grafana-lgtm
```

Press **Ctrl+C** to stop following the logs. This does not stop the services.

## Open Grafana and ORDS

Open these local addresses in a browser:

- Grafana: <http://localhost:3000/> — sign in with the LGTM image's local demo account `admin` / `admin`.
- ORDS: <http://localhost:8080/ords/>.

In Grafana, open **Dashboards → ORDS → ORDS observability**. The dashboard refreshes every 10 seconds and initially shows the last 15 minutes. It has panels for:

- HTTP request rate, split by response status.
- HTTP p95 latency. P95 means 95% of measured requests finished in this time or less.
- UCP connection usage and requests waiting for a connection.
- ORDS JVM memory and CPU.
- ORDS runtime logs.

The Grafana page may initially show “No data.” Metrics are exported every 15 seconds, and rate/latency calculations need samples over time. Make requests as described below and allow about a minute for charts to fill in.

## Send a request and find its trace

The included public-properties URL is a database-independent ORDS endpoint. It is useful for a first check that ORDS accepts an HTTP request and OpenTelemetry sends a trace:

```sh
curl -i http://localhost:8080/ords/_/public-properties/
```

In Grafana, open **Explore**, choose **Tempo**, and search for the service `ords`. Open a recent trace to inspect its HTTP span and duration. A span is one timed operation within a trace.

The ORDS health check also requests this endpoint every 15 seconds, so it can create a small amount of background HTTP telemetry. To make the request-rate and latency charts easier to read, send requests continuously in another terminal:

```sh
while true; do curl --silent --output /dev/null http://localhost:8080/ords/_/public-properties/; sleep 1; done
```

Press **Ctrl+C** to stop the loop.

## Understand what the dashboard can show

The public-properties endpoint does not borrow a database connection. It can populate HTTP and JVM panels and produce HTTP traces, but it will not produce JDBC child spans or UCP pool metrics. Those panels need a database-backed ORDS endpoint. This Compose project does not create a REST-enabled schema or table.

The agent exports ORDS Java Util Logging records to Loki. In Grafana, open **Explore**, choose **Loki**, and use the query `{service_name="ords"}` to find them. Logs emitted while an HTTP trace is active can include trace context, which helps connect a log to its trace. Startup messages generally have no request trace. HTTP access-log files are separate from JUL records and are not collected by this setup.

## How the configuration fits together

- `ords/serve-with-agent.sh` wraps the ORDS command and adds `--java-options "-javaagent:…"` only when the command is `serve`. Startup checks and installation do not load the agent.
- `OTEL_SERVICE_NAME=ords` labels telemetry so you can find the ORDS service in Grafana.
- `OTEL_*_EXPORTER=otlp` turns on exporting for traces, metrics, and logs.
- `OTEL_EXPORTER_OTLP_ENDPOINT=http://grafana-lgtm:4318` points ORDS to Grafana LGTM using the Compose service name. Containers use this name to reach each other; `localhost` inside the ORDS container would refer back to ORDS itself.
- The Java agent exports HTTP/protobuf. The OTLP ports published on the host (`4317` and `4318`) are available if you later want to send telemetry from another host-side instrumented program.
- The dashboard and provisioning file under `grafana/` tell Grafana which dashboard JSON to load at startup. JSON does not support comments, so panel descriptions explain the dashboard queries in Grafana itself.

## Local ports

All published ports are bound to `127.0.0.1`, which makes them available from this computer only:

| Service | Address | Purpose |
| --- | --- | --- |
| Grafana | `http://localhost:3000` | Dashboard, Explore, and data-source UI |
| ORDS | `http://localhost:8080/ords/` | REST services |
| Oracle Database | `localhost:1521/FREEPDB1` | Local database listener |
| OTLP/gRPC | `localhost:4317` | Telemetry receiver for host-side apps using gRPC |
| OTLP/HTTP | `localhost:4318` | Telemetry receiver for host-side apps using HTTP/protobuf |

The internal ORDS-to-LGTM connection uses `http://grafana-lgtm:4318`; it does not go through the host-published port.

If one of these host ports is already in use, change its value in `.env` and run `docker compose up -d` again. For example, `GRAFANA_PORT=3001` makes Grafana available at `http://localhost:3001`.

## Stop or reset

Stop and remove the containers while keeping the database, ORDS configuration, and Java agent volumes. The next `docker compose up -d` reuses them:

```sh
docker compose down
```

### Start with clean service data

Use this when you want the stack to initialize from scratch, for example after changing the database setup or recovering from a bad volume state. This deletes the local database files and ORDS configuration, so any database data in this Compose project will be lost. Your `.env` file and downloaded container images are kept. The verified Java agent is part of the custom ORDS image, so removing volumes does not remove it.

From the project directory, remove the containers, named volumes, and orphan containers, then start the stack again:

```sh
docker compose down --volumes --remove-orphans
docker compose up -d
docker compose ps
```

The first startup initializes the database and installs ORDS, which can take several minutes. Compose reuses the custom ORDS image, including its verified Java agent, after a volume reset. To force a fresh image build and re-download the agent, run `docker compose build --no-cache ords` before starting the services. Follow startup logs if you want to see progress:

```sh
docker compose logs -f db ords grafana-lgtm
```

Press **Ctrl+C** to stop following logs; the services continue running. Grafana LGTM has no persistent volume in this setup, so its telemetry is also discarded when its container is removed.

## Troubleshooting

- **A container is still starting:** the initial database initialization is slow. Check `docker compose ps` and `docker compose logs -f db ords grafana-lgtm`.
- **Grafana opens but charts are empty:** send requests and wait for several metric export intervals. Use a time range that includes the requests.
- **No traces in Tempo:** confirm ORDS is healthy, send the `curl` request above, then search Tempo for service `ords`. Check `docker compose logs ords grafana-lgtm` for agent or export errors. The first `docker compose up` builds the custom ORDS image; a failed download or checksum check appears in the build output.
- **UCP panels are empty:** expected until ORDS serves a request that accesses the database; the health-check endpoint does not do that.
- **The dashboard is missing:** the provisioning files are mounted into LGTM when the container starts. Check `docker compose logs grafana-lgtm`; after changing dashboard files, restart Grafana with `docker compose restart grafana-lgtm`.
- **A port is already in use:** change the corresponding port in `.env`, then run `docker compose up -d`.
- **Oracle image pull is denied:** verify that you accepted both image repository terms and completed `docker login container-registry.oracle.com`.

## References

- [OpenTelemetry Java agent configuration](https://opentelemetry.io/docs/zero-code/java/agent/configuration/)
- [Grafana OTLP LGTM Docker image](https://github.com/grafana/docker-otel-lgtm)
