-- ======================================================
-- Script: drop_user_schema.sql
-- Purpose: Remove an Oracle user/schema and clean up related settings.
-- Usage: Set the target_user variable and execute as a user with DBA privileges.
-- ======================================================

-- ======== CONFIGURATION SECTION ========
-- Edit the username you wish to drop:
DEFINE target_user = '[Username]'

SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- ======== ORDS Disablement (if schema is enabled) ========
BEGIN
  -- Try to disable schema from ORDS. Ignore errors if already disabled/not present.
  ords_admin.enable_schema(
    p_schema => UPPER('&target_user.'),
    p_enabled => FALSE
  );
  DBMS_OUTPUT.PUT_LINE('ORDS schema disabled for ' || UPPER('&target_user.'));
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ORDS disable_schema error (ignored): ' || SQLERRM);
END;
/

-- ======== REVOKE ALL RELEVANT ROLES & PRIVILEGES ========
BEGIN
  -- ROLES
  BEGIN EXECUTE IMMEDIATE 'REVOKE CONNECT FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE RESOURCE FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE DB_DEVELOPER_ROLE FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  -- UNLIMITED TABLESPACE
  BEGIN EXECUTE IMMEDIATE 'REVOKE UNLIMITED TABLESPACE FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  -- SYSTEM PRIVILEGES
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE MATERIALIZED VIEW FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE PROCEDURE FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE SEQUENCE FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE SESSION FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE SYNONYM FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE TABLE FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE TRIGGER FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE TYPE FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'REVOKE CREATE VIEW FROM ' || UPPER('&target_user.'); EXCEPTION WHEN OTHERS THEN NULL; END;
  DBMS_OUTPUT.PUT_LINE('Roles and privileges revoked for ' || UPPER('&target_user.') || '.');
END;
/

-- ======== DROP THE USER (CASCADE removes all schema objects) ========
BEGIN
  EXECUTE IMMEDIATE 'DROP USER ' || UPPER('&target_user.') || ' CASCADE';
  DBMS_OUTPUT.PUT_LINE('User ' || UPPER('&target_user.') || ' and all schema objects dropped.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('User drop error: ' || SQLERRM);
END;
/