#!/bin/sh
cd /usr/local/tomcat/webapps/identityiq/WEB-INF/bin

echo "import init.xml" >> import.txt

./iiq console < import.txt

rm import.txt