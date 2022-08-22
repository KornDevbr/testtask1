#!/bin/bash

# Turn on Drupal maintenance mode
drush sset system.maintenance_mode TRUE

# Make db backup
mkdir ../../db_backup
drush sql-dump --structure-tables-list=cache,cache_* --gzip --result-file=../../db_backup/backup-$(date +"%Y-%m-%d").sql


BACKUP_COMMIT=$(git rev-parse HEAD)

# Make functions to frequently using commands

turn_off_mm () {				#turn off maintenance mode
	drush sset system.maintenance_mode FALSE
}
git_ch_out () {					#undo to previous working checkout
	git checkout $BACKUP_COMMIT
}
comp_inst () {					#Installing composer without development modules
	composer install -o --no-dev
}

# Fetch and checkout on new commit hash
git fetch $BITBUCKET_GIT_HTTP_ORIGIN
git checkout $BITBUCKET_COMMIT

# If git pull made an error 
if [ `echo $?` = 0 ]; then

	git_ch_out

	turn_off_mm

	echo
	echo
	echo "Git error :("
	echo
	echo
	exit 1
	
fi

# Download all needed modules
comp_inst

# If composer install made an error 
if [ `echo $?` = 0 ]; then
	
	git_ch_out	

	comp_inst
	
	turn_off_mm

	echo
	echo
	echo "Composer install error :("
	echo
	echo

	exit 1
	
fi

# Final stage of deployment
drush deploy -v -y

# If drush deploy made an error
if [ `echo $?` = 0 ]; then
	
	git_ch_out	

	comp_inst

	# Restore deployment
	drush deploy -v -y

	turn_off_mm

	echo
	echo
	echo "Drush deploy error :("
	echo
	echo

	exit 1
	
fi

# Turn off Drupal maintence mode
turn_off_mm

echo
echo
echo "DEPLOYMENT IS SUCCESSFULL"
echo
echo


