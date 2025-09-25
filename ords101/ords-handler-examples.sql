-- =============================================
-- SECTION 1: VIEW QUERIES
-- =============================================

-- 1.1 View: v_emp_dept_proj

-- Uses optional route patterns

-- Not working, needs work:

-- BEGIN
--   ORDS.DEFINE_HANDLER(
--     p_module_name    => 'my.views',
--     p_pattern        => 'v_emp_dept_proj/:emp_name,dept_code',
--     p_method         => 'GET',
--     p_source_type    => ORDS.source_type_query,
--     p_source         => q'[
--         SELECT emp_name, dept_code, details, comments
--         FROM v_emp_dept_proj
--         WHERE (:emp_name IS NULL OR emp_name = :emp_name)
--           AND (:dept_code IS NULL OR dept_code = :dept_code)
--     ]',
--     p_items_per_page => 25
--   );
-- END;
-- /

-- 1.2 View: v_proj_emp_count; using the REST-Enabled SQL Service

-- SQL in the payload body

curl -i -X POST --user username:<password> \
  --data-binary "SELECT proj_name, dept_code, employee_count FROM v_proj_emp_count" \
  -H "Content-Type: application/sql" \
  https://<your-server>/ords/[your schema]/_/sql

-- JSON in the payload body

curl -i -X POST --user username:<password> \
  -H "Content-Type: application/json" \
  -d '{"statementText":"SELECT proj_name, dept_code, employee_count FROM v_proj_emp_count"}' \
  https://<your-server>/ords/[your schema]/_/sql

curl -i -X POST --user ords101:Password12345 \ 
-d '{"statementText":"SELECT proj_name, dept_code, employee_count FROM v_proj_emp_count"}' \
-H "Content-Type: application/json" http://localhost:8080/ords/ords101/_/sql 

-- 1.3 View: v_dept_budget_summary

-- download the results as a csv file.

BEGIN
  ORDS.DEFINE_HANDLER(
    p_module_name    => 'ords101',
    p_pattern        => 'v_dept_budget_summary/',
    p_method         => 'GET',
    p_source_type    => ORDS.source_type_query,
    p_source         => q'[
      SELECT dept_code, active_project_count
      FROM v_dept_budget_summary
    ]',
    p_items_per_page => 100,
    p_mimes_allowed  => 'application/json,text/csv'
  );
END;
/

-- Example curl command:
curl -X GET "https://<your-server>/ords/hr/v_dept_budget_summary/" -H "Accept: text/csv" -o summary.csv
 

-- 1.4: JSON Relational Duality View:

CREATE JSON RELATIONAL DUALITY VIEW department_with_projects_dv AS 
  SELECT JSON {
    '_id'        : d.dept_id,        -- <<<< Required unique identifier
    'dept_code'   : d.dept_code,
    'established' : d.established,
    'details'     : d.details,
    'projects'    : [
      SELECT JSON {
        'proj_id'   : p.proj_id,
        'proj_name' : p.proj_name,
        'is_active' : p.is_active
      }
      FROM project p 
      WHERE p.dept_id = d.dept_id
    ]
  }
  FROM department d;
/

-- Testing with an auto-REST Endpoint:

curl -X POST \
  https://your-ords-server/ords/hr/department_with_projects_dv/ \
  -H "Content-Type: application/json" \
  -d '{
        "dept_code":"NEW42",
        "established":"2024-05-01",
        "details":{"location":"Remote","members":7},
        "projects":[{"proj_name":"WebRevamp","is_active":true}]
      }'

-- =============================================
-- SECTION 2: PROCEDURE TESTS (Dynamic Output)
-- =============================================

-- 2.1: Returning a success/fail status code/message; uses bind parameters

BEGIN
  DECLARE
    l_emp_name  VARCHAR2(100) := :emp_name;
    l_dept_id   NUMBER        := :dept_id;
    l_comments  CLOB          := :comments;
  BEGIN
    add_employee(
      p_emp_name => l_emp_name,
      p_dept_id  => l_dept_id,
      p_comments => l_comments
    );
    :response := '{"status":"success","message":"Employee added."}';
  EXCEPTION
    WHEN OTHERS THEN
      :response := '{"status":"error","message":"'
        || REPLACE(SQLERRM, '"', '\"') || '"}';
  END;
END;

-- 2.2: Including a Forward Location in the results

-- NOTE: Requires a corresponding endpoint, with the /:id modifier.

