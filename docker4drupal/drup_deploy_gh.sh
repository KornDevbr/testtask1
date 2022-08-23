#!/bin/bash

# Turn on Drupal maintenance mode
drush sset system.maintenance_mode TRUE

# Make db backup
mkdir ../../../db_backup
drush sql-dump --structure-tables-list=cache,cache_* --gzip --result-file=../../../db_backup/backup-$(date +"%Y-%m-%d").sql

# Pull the master branch from the repository
git pull https://github.com/KornDevbr/testtask.git master

# If git pull made an error 
if [ `echo $?` != 0 ]; then
	
	# Make backup of broken database for auditing
	mkdir ../../../db_backup_br
	drush sql-dump --structure-tables-list=cache,cache_* --gzip --result-file=../../../db_backup_br/backup-$(date +"%Y-%m-%d").sql

# Move back before "git pull"
	git reset --hard HEAD@{1}

	# Restore database
	zcat ../../db-backup/backup-$(date +"%Y-%m-%d").sql.gz | drush sql-cli

	# Turn off Drupal maintence mode
	drush sset system.maintenance_mode FALSE
	
	echo
	echo
	echo "Git pull error :("
	echo
	echo

	exit
	
fi

# Download all needed modules
composer install -o --no-dev

# If composer install made an error 
if [ `echo $?` != 0 ]; then
	
	# Make backup of broken database for auditing
	drush sql-dump --structure-tables-list=cache,cache_* --gzip --result-file=../../../db_backup_br/backup-$(date +"%Y-%m-%d").sql

	# Move back before "git pull"
	git reset --hard HEAD@{1}

	# Restore database
	zcat ../../db-backup/backup-$(date +"%Y-%m-%d").sql.gz | drush sql-cli

	# Restore all needed modules
	composer install -o --no-dev

	# Turn off Drupal maintence mode
	drush sset system.maintenance_mode FALSE
	
	echo
	echo
	echo "Composer install error :("
	echo
	echo

	exit
	
fi

# Final stage of deployment
drush deploy -v -y

# If drush deploy made an error
if [ `echo $?` != 0 ]; then
	
	# Make backup of broken database for auditing
	drush sql-dump --structure-tables-list=cache,cache_* --gzip --result-file=../../../db_backup_br/backup-$(date +"%Y-%m-%d").sql

	# Move back before "git pull"
	git reset --hard HEAD@{1}

	# Restore database
	zcat ../../db-backup/backup-$(date +"%Y-%m-%d").sql.gz | drush sql-cli

	# Restore all needed modules
	composer install -o --no-dev

	# Restore deployment
	drush deploy -v -y

	# Turn off Drupal maintence mode
	drush sset system.maintenance_mode FALSE

	echo
	echo
	echo "Drush deploy error :("
	echo
	echo

	exit
	
fi

# Turn off Drupal maintence mode
drush sset system.maintenance_mode FALSE

# Clear caches
drush cr

echo
echo
echo "DEPLOYMENT IS SUCCESSFULL"
echo
echo


