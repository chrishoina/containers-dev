1. Execute the `enable audit policy.sh` script -> this creates a Unified Audit Policy named `ordstest_audit`. It uses the `enable_audit_policy.sql` script to do this.
2. Execute the `awr_snapshots.sh` script -> kicks off the `random_requests.py` script. Gracefully exits once AWR snapshots are complete. 
3. The `extract_sqlid_sqlmodule.sh` script can be run right after the `awr_snapshots.sh` file is complete.

A fully automated, end-to-end performance testing framework.

Starts with user requirements.

Instruments the database (Auditing).

Simulates real-world load.

Measures performance (AWR).

Analyzes the "bad" SQL.

Attributes it to specific users.

Packages everything for review.

Directory structure: 

ords_testing_automate/
├── run_test_suite.sh          <-- THE BRAIN
├── files_output/              <-- THE RESULTS (Reports + CSVs)
├── main/
│   ├── py_rx/ (Workloads)
│   ├── sh_rx/ (Automation Scripts)
│   └── sql_rx/ (Database Logic)
└── test/ (Unit Tests)


TODO:

Look at this SQL next:

```sql
SELECT
  sql_id,
  parsing_schema_name,
  module,
  executions_total,
  executions_delta,
  PLSEXEC_TIME_TOTAL,
PLSEXEC_TIME_DELTA,
JAVEXEC_TIME_TOTAl,
JAVEXEC_TIME_DELTA
FROM dba_hist_sqlstat
WHERE sql_id = ' ';
```


https://docs.oracle.com/en/database/oracle/oracle-database/18/refrn/UNIFIED_AUDIT_TRAIL.html#GUID-B7CE1C02-2FD4-47D6-80AA-CF74A60CDD1D

SQL> describe UNIFIED_AUDIT_TRAIL;

