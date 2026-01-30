-- Create a unified audit policy to capture activity only for specific session modules.
-- This policy can be enabled for all users or for a specific user as needed.


CREATE AUDIT POLICY module_activity_audit
  ACTIONS ALL
  WHEN 'SYS_CONTEXT(''USERENV'',''MODULE'') = ''/performance/owa_cgi''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''/performance/sleep''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''/table_a/''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''/table_a/1''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''/table_b/''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''/table_b/2''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''DBMS_SCHEDULER''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''Oracle REST Data Services''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''SQLcl''
    OR SYS_CONTEXT(''USERENV'',''MODULE'') = ''sys$abs_timeout'''
  EVALUATE PER STATEMENT;

-- To enable this policy at the database level:
-- AUDIT POLICY module_activity_audit BY ALL;

-- To enable this policy for a specific user (e.g., podman_sys):
-- AUDIT POLICY module_activity_audit BY podman_sys;

-- To view audit policies:
-- SELECT * FROM AUDIT_UNIFIED_POLICIES;
-- For audit records, query UNIFIED_AUDIT_TRAIL.