BEGIN
  DECLARE
    l_emp_id   NUMBER := :emp_id;
    l_dept_id  NUMBER := :dept_id;
  BEGIN
    assign_employee_to_department(
      p_emp_id  => l_emp_id,
      p_dept_id => l_dept_id
    );
    -- Forward to the GET handler representing the employee resource
    :forward_location := '/employee/' || l_emp_id;
    :status_code := 201;
    -- No need to set :response (it will be overridden by the GET handler's response)
  EXCEPTION
    WHEN OTHERS THEN
      -- On error, still return a JSON error message
      :status_code := 400;
      :response := '{"status":"error","message":"'
                   || REPLACE(SQLERRM, '"', '\"') || '"}';
  END;
END;

-- 2.3 Test: update_project_status
-- Updates a project's is_active status, confirms new state. Accepts many inputs

BEGIN
  DECLARE
    l_proj_id   NUMBER := :proj_id;
    l_input     VARCHAR2(50) := TRIM(UPPER(NVL(:is_active, '')));
    l_is_active BOOLEAN;

    -- Synonyms for TRUE and FALSE, now including html entity codes and rendered characters
  BEGIN
    IF l_input IN (
      'TRUE', 'YES', 'Y', '1',                         -- English
      'VERDADERO', 'SI', 'SÍ', 'CIERTO', 'CLARO',      -- Spanish
      'VERO', 'CERTO', 'CHIARO', 'SI',                 -- Italian
      -- HTML entity names or common encodings (accept both raw and character)
      '&AMP;#X2714;','&#X2714;','&AMP;#9989;','&#9989;','&AMP;PLUS;','&PLUS;','&#43;'
    ) THEN
      l_is_active := TRUE;

    ELSIF l_input IN (
      'FALSE', 'NO', 'N', '0',                         -- English
      'FALSO', 'INCORRECTO',                           -- Spanish
      'FALSO', 'SBAGLIATO', 'ERRATO',                  -- Italian
      -- HTML entity names or common encodings (accept both raw and character)
      '&AMP;#X2716;','&#X2716;','&AMP;#10060;','&#10060;','&AMP;MINUS;','&MINUS;','&#45;'
    ) THEN
      l_is_active := FALSE;

    ELSE
      :status_code := 400;
      :response := '{"status":"error","message":"Invalid value for is_active."}';
      RETURN;
    END IF;

    update_project_status(
      p_proj_id   => l_proj_id,
      p_is_active => l_is_active
    );

    :status_code := 200;
    :response := '{"status":"success","message":"Project ID '
                 || l_proj_id || ' set to is_active='
                 || CASE WHEN l_is_active THEN 'TRUE' ELSE 'FALSE' END || '"}';

  EXCEPTION
    WHEN OTHERS THEN
      :status_code := 500;
      :response := '{"status":"error","message":"'
        || REPLACE(SQLERRM, '"', '\"') || '"}';
  END;
END;

-- =============================================
-- SECTION 3: FUNCTION TESTS (with Output)
-- =============================================

-- 3.1 get_employee_count: Number of employees in department; with additional functions.
-- Building atop existing functions

BEGIN
  DECLARE
    l_dept_id    NUMBER := :dept_id;
    l_count      NUMBER;
    l_percentile NUMBER;
  BEGIN
    l_count := get_employee_count(l_dept_id);

    SELECT percentile
      INTO l_percentile
      FROM (
        SELECT dept_id,
               PERCENT_RANK() OVER (ORDER BY get_employee_count(dept_id)) AS percentile
          FROM departments
      )
     WHERE dept_id = l_dept_id;

    :response := '{"status":"success","department":' || l_dept_id ||
                 ',"employee_count":' || NVL(l_count,0) ||
                 ',"percentile_rank":' || TO_CHAR(l_percentile * 100, 'FM990.00') || '}';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      :response := '{"status":"error","message":"Department not found."}';
  END;
END;

-- 3.2 get_active_project_count: Number of active projects by dept_id

BEGIN
  DECLARE
    n NUMBER;
    l_dept_id NUMBER := :dept_id;
  BEGIN
    n := get_active_project_count(l_dept_id);
    :response := '{"status":"success","message":"Number of active projects in department ' 
                 || l_dept_id || ': ' || NVL(n,0) || '"}';
  EXCEPTION
    WHEN OTHERS THEN
      :response := '{"status":"error","message":"'
        || REPLACE(SQLERRM, '"', '\"') || '"}';
  END;
END;

-- 3.3 get_employee_comments: Retrieve comments for employee using automatic binding

BEGIN
  DECLARE
    c CLOB;
    l_emp_id NUMBER := :emp_id;
  BEGIN
    c := get_employee_comments(l_emp_id);
    IF c IS NOT NULL THEN
      :response := '{"status":"success","comments":"' 
                   || REPLACE(DBMS_LOB.SUBSTR(c, 4000, 1), '"', '\"') || '"}';
    ELSE
      :response := '{"status":"success","comments":"No comments found for employee id ' || l_emp_id || '"}';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      :response := '{"status":"error","message":"'
        || REPLACE(SQLERRM, '"', '\"') || '"}';
  END;
END;

-- Can use one of:

-- GET /ords/hr/your_handler?emp_id=7

-- POST /ords/hr/your_handler
-- Content-Type: application/x-www-form-urlencoded

-- emp_id=7

-- POST /ords/hr/your_handler
-- Content-Type: application/json

-- {
--   "emp_id": 7
-- }