Name                   Null?    Type              
______________________ ________ _________________ 
AUDIT_TYPE                      VARCHAR2(64)      
SESSIONID                       NUMBER            
PROXY_SESSIONID                 NUMBER            
OS_USERNAME                     VARCHAR2(128)     
USERHOST                        VARCHAR2(128)     
TERMINAL                        VARCHAR2(30)      
INSTANCE_ID                     NUMBER            
DBID                            NUMBER            
AUTHENTICATION_TYPE             VARCHAR2(1024)    
DBUSERNAME                      VARCHAR2(128)     
DBPROXY_USERNAME                VARCHAR2(128)     
EXTERNAL_USERID                 VARCHAR2(1024)    
GLOBAL_USERID                   VARCHAR2(32)      
CLIENT_PROGRAM_NAME             VARCHAR2(84)      
DBLINK_INFO                     VARCHAR2(4000)    
XS_USER_NAME                    VARCHAR2(128)     
XS_SESSIONID                    RAW(33 BYTE)      
ENTRY_ID                        NUMBER            
STATEMENT_ID                    NUMBER            
EVENT_TIMESTAMP                 TIMESTAMP(6)      
EVENT_TIMESTAMP_UTC             TIMESTAMP(6)      
ACTION_NAME                     VARCHAR2(64)      
RETURN_CODE                     NUMBER            
OS_PROCESS                      VARCHAR2(16)      
TRANSACTION_ID                  RAW(8 BYTE)       
SCN                             NUMBER            
EXECUTION_ID                    VARCHAR2(64)      
OBJECT_SCHEMA                   VARCHAR2(128)     
OBJECT_NAME                     VARCHAR2(128)     
SQL_TEXT                        CLOB              
SQL_BINDS                       CLOB              
APPLICATION_CONTEXTS                 VARCHAR2(4000)    
CLIENT_IDENTIFIER                    VARCHAR2(64)      
NEW_SCHEMA                           VARCHAR2(128)     
NEW_NAME                             VARCHAR2(128)     
OBJECT_EDITION                       VARCHAR2(128)     
SYSTEM_PRIVILEGE_USED                VARCHAR2(1024)    
SYSTEM_PRIVILEGE                     VARCHAR2(40)      
AUDIT_OPTION                         VARCHAR2(40)      
OBJECT_PRIVILEGES                    VARCHAR2(37)      
ROLE                                 VARCHAR2(128)     
TARGET_USER                          VARCHAR2(128)     
EXCLUDED_USER                        VARCHAR2(128)     
EXCLUDED_SCHEMA                      VARCHAR2(128)     
EXCLUDED_OBJECT                      VARCHAR2(128)     
CURRENT_USER                         VARCHAR2(128)     
ADDITIONAL_INFO                      VARCHAR2(4000)    
UNIFIED_AUDIT_POLICIES               VARCHAR2(4000)    
FGA_POLICY_NAME                      VARCHAR2(128)     
XS_INACTIVITY_TIMEOUT                NUMBER            
XS_ENTITY_TYPE                       VARCHAR2(32)      
XS_TARGET_PRINCIPAL_NAME             VARCHAR2(128)     
XS_PROXY_USER_NAME                   VARCHAR2(128)     
XS_DATASEC_POLICY_NAME               VARCHAR2(128)     
XS_SCHEMA_NAME                       VARCHAR2(128)     
XS_CALLBACK_EVENT_TYPE               VARCHAR2(32)      
XS_PACKAGE_NAME                      VARCHAR2(128)     
XS_PROCEDURE_NAME                    VARCHAR2(128)     
XS_ENABLED_ROLE                      VARCHAR2(128)     
XS_COOKIE                            VARCHAR2(1024)    
XS_NS_NAME                           VARCHAR2(128)     
XS_NS_ATTRIBUTE                      VARCHAR2(4000)    
XS_NS_ATTRIBUTE_OLD_VAL              VARCHAR2(4000)    
XS_NS_ATTRIBUTE_NEW_VAL              VARCHAR2(4000)    
DV_ACTION_CODE                       NUMBER            
DV_ACTION_NAME                       VARCHAR2(128)     
DV_EXTENDED_ACTION_CODE              NUMBER            
DV_GRANTEE                           VARCHAR2(128)     
DV_RETURN_CODE                       NUMBER            
DV_ACTION_OBJECT_NAME                VARCHAR2(128)     
DV_RULE_SET_NAME                     VARCHAR2(128)     
DV_COMMENT                           VARCHAR2(4000)    
DV_FACTOR_CONTEXT                    VARCHAR2(4000)    
DV_OBJECT_STATUS                     VARCHAR2(1)       
OLS_POLICY_NAME                      VARCHAR2(128)     
OLS_GRANTEE                          VARCHAR2(1024)    
OLS_MAX_READ_LABEL                   VARCHAR2(4000)    
OLS_MAX_WRITE_LABEL                  VARCHAR2(4000)    
OLS_MIN_WRITE_LABEL                  VARCHAR2(4000)    
OLS_PRIVILEGES_GRANTED               VARCHAR2(128)     
OLS_PROGRAM_UNIT_NAME                VARCHAR2(128)     
OLS_PRIVILEGES_USED                  VARCHAR2(128)     
OLS_STRING_LABEL                     VARCHAR2(4000)    
OLS_LABEL_COMPONENT_TYPE             VARCHAR2(12)      
OLS_LABEL_COMPONENT_NAME             VARCHAR2(30)      
OLS_PARENT_GROUP_NAME                VARCHAR2(30)      
OLS_OLD_VALUE                        VARCHAR2(4000)    
OLS_NEW_VALUE                        VARCHAR2(4000)    
RMAN_SESSION_RECID                   NUMBER            
RMAN_SESSION_STAMP                   NUMBER            
RMAN_OPERATION                       VARCHAR2(20)      
RMAN_OBJECT_TYPE                     VARCHAR2(20)      
RMAN_DEVICE_TYPE                     VARCHAR2(5)       
DP_TEXT_PARAMETERS1                        VARCHAR2(512)     
DP_BOOLEAN_PARAMETERS1                     VARCHAR2(512)     
DP_WARNINGS1                               VARCHAR2(512)     
DIRECT_PATH_NUM_COLUMNS_LOADED             NUMBER            
RLS_INFO                                   CLOB              
KSACL_USER_NAME                            VARCHAR2(128)     
KSACL_SERVICE_NAME                         VARCHAR2(512)     
KSACL_SOURCE_LOCATION                      VARCHAR2(48)      
PROTOCOL_SESSION_ID                        NUMBER            
PROTOCOL_RETURN_CODE                       NUMBER            
PROTOCOL_ACTION_NAME                       VARCHAR2(32)      
PROTOCOL_USERHOST                          VARCHAR2(128)     
PROTOCOL_MESSAGE                           VARCHAR2(4000)    
DB_UNIQUE_NAME                             VARCHAR2(257)     
OBJECT_TYPE                                VARCHAR2(23)      
FW_ACTION_NAME                             VARCHAR2(30)      
FW_RETURN_CODE                             NUMBER            
SOURCE                                     VARCHAR2(8)       
SCHEMA                                     VARCHAR2(4000)    
DP_CLOB_PARAMETERS1                        CLOB 


describe dba_hist_sqlstat;
  
