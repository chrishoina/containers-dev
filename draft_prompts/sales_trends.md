## Sales Trending

1. Please familiarize yourself with, and referer to this resource as needed to accomplish the following tasks: https://docs.oracle.com/en/database/oracle/oracle-database/19/dwhsg/sql-modeling-data-warehouses.html#GUID-195E4085-EE47-4122-AED6-F358C0C2F716

2. You will need to project sales for the next 12 months. Each Channel type should have its own sales projection.

3. You can accomplish this task by following the regression example as shown here: https://docs.oracle.com/en/database/oracle/oracle-database/19/dwhsg/sql-modeling-data-warehouses.html#GUID-DF19701F-FB63-4AA0-A285-F337DC9D6203. You may require a view to do this. You can review the sales_view2 in the following example as a point of reference: https://docs.oracle.com/en/database/oracle/oracle-database/19/dwhsg/sql-modeling-data-warehouses.html#GUID-195E4085-EE47-4122-AED6-F358C0C2F716

4. You will perform this as the SQL_FREESQL_01 user, and you will use the tables located in the SH schema.

4. Once you have accomplished this, create an html file with a table of the projections, along with a line chart. The html file should include:
    - Sales projections for each individual channel type
    - Sales projections table for each individual channel type 

5. Provide a summary of the methods used to perform the sales projections.

To accomplish the task of connecting as SQL_FREESQL_01 user and displaying the channel descriptions' monthly sales figures over the last 12 months, I need to follow these steps:

1. Connect to the Oracle database as SQL_FREESQL_01 user using the SQLcl MCP server.
2. Identify the relevant tables that contain the channel descriptions and sales data.
3. Write an SQL query to retrieve the channel descriptions and their monthly sales figures for the last 12 months.
4. Execute the SQL query and retrieve the results.


What trends are present in the channel description summary you provided?

present these finds to me in an executive summary


which promotions were occuring when the highest and lowest sales data were recorded for the channels (Direct Sales, Internet, Partners)?

To show the 10 least purchased items by customer country, I need to modify the previous SQL query to focus on the least purchased products for each country.

Show me the 5 least most purchased products by the 5 highest grossing countries.