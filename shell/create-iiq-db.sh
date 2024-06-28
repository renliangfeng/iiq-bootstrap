#!/bin/sh
echo "Start creating IIQ Database. It will take a while to complete. Please do not interupt."
mysql --user=root --password=$1  < /tmp/create_identityiq_tables.mysql
echo "IIQ Database was created."