Name                           Null?    Type           
------------------------------ -------- -------------- 
SNAP_ID                        NOT NULL NUMBER         
DBID                           NOT NULL NUMBER         
INSTANCE_NUMBER                NOT NULL NUMBER         
SQL_ID                         NOT NULL VARCHAR2(13)   
PLAN_HASH_VALUE                NOT NULL NUMBER         
OPTIMIZER_COST                          NUMBER         
OPTIMIZER_MODE                          VARCHAR2(10)   
OPTIMIZER_ENV_HASH_VALUE                NUMBER         
SHARABLE_MEM                            NUMBER         
LOADED_VERSIONS                         NUMBER         
VERSION_COUNT                           NUMBER         
MODULE                                  VARCHAR2(64)   
ACTION                                  VARCHAR2(64)   
SQL_PROFILE                             VARCHAR2(64)   
FORCE_MATCHING_SIGNATURE                NUMBER         
PARSING_SCHEMA_ID                       NUMBER         
PARSING_SCHEMA_NAME                     VARCHAR2(128)  
PARSING_USER_ID                         NUMBER         
FETCHES_TOTAL                           NUMBER         
FETCHES_DELTA                           NUMBER         
END_OF_FETCH_COUNT_TOTAL                NUMBER         
END_OF_FETCH_COUNT_DELTA                NUMBER         
SORTS_TOTAL                             NUMBER         
SORTS_DELTA                             NUMBER         
EXECUTIONS_TOTAL                        NUMBER         
EXECUTIONS_DELTA                        NUMBER         
PX_SERVERS_EXECS_TOTAL                  NUMBER         
PX_SERVERS_EXECS_DELTA                  NUMBER         
LOADS_TOTAL                             NUMBER         
LOADS_DELTA                             NUMBER         
INVALIDATIONS_TOTAL                     NUMBER         
INVALIDATIONS_DELTA                     NUMBER         
PARSE_CALLS_TOTAL                       NUMBER         
PARSE_CALLS_DELTA                       NUMBER         
DISK_READS_TOTAL                        NUMBER         
DISK_READS_DELTA                        NUMBER         
BUFFER_GETS_TOTAL                       NUMBER         
BUFFER_GETS_DELTA                       NUMBER         
ROWS_PROCESSED_TOTAL                    NUMBER         
ROWS_PROCESSED_DELTA                    NUMBER         
CPU_TIME_TOTAL                          NUMBER         
CPU_TIME_DELTA                          NUMBER         
ELAPSED_TIME_TOTAL                      NUMBER         
ELAPSED_TIME_DELTA                      NUMBER         
IOWAIT_TOTAL                            NUMBER         
IOWAIT_DELTA                            NUMBER         
CLWAIT_TOTAL                            NUMBER         
CLWAIT_DELTA                            NUMBER         
APWAIT_TOTAL                            NUMBER         
APWAIT_DELTA                            NUMBER         
CCWAIT_TOTAL                            NUMBER         
CCWAIT_DELTA                            NUMBER         
DIRECT_WRITES_TOTAL                     NUMBER         
DIRECT_WRITES_DELTA                     NUMBER         
PLSEXEC_TIME_TOTAL                      NUMBER         
PLSEXEC_TIME_DELTA                      NUMBER         
JAVEXEC_TIME_TOTAL                      NUMBER         
JAVEXEC_TIME_DELTA                      NUMBER         
IO_OFFLOAD_ELIG_BYTES_TOTAL             NUMBER         
IO_OFFLOAD_ELIG_BYTES_DELTA             NUMBER         
IO_INTERCONNECT_BYTES_TOTAL             NUMBER         
IO_INTERCONNECT_BYTES_DELTA             NUMBER         
PHYSICAL_READ_REQUESTS_TOTAL            NUMBER         
PHYSICAL_READ_REQUESTS_DELTA            NUMBER         
PHYSICAL_READ_BYTES_TOTAL               NUMBER         
PHYSICAL_READ_BYTES_DELTA               NUMBER         
PHYSICAL_WRITE_REQUESTS_TOTAL           NUMBER         
PHYSICAL_WRITE_REQUESTS_DELTA           NUMBER         
PHYSICAL_WRITE_BYTES_TOTAL              NUMBER         
PHYSICAL_WRITE_BYTES_DELTA              NUMBER         
OPTIMIZED_PHYSICAL_READS_TOTAL          NUMBER         
OPTIMIZED_PHYSICAL_READS_DELTA          NUMBER         
CELL_UNCOMPRESSED_BYTES_TOTAL           NUMBER         
CELL_UNCOMPRESSED_BYTES_DELTA           NUMBER         
IO_OFFLOAD_RETURN_BYTES_TOTAL           NUMBER         
IO_OFFLOAD_RETURN_BYTES_DELTA           NUMBER         
BIND_DATA                               RAW(2000 BYTE) 
FLAG                                    NUMBER         
OBSOLETE_COUNT                          NUMBER         
CON_DBID                                NUMBER         
CON_ID                                  NUMBER     