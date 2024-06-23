Covid.sql file: scripts about data preprocessing, get data going to be used in later Tableau (Views,CTE, Temp table)

Data import is very time consuming, may face a lot problemss due to system error, format error

Tips for that: Pgadmin(mac)-postgre_sql
    1. Create database and table first, then add columns and datatype
    2. Make sure you add exact right number of columns and number of columns in your csv file
    3. Change data type accordingly when see import data error message (e.g. float data can not be imported by using interger numer setting)
    4. Select delimiter, typically comma ',' for csv file
    5. After importing successfully, adjust columns properly ( we move to data cleaning /preprocessing step, some data are recorded randomly)
     
