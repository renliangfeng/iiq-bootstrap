#!/bin/sh

echo "Checking current running DB container. "
mysqlContainer="$(docker ps --format '{{ .Names }}' | grep iiq-db)"
mssqlContainer="$(docker ps --format '{{ .Names }}' | grep iiq-mssql-db)"
oracleContainer="$(docker ps --format '{{ .Names }}' | grep iiq-oracle-db)"
if [[ $mysqlContainer = 'iiq-db' ]];then
	echo "Running DB is MySQL. "
	dbType=mysql
elif [[ "$mssqlContainer" == "iiq-mssql-db" ]]; then
	echo "Running DB is SQL Server. "
	dbType=mssql
elif [[ "$oracleContainer" == "iiq-oracle-db" ]]; then
	echo "Running DB is Oracle. "
	dbType=oracle
else
	echo "No Running DB (MySQL or SQL Server). Exit "
	exit
fi


echo "Please specify password of Database Server root user. Leave it empty and press Enter to continue with the default password 'Sailpoint_1234'. "
read rootPassword

# echo "root password: $rootPassword"

if [[ $rootPassword = '' ]];then
	rootPassword=Sailpoint_1234
fi

echo "root password: $rootPassword"

# generate IIQ Database schema from IIQ App container
docker exec --workdir /usr/local/tomcat/webapps/identityiq/WEB-INF/bin iiq-app ./iiq schema

# download IIQ DB Script from IIQ App container
if [[ $dbType = 'mssql' ]];then
	docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/database/create_identityiq_tables.sqlserver .
	sed -i '' "s/WITH PASSWORD='identityiq'/WITH PASSWORD='identityiq',CHECK_POLICY = OFF/g" ./create_identityiq_tables.sqlserver
	sed -i '' "s/WITH PASSWORD='identityiqPlugin'/WITH PASSWORD='identityiqPlugin',CHECK_POLICY = OFF/g" ./create_identityiq_tables.sqlserver
	echo "By default IIQ database name is 'identityiq'. But you can modify ${PWD}/create_identityiq_tables.sqlserver to override values before pressing Enter to continue".
elif [[ $dbType = 'oracle' ]];then
	docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/database/create_identityiq_tables.oracle .
	echo "By default IIQ database name is 'identityiq'. But you can modify ${PWD}/create_identityiq_users.oracle and ${PWD}/create_identityiq_tables.oracle to override values before pressing Enter to continue".
else
	docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/database/create_identityiq_tables.mysql .
	echo "By default IIQ database name is 'identityiq'. But you can modify ${PWD}/create_identityiq_tables.mysql to override values before pressing Enter to continue".
fi

read continue

if [[ $dbType = 'mssql' ]];then
	# upload IIQ DB script to IIQ DB container
	docker cp ./create_identityiq_tables.sqlserver iiq-mssql-db:/tmp/

	# upload shell script to IIQ DB container
	docker cp ./shell/create-iiq-db-mssql.sh iiq-mssql-db:/tmp/
	docker exec -u 0 -it iiq-mssql-db chown root:root /tmp/create-iiq-db-mssql.sh
	docker exec -u 0 -it iiq-mssql-db bash -c "sed -i -e 's/\r$//' /tmp/create-iiq-db-mssql.sh"
	docker exec -u 0 --workdir /tmp iiq-mssql-db chmod 755 create-iiq-db-mssql.sh

	# run shell script in IIQ DB container to create IIQ DB & tables
	docker exec -it iiq-mssql-db sh -c "/tmp/create-iiq-db-mssql.sh $rootPassword"
