@echo off

set "rootPassword=Sailpoint@1234"
set /p rootPassword=Please specify password of SQL Server root user. Leave it empty and press Enter to continue with the default password 'Sailpoint@1234'. 

echo root password: %rootPassword%

@REM generate IIQ Database schema from IIQ App container
docker exec --workdir /usr/local/tomcat/webapps/identityiq/WEB-INF/bin iiq-app ./iiq schema

@REM download IIQ DB Script from IIQ App container
docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/database/create_identityiq_tables.sqlserver .
set /p continue=By default IIQ database name is 'identityiq'. But you can modify %cd%/create_identityiq_tables.sqlserver to override values before pressing Enter to continue.

@REM upload IIQ DB script to IIQ DB container
docker cp ./create_identityiq_tables.sqlserver iiq-mssql-db:/tmp/

@REM upload shell script to IIQ DB container
docker cp ./shell/create-iiq-db-mssql.sh iiq-mssql-db:/tmp/
docker exec --workdir /tmp iiq-mssql-db chmod 755 create-iiq-db-mssql.sh

@REM run shell script in IIQ DB container to create IIQ DB & tables
docker exec -it iiq-mssql-db sh -c "/tmp/create-iiq-db-mssql.sh %rootPassword%"

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

echo Deleting downloaded files: sp.init-custom.xml and create_identityiq_tables.mysql
DEL sp.init-custom.xml
DEL create_identityiq_tables.sqlserver

echo Completed IIQ Setup. Please restart Docker Compose via 'Docker Compose up/down commands'.