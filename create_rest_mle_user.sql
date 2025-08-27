-- =====================================================
-- Script: create_user_schema.sql
-- Purpose: Create and configure a new user/schema. It checks for the user's existence to avoid errors,
--          then grants essential roles and privileges. This includes standard object creation permissions,
--          the DB_DEVELOPER_ROLE for Machine Learning for Oracle (MLE), and an ORDS.ENABLE_SCHEMA
--          call to make the schema's objects accessible via a RESTful API.
--
-- Usage in SQLcl:
--   SQL> @create_user_schema.sql
-- =====================================================

-- The following commands explicitly prompt the user for input.
-- The 'prompt' command displays the message, and the 'define' command
-- stores the user's input into the specified variables.

INPUT
PROMPT Choose a new database username:
ACCEPT target_user CHAR PROMPT 'Enter new user name hurrr:'
PROMPT Choose a temporary password for &&target_user: 
ACCEPT target_password CHAR PROMPT 'Make it super secret:'

Set Verify Off

whenever sqlerror exit sql.sqlcode

-- This PL/SQL block checks if the user exists and creates them if they don't.
DECLARE
  v_user_exists INTEGER;
BEGIN
-- We're checking the 'dba_users' view, which contains a list of all database users.
  SELECT COUNT(*)
  INTO v_user_exists
  FROM dba_users
  WHERE username = UPPER('&&target_user');

-- This is a conditional statement. If the user count is 0...
  IF v_user_exists = 0 THEN
-- A message is printed to the console to let the user know what's happening.
    DBMS_OUTPUT.PUT_LINE('Creating user ' || UPPER('&&target_user') || '...');
-- The user is created using the variables defined at the top of the script.
    EXECUTE IMMEDIATE 'create user &&target_user identified by "&&target_password"';
    DBMS_OUTPUT.PUT_LINE('User created.');
  ELSE
-- If the user exists, a different message is displayed, and the creation step is skipped.
    DBMS_OUTPUT.PUT_LINE('User ' || UPPER('&&target_user') || ' already exists. Skipping creation.');
  END IF;
END;
/

-- The following lines grant the necessary permissions to the user.
-- This section will run regardless of whether the user was just created or already existed.

-- A message is printed to the console before the grants begin.
-- DBMS_OUTPUT.PUT_LINE('Granting privileges to ' || UPPER('&&target_user') || '...');

-- Grants the user unlimited storage space in any tablespace.
grant unlimited tablespace to &&target_user;

-- 'connect' allows the user to log in. 'resource' gives them basic object creation privileges.
grant connect, resource to &&target_user;

-- These grants provide the ability to create common database objects within their schema.
-- This is a very common set of privileges for a new application user.
grant create materialized view,
      create procedure,
      create sequence,
      create session,
      create synonym,
      create table,
      create trigger,
      create type,
      create view
to &&target_user;

-- Grants the user the 'db_developer_role' which is required for using MLE (Machine Learning for Oracle).
grant db_developer_role to &&target_user;

-- A final message confirms that the grants have been applied.
-- DBMS_OUTPUT.PUT_LINE('Privileges granted.');

-- This command changes the current SQL*Plus or SQLcl session to the newly created user.
connect &target_user/"&&target_password"

-- This PL/SQL block enables the ORDS (Oracle REST Data Services) schema for the user.
-- This makes the schema's objects accessible via a RESTful API.
BEGIN
  ords.enable_schema(
    p_enabled => TRUE, -- Sets ORDS as enabled for this schema.
    p_schema => UPPER('&&target_user'), -- Specifies the target schema.
    p_url_mapping_type => 'BASE_PATH', -- Sets the URL mapping type.
    p_url_mapping_pattern => LOWER('&&target_user'), -- Defines the URL path (e.g., /myuser/...).
    p_auto_rest_auth => TRUE -- Enables automatic REST authentication for security.
  );
END;
/
