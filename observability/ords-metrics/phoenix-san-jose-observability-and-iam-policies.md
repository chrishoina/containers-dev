# Phoenix and San Jose Observability Comparison and IAM Policies

This guide compares the logging, metrics, namespaces, and alarm settings in the Phoenix and San Jose Terraform stacks. It also provides compartment-scoped IAM policy templates for instance principals and identifies configuration alignment checks in the ORDS metrics project.

## Stack comparison

| Area | Phoenix stack | San Jose stack |
|---|---|---|
| Log groups | `error` and `access` | `ords` |
| Logs | 13 enabled logs, all with 30-day retention: 12 OCI service logs and one custom ORDS access log | Two enabled custom logs, `service` and `access`, each with 30-day retention |
| Unified agent configurations | One enabled ORDS access-log configuration | Two enabled configurations: ORDS service logs and access logs |
| Metrics and alarms | Five alarms query the `ords_metrics` namespace | No OCI Monitoring alarm resources or ORDS metric namespace are defined |
| Alarm notification | All five alarms use the existing `temp-topic` Notifications topic | No Notifications topic or alarm destination is defined |

### Logs and log groups

Phoenix places nine service logs in the `error` group: load-balancer logs, flow logs for two subnets, and Network Firewall tunnel, traffic, and threat logs. Four logs are in `access`: three load-balancer access logs and the custom ORDS access log. One access-category log, `mylb11_access`, is assigned to the `error` group.

San Jose uses one `ords` group for two custom logs, `service` and `access`. It does not define OCI service logs for load balancers, subnets, or Network Firewall.

### Unified agent configurations

| Stack and configuration | Source path | Destination | Parser |
|---|---|---|---|
| Phoenix `ords-access-log-agent-configuration` | `/var/log/ords/access/*` | Custom log `ords-access` | JSON; `parse_nested=false`, `time_type=FLOAT`; estimates current event time |
| San Jose `ords-service-config` | `/var/log/ords/service/ords.log.*` | Custom log `service` | JSON; `parse_nested=false`, `time_type=FLOAT` |
| San Jose `access-log-config` | `/var/log/ords/access/*.log` | Custom log `access` | `NONE` |

Each agent configuration is enabled and associated with a dynamic group. The Phoenix access path matches any filename; the San Jose path matches only files ending in `.log`. Phoenix parses access records as JSON; San Jose leaves them unparsed.

### Metrics and alarms

Phoenix defines five enabled alarms. Each evaluates a one-minute count query, has a one-minute pending duration, a three-minute evaluation slack, and one-minute resolution.

| Alarm | Query threshold | Severity |
|---|---|---|
| 500 Internal Server Error Alert | `HttpStatus500[1m].grouping().count() > 10` | CRITICAL |
| 503 Service Unavailable Alert | `HttpStatus503[1m].grouping().count() > 10` | CRITICAL |
| 571 Database Connection Error Alert | `HttpStatus571[1m].grouping().count() > 10` | ERROR |
| 572 Recoverable Database Error Alert | `HttpStatus572[1m].grouping().count() > 50` | WARNING |
| 578 Database Error Alert | `HttpStatus578[1m].grouping().count() > 10` | ERROR |

All five use metric namespace `ords_metrics`, resource group `ords`, rule `base`, and the `temp-topic` topic. The Terraform defines alarm queries but does not define a resource that publishes the ORDS metric datapoints.

### Alignment checks with the ORDS metrics project

- The Phoenix alarms query `ords_metrics`. The project `ords-metrics.conf` sets `namespace=dbtools_ords`. Confirm the running publisher emits to `ords_metrics`, or align the alarm namespace and IAM condition with the namespace actually used.
- The project README configures Java service-log filenames like `ords_service_%g.log` and recommends an agent path like `ords_service_*.log*`. San Jose watches `/var/log/ords/service/ords.log.*`. Confirm the deployed filename pattern matches the agent path.

## IAM policy templates for instance principals

The Terraform stacks reference dynamic groups by OCID but do not include their IAM names or policy definitions:

- Phoenix agent group OCID: `ocid1.dynamicgroup.oc1..aaaaaaaali72ca3ayfj6fdk72iwslvjpvgkong5rpd3uzf5sanspnkw6b5ya`
- San Jose agent group OCID: `ocid1.dynamicgroup.oc1..aaaaaaaajwxo44zcocs6274csb7dazy64uxkpl35uqojhp5gaai6vuwr4lda`

