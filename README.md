# iiq-bootstrap
Build IIQ from SSB compliant folder and run it in Docker Desktop rapidly. It supports MySQL, SQL Server, Oracle, PostgreSQL as IIQ backed Database.

Below are the steps of kick-start.

## step 1: copy entire SSB folder to:
iiq-bootstrap/iiq_app
## step 2: build docker images
Run command from *iiq-bootstrap* directory:

`ssb_app_folder=[[appFolder]] sp_target=[[envValue]] docker compose up`

Notes: To run SQL Server or Oracle as IIQ Database, update **.env** file (hidden file under root folder) to add line:

`COMPOSE_FILE=mssql-compose.yaml`

or

`COMPOSE_FILE=oracle-compose.yaml`

or

`COMPOSE_FILE=psql-compose.yaml`

Or add it to the front of '*docker compose up*' command as below:

`COMPOSE_FILE=mssql-compose.yaml ssb_app_folder=[[appFolder]] sp_target=[[envValue]] docker compose up`

Alternately, you can define all the parameters (`ssb_app_folder`, `sp_target` and `COMPOSE_FILE`) in **.env** file, then simply run `docker compose up` command.

If you are running IIQ with MySQL in linux, you need to update compose.yaml file to replace one line with following (setting "lower-case-table-names" as "1"):


 	command: mysqld --default-authentication-plugin=mysql_native_password --lower-case-table-names=1 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    

If you get the following error the first time running command `docker compose up`, you may need to disable your VPN temporily. You can enable VPN back once IIQ docker image is built successfully.

<img width="975" height="181" alt="image" src="https://github.com/user-attachments/assets/283e202f-6097-4526-aa74-0c96d2d921b2" />


## step 3: install and initialize database
Run command from *iiq-bootstrap* directory:
### Mac (Linux) OS
`./setup-iiq.sh `

### Windows OS and MySQL DB
`setup-iiq.bat`
### Windows OS and SQL Server DB
`setup-iiq-mssql.bat`
### Windows OS and Oracle DB
`setup-iiq-oracle.bat`
### Windows OS and PostgreSQL DB
TODO - will be supported in the future.

***Additional Notes:*** 
- *Unlike Window Batch, there is only one Shell script for Mac or Linux as it automatically detects the type (MySQL or SQL Server or Oracle or PostgreSQL) of running Database for IIQ.*
- *By default, it will install LCM and RapidSetup XML Objects. If you want to skip them, you need to modify the following shell script to remove the section related to LCM or RapidSetup XML import*:
  
		iiq-bootstrap/shell/init-iiq.sh

## step 4: restart docker compose
Run commands from *iiq-bootstrap* directory:

`docker compose down`

`docker compose up`

## Reset from scratch
Installing IIQ is usually an one-off effort. However if you need to start over again for any reasons, you need to perform the following clean-up steps first.

- Clean up Database data. Delete all files under the following folder according to the type of Database (MySQL or SQL Server or Oracle) used by IIQ.
	
	- **MySQL**: iiq-bootstrap/volume/mysql/mysql-data 
	- **SQL Server**: iiq-bootstrap/volume/mssql/data
	- **Oracle**: iiq-bootstrap/volume/oracle/oracle-data
	- **PostgreSQL**: **make sure you delete the whole folder** (iiq-bootstrap/volume/psql), otherwise Docker Desktop will fail to create PostgreSQL container instance.

- Delete Container instances group **iiq-bootstrap** from Docker Desktop. This will delete both Container instances under group **iiq-bootstrap**.
- If you switch to a different IIQ application, delete **iiq-app** image from Docker Desktop.
- Try to delete all Volumes from Docker Desktop if you encounter any issues.
- Now follow the previous steps to install IIQ.
