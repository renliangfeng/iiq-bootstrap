# iiq-bootstrap
Build IIQ from SSB compliant folder and run it in Docker Desktop rapidly. It supports MySQL and SQL Server as IIQ backed Database.

Below are the steps of kick-start.

## step 1: copy entire SSB folder to:
iiq-bootstrap/iiq_app
## step 2: build docker images
Run command from *iiq-bootstrap* directory:

`ssb_app_folder=[[appFolder]] sp_target=[[envValue]] docker compose up`

Notes: To run SQL Server as IIQ Database, update **.env** file (hidden file under root folder) to add line:

`COMPOSE_FILE=mssql-compose.yaml`

Or add it to the front of '*docker compose up*' command as below:

`COMPOSE_FILE=mssql-compose.yaml ssb_app_folder=[[appFolder]] sp_target=[[envValue]] docker compose up`

## step 3: install and initialize database
Run command from *iiq-bootstrap* directory:
### Mac (Linux) OS
`./setup-iiq.sh `

### Windows OS and MySQL DB
`setup-iiq.bat`
### Windows OS and SQL Server DB
`setup-iiq-mssql.bat`

***Additional Notes:*** 
- *Unlike Window Batch, there is only one Shell script for Mac or Linux as it automatically detects the type (MySQL or SQL Server) of running Database for IIQ.*
- *By default, it will install LCM and RapidSetup XML Objects. If you want to skip them, you need to modify the following shell script to remove the section related to LCM or RapidSetup XML import*:
  
		iiq-bootstrap/shell/init-iiq.sh

## step 4: restart docker compose
Run commands from *iiq-bootstrap* directory:

`docker compose down`

`docker compose up`

## Reset from scratch
Installing IIQ is usually an one-off effort. However if you need to start over again for any reasons, you need to perform the following clean-up steps first.

- Clean up Database data. Delete all files under the following folder according to the type of Database (MySQL or SQL Server) used by IIQ.
	
	- **MySQL**: iiq-bootstrap/volume/mysql/mysql-data 
	- **SQL Server**: iiq-bootstrap/volume/mssql/data

- Delete Container instances group **iiq-bootstrap** from Docker Desktop. This will delete both Container instances under group **iiq-bootstrap**.
- If you switch to a different IIQ application, delete **iiq-app** image from Docker Desktop.
- Try to delete all Volumes from Docker Desktop if you encounter any issues.
- Now follow the previous steps to install IIQ.
