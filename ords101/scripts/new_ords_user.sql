-- =====================================================
-- Script: create_user_schema.sql
-- Purpose: Create and configure a new user/schema in Oracle DB.
-- Usage: Edit the variables below before running.
-- =====================================================

-- ======== CONFIGURATION SECTION ========
-- Edit these two lines before running!
-- =======================================
DEFINE target_user = '[Username]'
DEFINE target_password = '[Password]'

-- =======================================
-- SQL Developer Web/VS Code: SETUP
-- No interactive prompt, so just SET your values.
-- =======================================
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- ======== USER CREATION (Check existence) ========
DECLARE
  v_user_exists INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_user_exists FROM dba_users WHERE username = UPPER('&target_user.');

  IF v_user_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Creating user ' || UPPER('&target_user.') || '...');
    EXECUTE IMMEDIATE 'CREATE USER ' || UPPER('&target_user.') || ' IDENTIFIED BY "' || '&target_password.' || '"';
    DBMS_OUTPUT.PUT_LINE('User created.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User ' || UPPER('&target_user.') || ' already exists. Skipping creation.');
  END IF;
END;
/

-- ======== GRANT ROLES & PRIVILEGES ========
BEGIN
  EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO ' || UPPER('&target_user.');
  EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE TO ' || UPPER('&target_user.');
  EXECUTE IMMEDIATE 'GRANT CREATE MATERIALIZED VIEW, CREATE PROCEDURE, CREATE SEQUENCE, CREATE SESSION, CREATE SYNONYM, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, CREATE VIEW TO ' || UPPER('&target_user.');
  EXECUTE IMMEDIATE 'GRANT DB_DEVELOPER_ROLE TO ' || UPPER('&target_user.');
  DBMS_OUTPUT.PUT_LINE('Privileges granted for ' || UPPER('&target_user.') || '.');
END;
/

-- ======== ORDS Enablement for REST Access ========
BEGIN
  ords_admin.enable_schema(
    p_enabled            => TRUE,
    p_schema             => UPPER('&target_user.'),
    p_url_mapping_type   => 'BASE_PATH',
    p_url_mapping_pattern=> LOWER('&target_user.'),
    p_auto_rest_auth     => TRUE
  );
  DBMS_OUTPUT.PUT_LINE('ORDS enabled for schema ' || UPPER('&target_user.') || '.');
EXCEPTION
  WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- NOTE: You cannot change sessions with 'CONNECT' within SQL Developer Web scripts.
-- Connect as the new user manually if needed for subsequent commands.