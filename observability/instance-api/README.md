# ORDS Instance API Pool Dashboard

The ORDS Instance API endpoints used by this dashboard provide an ORDS-side view of pool health and usage. They help answer three operational questions: Are pools healthy? Which pools are present? Are requests waiting for connections?

## Endpoints

| Endpoint | Operational value |
| --- | --- |
| `/ords/_/instance-api/latest/status` | A quick health check with counts of valid and invalid pools. Use it for health monitoring, alerting, and initial triage. |
| `/ords/_/instance-api/latest/database-pools-cache/` | An inventory of pools. Use it to confirm expected pools are present and review each pool's state and connection counts. |
| `/ords/_/instance-api/latest/database-pools-cache/{pool},{type}` | Statistics for one pool. Review borrowed and available connections, pending requests, waits, failures, capacity, peaks, and other statistics to identify possible contention or behavior changes. |

## Who benefits

- **Systems administrators and SREs** can use the status endpoint for health checks and alerts, the cache endpoint to inspect the pool inventory, and per-pool details to investigate a specific pool. In a cluster, query each ORDS instance directly when comparing nodes because pool statistics can differ by instance.
- **Performance analysts and DBAs** can use per-pool statistics to look for signs of saturation, such as high borrowed connection counts, pending requests, rising connection wait times, or failed waits. Compare samples over time to see trends and assess the effect of pool configuration changes.
- **Application and platform support teams** can use the inventory and detail endpoints to narrow an incident to a specific pool before correlating it with application, ORDS JVM, or database telemetry.

## Interpreting the data

A single response is a snapshot. It shows the pool's current state, but does not establish a trend or explain the root cause by itself. Compare measurements over time and correlate pool symptoms with ORDS JVM, application, and database telemetry. Pool statistics can help identify where to investigate; they do not provide SQL-level or database-side diagnostics on their own.

## Reading pool statistics

Use these groups to interpret the per-pool statistics. Cumulative counters are most useful when comparing samples over the same interval or pool lifetime; a single value does not show a rate or trend.

| Area | Metrics to review | How they help |
| --- | --- | --- |
| **Current demand and capacity** | `borrowedConnectionsCount`, `availableConnectionsCount`, `pendingRequestsCount`, `remainingPoolCapacityCount` | Shows current use, immediately available connections, waiting requests, and room to grow. Watch pending requests across refreshes as a signal of contention. |
| **Typical and peak load** | `averageBorrowedConnectionsCount`, `peakBorrowedConnectionsCount`, `peakConnectionsCount` | Puts current use in context with typical and recorded peak load. Compare across consistent observation windows and pool resets. |
| **Wait experience** | `averageConnectionWaitTime`, `peakConnectionWaitTime`, `cumulativeSuccessfulConnectionWaitTime`, `cumulativeSuccessfulConnectionWaitCount` | Helps assess connection acquisition latency. When the successful wait count is nonzero, divide successful cumulative wait time by that count to estimate the mean wait for successful requests. |
| **Failed requests** | `cumulativeFailedConnectionWaitCount`, `cumulativeFailedConnectionWaitTime` | Shows completed waits that failed and how long they waited. These are historical counters and do not guarantee that a currently pending request will succeed. |
| **Connection turnover** | `connectionsCreatedCount`, `connectionsClosedCount` | Compare changes over time to assess connection churn. Totals alone do not show whether turnover is excessive. |
| **Borrow and return balance** | `cumulativeConnectionBorrowedCount`, `cumulativeConnectionReturnedCount`, `borrowedConnectionsCount` | Helps compare cumulative checkout and return activity with the number currently borrowed. Consider counter resets and scope when reconciling them. |
| **Connection use time** | `cumulativeConnectionUseTime`, `cumulativeConnectionBorrowedCount` | Dividing cumulative use time by borrow count estimates average checkout duration when both counters cover the same period. Use it as a workload baseline, not a pass/fail threshold. |
| **Abandoned connections** | `abandonedConnectionsCount` | Tracks abandoned connections reclaimed by the pool. A rising count can prompt a review of connection handling and abandonment settings; it does not by itself prove an application leak. |
| **Outage and failover** | `connectionCreationAttemptsSinceLastOutage`, `cumulativeConnectionCreationAttempts`, `cumulativeConnectionCreationAttemts`, `FCFProcessingInfo`, `FCFProcessingInfoProcessedOnly` | Provides context about connection creation during outages and Fast Connection Failover processing. Missing FCF details do not prove failover is disabled. If both spellings of the cumulative attempts field appear, treat them as returned API fields and do not add them together without confirming their semantics. |
| **RAC routing and affinity** | `colocationStats` (`isRacDataAffinityEnabled`, `isDataDependentRoutingEnabled`, `isRLBEnabled`, `allow INSTANCE_NAME at connection creations`), `successfulAffinityBasedBorrowCount`, `failedAffinityBasedBorrowCount`, `successfulRCLBBasedBorrowCount`, `failedRCLBBasedBorrowCount` | Shows configured routing capabilities alongside observed borrow outcomes. An enabled RLB flag alone does not show that RLB was used successfully; compare it with the corresponding counters. |
| **Connection labels** | `labeledConnectionsCount` | Shows how many pooled connections carry labels. This is useful when the application uses connection labeling to find connections with matching state; the count alone is not a load or health problem. |
| **Multitenant reuse** | `connectionRepurposeCount` | Tracks shared-pool connections repurposed across pluggable databases. It is most useful when the deployment expects cross-PDB connection reuse. |
| **Sharding** | `shardConnectionStats` | Provides per-shard connection details for shards reported by the pool. An empty result means no per-shard entries were returned; it does not by itself prove sharding is disabled. |


The Instance API requires the ORDS **System Administrator** role. It returns information about ORDS pools and does not provide direct database access.

For more details, see Oracle's [ORDS monitoring guide](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/26.3/ordig/deploying-and-monitoring-oracle-rest-data-services.html).
