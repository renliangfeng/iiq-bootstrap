# iiq-bootstrap
Build IIQ from SSB compliant folder and run it in Docker Desktop rapidly. It supports MySQL and SQL Server as IIQ backed Database.

Below are the steps of kick-start.

## step 1: copy entire SSB folder to:
iiq-bootstrap/iiq_app
## step 2: build docker images
Run command from *iiq-bootstrap* directory:

`ssb_app_folder=[[appFolder]] sp_target=[[envValue]] docker compose up`

Notes: To run SQL Server as IIQ Database, update **.env** file to add line:

`COMPOSE_FILE=mssql-compose.yaml`

Or add it to the front of 'docker compose up' command as below:

`COMPOSE_FILE=mssql-compose.yaml ssb_app_folder=[[appFolder]] sp_target=[[envValue]] docker compose up`

## step 3: install and initialize database
Run command from *iiq-bootstrap* directory:
### Mac (Linux) OS
`./setup-iiq.sh `

### Windows OS and MySQL DB
`setup-iiq.bat`
### Windows OS and SQL Server DB
`setup-iiq-mssql.bat`

*Notes: Unlike Window Batch, there is only one Shell script for Mac or Linux as it automatically detects the type (MySQL or SQL Server) of running Database for IIQ.*

## step 4: restart docker compose
Run commands from *iiq-bootstrap* directory:

`docker compose down`

`docker compose up`
