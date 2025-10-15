#!/bin/sh
echo "Start creating IIQ Database (PostgreSQL). It will take a while to complete. Please do not interupt."
psql postgresql://postgres:$1@localhost:5432/iiqdb -f /tmp/create_identityiq_tables.postgresql
echo "IIQ Database (PostgreSQL) was created."