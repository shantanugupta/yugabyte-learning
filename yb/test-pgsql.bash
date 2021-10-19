ysqlsh -h 10.0.1.155

CREATE DATABASE northwind;
\l -- list all databases
\c northwid -- switch to default db as northwind
\i ~/yb/northwind_ddl.sql
\d -- verify all tables
\i ~/yb/northwind_data.sql
SELECT * FROM customers LIMIT 2;
\q -- quit