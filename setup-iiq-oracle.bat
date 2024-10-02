@echo off

set "rootPassword=Sailpoint_1234"
set /p rootPassword=Please specify password of Oracle root user. Leave it empty and press Enter to continue with the default password 'Sailpoint_1234'. 

echo root password: %rootPassword%

@REM generate IIQ Database schema from IIQ App container
docker exec --workdir /usr/local/tomcat/webapps/identityiq/WEB-INF/bin iiq-app ./iiq schema

@REM download IIQ DB Script from IIQ App container
docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/database/create_identityiq_tables.oracle .
set /p continue=By default IIQ database name is 'identityiq'. But you can modify %cd%/create_identityiq_users.oracle and %cd%/create_identityiq_tables.oracle to override values before pressing Enter to continue.

@REM upload IIQ DB script to IIQ DB container
docker cp ./create_identityiq_users.oracle iiq-oracle-db:/tmp/
docker cp ./create_identityiq_tables.oracle iiq-oracle-db:/tmp/

@REM increase size of some DB table columes to prevent errors
docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/IS_DURABLE VARCHAR2(1)/IS_DURABLE VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"
docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/IS_NONCONCURRENT VARCHAR2(1)/IS_NONCONCURRENT VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"
docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/IS_UPDATE_DATA VARCHAR2(1)/IS_UPDATE_DATA VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"
docker exec -u 0 -it iiq-oracle-db bash -c "sed -i -e 's/REQUESTS_RECOVERY VARCHAR2(1)/REQUESTS_RECOVERY VARCHAR2(5)/g' /tmp/create_identityiq_tables.oracle"

@REM upload shell script to IIQ DB container
docker cp ./shell/create-iiq-db-oracle.sh iiq-oracle-db:/tmp/
docker exec --workdir /tmp iiq-oracle-db chmod 755 create-iiq-db-oracle.sh

@REM run shell script in IIQ DB container to create IIQ DB & tables
docker exec -it iiq-oracle-db sh -c "/tmp/create-iiq-db-oracle.sh %rootPassword%"

@REM download sp.init-custom.xml from IIQ App container
docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/config/sp.init-custom.xml .

set "overrideInitCustom=n"
set /p overrideInitCustom=You can modify %cd%/sp.init-custom.xml to customise the files you want to import to IIQ. Type 'y' or 'Y' to override; Leave it empty or type any other values to skip. Press Enter to continue.

if not %overrideInitCustom% == y (
	if not %overrideInitCustom% == Y (
		echo not to override sp.init-custom.xml
		GOTO importXML
	)
)

echo upload %cd%/sp.init-custom.xml to override
docker cp ./sp.init-custom.xml iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/config/sp.init-custom.xml

:importXML

@REM overried iiq (shell script to run iiq console) to increase JVM HEAP
docker cp ./shell/iiq iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/bin/iiq
docker exec --workdir /usr/local/tomcat/webapps/identityiq/WEB-INF/bin iiq-app chmod 755 iiq

docker cp ./shell/init-iiq.sh iiq-app:/tmp/
docker exec --workdir /tmp/ iiq-app chmod 755 init-iiq.sh

docker exec -it iiq-app bash -c "/tmp/init-iiq.sh"

echo Deleting downloaded files: sp.init-custom.xml and create_identityiq_tables.oracle
DEL sp.init-custom.xml
DEL create_identityiq_tables.oracle

echo Completed IIQ Setup. Please restart Docker Compose via 'Docker Compose up/down commands'.