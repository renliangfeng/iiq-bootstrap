#!/bin/sh
cd /usr/local/tomcat/webapps/identityiq/WEB-INF/bin

echo "Start to import init.xml"
echo "import init.xml" >> import.txt
./iiq console < import.txt
rm import.txt
echo "Complete import init.xml"

if [ -e ../config/init-lcm.xml ]
then
	echo "Start to import init-lcm.xml"
	echo "import init-lcm.xml" >> import-lcm.txt
	./iiq console < import-lcm.txt
	rm import-lcm.txt
	echo "Complete import init-lcm.xml"
fi

if [ -e ../config/rapidsetup.xml ]
then
    echo "Start to import rapidsetup.xml"
	echo "import rapidsetup.xml" >> import-rapidsetup.txt
	./iiq console < import-rapidsetup.txt
	rm import-rapidsetup.txt
	echo "Complete import rapidsetup.xml"
fi