OCI policy statements refer to the dynamic group by its IAM name, not its OCID. Apply the templates in the tenancy that owns each group. Replace `<DG_NAME>` with that group's name and `<COMPARTMENT_NAME>` with the compartment containing the stack resources. The stacks use the same compartment for their alarm and metric compartments. If those compartments differ in a deployment, scope each statement to the corresponding compartment.

### Publish and query ORDS metrics; create and read alarms

Use this block for the Phoenix publisher and alarm principal when it publishes custom metrics and creates or reads alarms:

```text
Allow dynamic-group <DG_NAME> to use metrics in compartment <COMPARTMENT_NAME> where target.metrics.namespace='ords_metrics'
Allow dynamic-group <DG_NAME> to read metrics in compartment <COMPARTMENT_NAME> where target.metrics.namespace='ords_metrics'
Allow dynamic-group <DG_NAME> to {ALARM_INSPECT, ALARM_READ, ALARM_CREATE} in compartment <COMPARTMENT_NAME>
Allow dynamic-group <DG_NAME> to use ons-topics in compartment <COMPARTMENT_NAME>
```

`use metrics` permits publishing custom metric data; `read metrics` permits metric queries. The `ALARM_CREATE` grant requires access to the metric namespace used by the alarm query. `use ons-topics` lets the principal select the existing topic as an alarm destination. Add `ALARM_UPDATE` if it must update alarms. Add `ALARM_DELETE` only if it must delete alarms. Creating a topic requires `manage ons-topics` instead of `use ons-topics`.

San Jose currently has no alarm or `ords_metrics` configuration, so it needs these Monitoring grants only if that functionality is added. If the deployed publisher uses `dbtools_ords`, change the namespace condition and alarm configuration to match.

### Ship logs with the existing agent configurations

The instance principal used by each custom-log agent needs:

```text
Allow dynamic-group <DG_NAME> to use log-content in compartment <COMPARTMENT_NAME>
```

`use log-content` allows the agent to obtain its configuration and push logs. It also includes log-content read access. The existing agents do not need permission to create log groups or agent configurations just to ship their configured files.

### Create, read, and update logging resources

If the instance principal itself creates or updates log groups, logs, or unified agent configurations, add:

```text
Allow dynamic-group <DG_NAME> to {LOG_GROUP_INSPECT, LOG_GROUP_READ, LOG_GROUP_CREATE, LOG_GROUP_UPDATE} in compartment <COMPARTMENT_NAME>
Allow dynamic-group <DG_NAME> to {UNIFIED_AGENT_CONFIG_INSPECT, UNIFIED_AGENT_CONFIG_READ, UNIFIED_AGENT_CONFIG_CREATE, UNIFIED_AGENT_CONFIG_UPDATE} in compartment <COMPARTMENT_NAME>
Allow dynamic-group <DG_NAME> to {IDENTITY_DYNAMIC_GROUP_INSPECT} in tenancy
```

These permission sets allow create, list/read, and update without delete. The identity inspection grant is needed when creating an agent configuration assigned to a dynamic group. To restrict access to a specific existing log group, add a condition such as `where target.loggroup.id='<LOG_GROUP_OCID>'` to the applicable `log-groups` or `log-content` statement. Group OCIDs must be obtained from the deployed resources.

### Enable OCI service logs

Creating or enabling service logs also requires permissions on the source resource. For Phoenix VCN Flow Logs, Oracle specifies subnet read and update permissions in addition to Logging permissions:

```text
Allow dynamic-group <DG_NAME> to {SUBNET_READ, SUBNET_UPDATE} in compartment <COMPARTMENT_NAME>
```

Load Balancer and Network Firewall log configuration can likewise require source-service permissions. Grant only the source-resource permissions required by the operations the instance principal performs.

## Oracle references

- [Monitoring policy reference](https://docs.oracle.com/en-us/iaas/Content/Identity/policyreference/monitoringpolicyreference.htm)
- [Securing Monitoring and alarm policy examples](https://docs.oracle.com/en-us/iaas/Content/Security/Reference/monitoring_security.htm)
- [Logging policy reference](https://docs.oracle.com/en-us/iaas/Content/Identity/policyreference/loggingpolicyreference.htm)
- [Logs and Log Groups IAM requirements](https://docs.oracle.com/en-us/iaas/Content/Logging/Task/managinglogs.htm)
- [Managing Monitoring Agent Configurations](https://docs.oracle.com/en-us/iaas/Content/Monitoring/Tasks/agent-configurations.htm)
