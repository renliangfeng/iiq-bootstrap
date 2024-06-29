#!/bin/sh
echo "Start creating IIQ Database (MSSQL). It will take a while to complete. Please do not interupt."
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $1 -d master -i /tmp/create_identityiq_tables.sqlserver
echo "IIQ Database (MSSQL) was created."