elif [[ $dbType = 'oracle' ]];then
	# upload IIQ DB script to IIQ DB container
	docker cp ./create_identityiq_users.oracle iiq-oracle-db:/tmp/
	docker cp ./create_identityiq_tables.oracle iiq-oracle-db:/tmp/
	## increase size of some DB table columes to prevent errors
	docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/IS_DURABLE VARCHAR2(1)/IS_DURABLE VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"
	docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/IS_NONCONCURRENT VARCHAR2(1)/IS_NONCONCURRENT VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"
	docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/IS_UPDATE_DATA VARCHAR2(1)/IS_UPDATE_DATA VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"
	docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/REQUESTS_RECOVERY VARCHAR2(1)/REQUESTS_RECOVERY VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"


	# upload shell script to IIQ DB container
	docker cp ./shell/create-iiq-db-oracle.sh iiq-oracle-db:/tmp/
	docker exec -u 0 -it iiq-oracle-db chown root:root /tmp/create-iiq-db-oracle.sh
	docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/\r$//' /tmp/create-iiq-db-oracle.sh"
	docker exec -u 0 --workdir /tmp iiq-oracle-db chmod 755 create-iiq-db-oracle.sh

	# run shell script in IIQ DB container to create IIQ DB & tables
	docker exec -it iiq-oracle-db sh -c "/tmp/create-iiq-db-oracle.sh $rootPassword"

else
	# upload IIQ DB script to IIQ DB container
	docker cp ./create_identityiq_tables.mysql iiq-db:/tmp/

	# upload shell script to IIQ DB container
	docker cp ./shell/create-iiq-db.sh iiq-db:/tmp/
	docker exec -u 0 -it iiq-db chown root:root /tmp/create-iiq-db.sh
	docker exec -u 0 -it iiq-db bash -c "sed -i -e 's/\r$//' /tmp/create-iiq-db.sh"
	docker exec -u 0 --workdir /tmp iiq-db chmod 755 create-iiq-db.sh

	# run shell script in IIQ DB container to create IIQ DB & tables
	docker exec -it iiq-db sh -c "/tmp/create-iiq-db.sh $rootPassword"
fi

# download sp.init-custom.xml from IIQ App container
docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/config/sp.init-custom.xml .

echo "You can modify ${PWD}/sp.init-custom.xml to customise the files you want to import to IIQ. Type 'y' or 'Y' to override; Leave it empty or type any other values to skip. Press Enter to continue. "
read overrideInitCustom

if [[ $overrideInitCustom = 'y' ]] || [[ $overrideInitCustom = 'Y' ]];then
	echo "upload ${PWD}/sp.init-custom.xml to override"
	docker cp ./sp.init-custom.xml iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/config/sp.init-custom.xml
fi

# overried iiq (shell script to run iiq console) to increase JVM HEAP
docker cp ./shell/iiq iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/bin/iiq
docker exec -u 0 -it iiq-app chown root:root /usr/local/tomcat/webapps/identityiq/WEB-INF/bin/iiq
docker exec -u 0 -it iiq-app bash -c "sed -i -e 's/\r$//' /usr/local/tomcat/webapps/identityiq/WEB-INF/bin/iiq"
docker exec -u 0 --workdir /usr/local/tomcat/webapps/identityiq/WEB-INF/bin iiq-app chmod 755 iiq

docker cp ./shell/init-iiq.sh iiq-app:/tmp/
docker exec -u 0 -it iiq-app chown root:root /tmp/init-iiq.sh
docker exec -u 0 -it iiq-app bash -c "sed -i -e 's/\r$//' /tmp/init-iiq.sh"
docker exec -u 0 --workdir /tmp/ iiq-app chmod 755 init-iiq.sh
docker exec -it iiq-app bash -c "/tmp/init-iiq.sh"

echo "Deleting downloaded files: sp.init-custom.xml and create_identityiq_tables.mysql"
rm ./sp.init-custom.xml

if [[ $dbType = 'mssql' ]];then
	rm ./create_identityiq_tables.sqlserver
elif [[ $dbType = 'oracle' ]];then
	rm ./create_identityiq_tables.oracle
else
	rm ./create_identityiq_tables.mysql
fi
echo "Completed IIQ Setup. Please restart Docker Compose via 'Docker Compose up/down commands'. "
