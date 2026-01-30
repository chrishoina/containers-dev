SET SERVEROUTPUT ON
SET FEEDBACK ON

PROMPT
PROMPT ================================================================
PROMPT REVERTING AUDIT SETTINGS: ordstest_audit
PROMPT ================================================================

PROMPT [1/1] Disabling audit policy records...
NOAUDIT POLICY ordstest_audit;
PROMPT   --> [OK] Audit policy "ordstest_audit" disabled.

PROMPT
PROMPT [FINISHED] The environment has been cleaned up (policy definition remains in database).
PROMPT ================================================================
PROMPT
EXIT