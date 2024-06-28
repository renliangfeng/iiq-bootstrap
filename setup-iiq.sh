#!/bin/sh

echo "Please specify password of MySQL root user. Leave it empty and press Enter to continue with the default password 'Sailpoint@1234'. "
read rootPassword

# echo "root password: $rootPassword"

if [[ $rootPassword = '' ]];then
	rootPassword=Sailpoint@1234
fi

echo "root password: $rootPassword"

# generate IIQ Database schema from IIQ App container
docker exec --workdir /usr/local/tomcat/webapps/identityiq/WEB-INF/bin iiq-app ./iiq schema

# download IIQ DB Script from IIQ App container
docker cp iiq-app:/usr/local/tomcat/webapps/identityiq/WEB-INF/database/create_identityiq_tables.mysql .

echo "By default IIQ database name is 'identityiq'. But you can modify ${PWD}/create_identityiq_tables.mysql to override values before pressing Enter to continue".
read continue

# upload IIQ DB script to IIQ DB container
docker cp ./create_identityiq_tables.mysql iiq-db:/tmp/

# upload shell script to IIQ DB container
docker cp ./shell/create-iiq-db.sh iiq-db:/tmp/
docker exec --workdir /tmp iiq-db chmod 755 create-iiq-db.sh

# run shell script in IIQ DB container to create IIQ DB & tables
docker exec -it iiq-db sh -c "/tmp/create-iiq-db.sh $rootPassword"

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
docker exec --workdir /usr/local/tomcat/webapps/identityiq/WEB-INF/bin iiq-app chmod 755 iiq

docker cp ./shell/init-iiq.sh iiq-app:/tmp/
docker exec --workdir /tmp/ iiq-app chmod 755 init-iiq.sh

docker exec -it iiq-app bash -c "/tmp/init-iiq.sh"

echo "Deleting downloaded files: sp.init-custom.xml and create_identityiq_tables.mysql"
rm ./sp.init-custom.xml
rm ./create_identityiq_tables.mysql 

echo "Completed IIQ Setup. Please restart Docker Compose via 'Docker Compose up/down commands'. "
