#!/bin/bash

helpSequence ()
{
	printf "\e[31m\nExample usage of this script:\n"
	printf "\e[34m\t./backup_script.sh help\n"
	printf "\e[32m\t\tThe help command outputs this current sequence of strings\n\n"
	printf "\e[34m\t./backup_script.sh relative/backup/directory/path/\n"
	printf "\e[32m\t\tThis runs the script as intended. The backup for both the file server and\n\t\tthe database will be placed in the directory provided.\n\n\e[39m"
}

sshPortNumber=22 # Default SSH Port is Port 22
# sshPrivateKey= # Can be ommitted if allowable
sshUser=
sshHost=
databaseName=
databaseUser=

# Check if variables are set
if [ -z $sshPortNumber ] || [ -z $sshUser ] || [ -z $sshHost ] || [ -z $databaseName ] || [ -z $databaseUser ]
then
	printf "\e[31mFATAL: Not all needed variables are set. Please set all required variables and re-run.\e[0m\n"
	exit 1
fi

# Check if help dialouge is needed
if [ "$1" = "help" ] || [ $# != 1 ]
then
	helpSequence
	exit $?
else # Backup Directory Logic
	backupDir=$1

	# Check if trailing slash exists on backup directory
	if [ "${backupDir: -1}" != "/" ]
	then
		backupDir=$backupDir"/"
	fi

	# Check if backup directory exists
	if [ ! -d "$backupDir" ]
	then
		printf "\e[31m\nCreating Given Directory\e[5m...\e[0m\n"
		mkdir $backupDir
		printf "\e[32mCreated: ${backupDir}\e[0m\n"
	fi
fi


printf "\e[31m\nChecking for and Deleting Old Database Exports in Backup Folder\e[5m...\e[0m\n"
rm -f $backupDir$databaseName.sql

printf "\e[31m\nExporting MySQL Database\e[5m...\e[0m\n"
ssh -tt -p $sshPortNumber -i $sshPrivateKey $sshUser@$sshHost 'mysqldump -u '$databaseUser' -p '$databaseName' > '$databaseName'.sql'

printf "\n\e[31m\nCopying Database Export to Local Machine\e[5m...\e[0m\n"
scp -P $sshPortNumber -i $sshPrivateKey $sshUser@$sshHost:~/$databaseName.sql $backupDir$databaseName.sql

printf "\n\e[31m\nRemoving Database Export from Remote Server\e[5m...\e[0m\n"
ssh -tt -p $sshPortNumber -i $sshPrivateKey $sshUser@$sshHost 'rm -f '$databaseName'.sql'

printf "\n\e[31m\nSyncing Remote File Server with Local Copy\e[5m...\e[0m\n"
rsync -zr -e "ssh -p $sshPortNumber -i $sshPrivateKey" --progress $sshUser@$sshHost:~/public_html/ $backupDir"public_html"

printf "\e[32m\nBackup Successfully Completed... Exiting\e[0m\n\n"

exit $?
