--------------------------------------------------------------------------------
-- 1. Test the Standard View: v_emp_dept_summary
--------------------------------------------------------------------------------

-- View the joined employee and department information
SELECT * FROM v_emp_dept_summary;
-- Look for columns: emp_id, emp_name, dept_code, established, details, comments

--------------------------------------------------------------------------------
-- 2. Test the JSON Relational Duality View: dept_projects_dv
--------------------------------------------------------------------------------

-- Query all departments as JSON, with nested projects array
SELECT JSON_SERIALIZE(VALUE(dat) PRETTY)
FROM dept_projects_dv dat;

-- Insert a new department (id 999) with one project (id 888) using JSON input
INSERT INTO dept_projects_dv VALUES (
  JSON_OBJECT(
    '_id'         VALUE 999,
    'dept_code'   VALUE 'ZZ999',
    'established' VALUE '2024-06-13',
    'details'     VALUE JSON_OBJECT('location' VALUE 'Bldg X', 'members' VALUE 1),
    'projects'    VALUE JSON_ARRAY(
      JSON_OBJECT('proj_id' VALUE 888, 'proj_name' VALUE 'TestProj', 'is_active' VALUE TRUE)
    )
  )
);

-- Verify the department and project were inserted (view as JSON)
SELECT JSON_SERIALIZE(VALUE(dat) PRETTY)
FROM dept_projects_dv dat
WHERE JSON_VALUE(VALUE(dat), '$._id') = 999;

-- Update the project name inside the JSON structure
UPDATE dept_projects_dv
SET VALUE = JSON_TRANSFORM(
    VALUE(dat),
    REPLACE '$.projects[0].proj_name' = 'TestProjRenamed'
)
WHERE JSON_VALUE(VALUE(dat), '$._id') = 999;

-- Verify the change by querying the base table directly
SELECT * FROM project WHERE proj_id = 888;

--------------------------------------------------------------------------------
-- 3. Test the Complex SQL Query
--------------------------------------------------------------------------------

-- Show departments with counts of employees, projects, and active projects.
-- Filter for department(s) with the maximum number of active projects.
SELECT
  d.dept_id,
  d.dept_code,
  COUNT(DISTINCT e.emp_id) AS emp_count,
  COUNT(DISTINCT p.proj_id) AS project_count,
  SUM(CASE WHEN p.is_active = TRUE THEN 1 ELSE 0 END) AS active_proj_count
FROM
  department d
  LEFT JOIN project p ON d.dept_id = p.dept_id
  LEFT JOIN employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_code
HAVING SUM(CASE WHEN p.is_active = TRUE THEN 1 ELSE 0 END) = (
    SELECT MAX(cnt) FROM (
      SELECT COUNT(*) AS cnt FROM project WHERE is_active = TRUE GROUP BY dept_id
    )
  )
ORDER BY emp_count DESC;

--------------------------------------------------------------------------------
-- 4. Test the PL/SQL Procedure: pr_add_and_assign_employee
--------------------------------------------------------------------------------

-- Add a new employee 'Kim' and assign to department with code 'HR001'
BEGIN
  pr_add_and_assign_employee('Kim', 'HR001', 'New HR assistant.');
END;
/

-- Verify insertion of the new employee
SELECT * FROM employee WHERE emp_name = 'Kim';

--------------------------------------------------------------------------------
-- 5. Test the PL/SQL Function: fn_longest_tenured_employee
--------------------------------------------------------------------------------

-- Get the name of the employee with the longest comment
SELECT fn_longest_tenured_employee FROM dual;

--------------------------------------------------------------------------------
-- End of manual SQL test file
--------------------------------------------------------------------------------