#!/bin/sh
echo "Start creating IIQ Database (Oracle). It will take a while to complete. Please do not interupt."
sqlplus sys/$1@FREEPDB1 as sysdba<< EOF
@/tmp/create_identityiq_users.oracle
@/tmp/create_identityiq_tables.oracle
exit
EOF

echo "IIQ Database (Oracle) was created."