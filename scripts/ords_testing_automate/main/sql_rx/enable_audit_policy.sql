SET SERVEROUTPUT ON
SET FEEDBACK OFF

PROMPT ----- Checking if Unified Auditing is enabled -----

DECLARE
  unified_enabled VARCHAR2(10);
  policy_count    NUMBER;
BEGIN
  -- 1. Check if Unified Auditing is actually ON
  SELECT VALUE INTO unified_enabled
    FROM V$OPTION
   WHERE PARAMETER = 'Unified Auditing';

  IF unified_enabled = 'TRUE' THEN
    DBMS_OUTPUT.PUT_LINE('Unified Auditing is ENABLED. Continuing...');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Unified Auditing is NOT ENABLED. Please request DBA to enable it.');
    RETURN;
  END IF;

  -- 2. See if the policy already exists
  SELECT COUNT(*) INTO policy_count
    FROM AUDIT_UNIFIED_POLICIES
   WHERE POLICY_NAME = 'ORDSTEST_AUDIT';

  IF policy_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE AUDIT POLICY ordstest_audit ACTIONS ALL';
    DBMS_OUTPUT.PUT_LINE('Created audit policy ordstest_audit');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Audit policy ordstest_audit already exists.');
  END IF;
END;
/

PROMPT ----- Enabling Audit Policy: ordstest_audit -----
-- This is a standalone SQL command, keep it outside the block
AUDIT POLICY ordstest_audit;

PROMPT ----- Audit Policy ordstest_audit process complete -----
EXIT