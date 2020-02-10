#!/bin/bash

scriptdir=$(pwd)
configfile="./fsbackup.conf"

infolog="INFO"
errorlog="ERROR"
debuglog="DEBUG"


writeLog(){
	if [ -z "$logdir" ]; then
		logdir="./logs"
                echo "No log dir found. Setting default log dir: $logdir"
	fi
	mkdir -p $logdir
	local logfile="${logdir}/fsbackup-$(date "+%d%m%Y.%H%M").log"
	echo  "$1"	>>	$logfile
}



################################# Log Printer #################################################
#@param $1 Log Type. i.e. Normal, INFO, ERROR
#@param $2 Log String
printLog(){
	local logdatetime=$(date "+%d-%m-%Y %H:%M:%S")
	if [ $1 == 0 ] ; then
		echo  "$logdatetime         $2"
		writeLog "$logdatetime         $2"
	elif [ $1 == 1 ]; then
		echo -e "$logdatetime  \e[34m$infolog\e[0m   $2"
		writeLog "$logdatetime  $infolog   $2"
	elif [ $1 == 2 ]; then
		echo -e "$logdatetime  \e[31m$errorlog\e[0m   $2"
		writeLog "$logdatetime  $errorlog   $2"	>>	$logfile
	elif [ $1 == 3 ]; then
		echo -e "$logdatetime  \e[93m$debuglog\e[0m   $2"
		writeLog "$logdatetime  $debuglog   $2"
	fi
}

################################# Creates Default Configuration File #################################
generateConfigFile(){
	printLog "1" "Creating new configuration file"
	echo "######################### Backup Configuration File ##############################" >> $configfile
	echo "#Log File Locaton"
	echo "logdir=/var/log/fsbackup"			>> $configfile
	echo "#Note: After declaring any path make sure there is no leading \"slash\" \\ " >> $configfile
	echo "#i.e. /opt/backup "			>> $configfile
	echo "#Total number of days that each backup files are going to be keept" >> $configfile
	echo "backup_retention[0]=3"		>> $configfile
	echo "#Direcotry path that needs to be backed up as array" >> $configfile
	echo "backup_dir[0]=\"${scriptdir}\""	>> $configfile
	echo "#Backup Type. 0 = incremental , 1 = full"		>> $configfile
	echo "backup_type[0]=0"			>> $configfile
	echo "#Backup Store path where backup is going to be generated"		>> $configfile
	echo "backup_store_dir=\"/tmp/backup\""         >> $configfile
	echo "#Last Modification Time in minutes For Incremental Backup. i.e. 1440 for 24Hr or 1 Day" >> $configfile
	echo "last_modification[1]=1440"			>> $configfile
}

############################## Removes a List of Files #########################################
#@param $1 File List
removeFileByList(){
	if [ -z $1 ]; then
		printLog "1" "File list is empty for removing"
	else
		for files in $1
		do
			if [ -f $files ]; then
				printLog "0" "Removing File $files"
#				rm -f $files
			fi
		done
	fi
}

############################## Generate Full Backup ################################################
#@param $1 source dir path which is going to be backed up
#@param $2 destination dir where the backup file are going to be stored
generateFullBackup(){
	#Check if prameter is null
	if [ -z "$1" ] || [ -z "$2" ]; then
		printLog "2" "Source or Desitnation is empty Source $1   Destination $2 "
	else
		#Check if the source file or directory exists
		if [ -f $1 ] || [ -d $1 ]; then
			printLog "1" "Generating Full Backup."
			printLog "0" "|- Source Dir $1 "
			printLog "0" "|- Destination Dir $2"
			local compressedSize=`tar -cz $1 | wc -c`
			local destAvailableSize=`df --output=avail -B 1 "$2" | tail -n 1`
			printLog "0" "|- Possible size of the backup $compressedSize available size $destAvailableSize"
			#Check if the backup size is less then the available size of the directory where it is going to be backed up
			if [ $compressedSize -le $destAvailableSize ]; then
				printLog "0" "Generating Backup"
				local datetimeform=$(date "+%d%m%Y-%H%M%S")
				local backupFileName=`basename $1`
				local backupFileName="${backupFileName}-${datetimeform}.tar.gz"
				#Finally create the backup
				tar -czvf ${2}/${backupFileName} $1
				#Check if the tar compression failes or not. 
				if [[ $? -ne 0 ]]
				then
					printLog "2" "Backup Failed"
					printLog "0" "$?"
				else
					#After sucessfull backup change the current backup status 1. so we can now remove old backup files
					backup_status=1
					printLog "1" "Backup Sucessfull"
				    printLog "0" "|- File Path : $2/$backupFileName"
				fi
			else
				printLog "2" "Possible size of the backup file overflows the destination available size"
			fi
		else
			printLog "2" "Source file or directory dose not exists! $1"
		fi
	fi
}

############################## Generate Incremental Backup ################################################
#@param $1 source dir path which is going to be backed up
#@param $2 destination dir where the backup file are going to be stored
#@param $3 Last Modification time of backup files. 
generateIncrementalBackup(){
	#Check if prameter is null
	if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then
		printLog "2" "Source, Desitnation or Modification Time is missing. Source: $1  ,Destination: $2   ,Modification Time: $3"
	else
		printLog "1" "Generating Incremental Backup."
		printLog "0" "|- Source Dir $1 "
		printLog "0" "|- Destination Dir $2"
		local incBackupList=`find $1 -type f -mmin -${3}  -exec echo {} +`
		printLog "3" "find $1 -type f -mmin -${3}  -exec echo {} +"
		local incBackupListString=""
		for incBkup in $incBackupList
		do
			incBackupListString="$incBackupListString $incBkup"
		done
		if [[ $incBackupListString = "" ]]; then
			printLog "2" "No Files Found."
			printLog "0" "$incBackupListString"
		else
			local compressedSize=`tar -cz $incBackupListString | wc -c`
			local destAvailableSize=`df --output=avail -B 1 "$2" | tail -n 1`
			printLog "0" "|- Possible size of the backup $compressedSize available size $destAvailableSize"
			if [ $compressedSize -le $destAvailableSize ]; then
				printLog "0" "Generating Backup"
				local datetimeform=$(date "+%d%m%Y-%H%M%S")
				local backupFileName=`basename $1`
				local backupFileName="${backupFileName}-${datetimeform}.tar.gz"
				tar -czvf ${2}/${backupFileName} $incBackupListString
				printLog "3" "tar -czvf ${2}/${backupFileName} $incBackupListString"
				#Check if the tar compression failes or not. 
				if [[ $? -ne 0 ]]
				then
					printLog "2" "Backup Failed"
					printLog "0" "$?"
				else
					#After sucessfull backup change the current backup status 1. so we can now remove old backup files
					backup_status=1
					printLog "1" "Backup Sucessfull"
					printLog "0" "|- File Path : $2/$backupFileName"
				fi
			fi
		fi
	fi
}

############################## Starts the Backup Process ###############################################
generateBackup(){
	local total_backup="${#backup_dir[@]}"
	printLog "1" "Total Backup Job Found $total_backup"
	#Loop through total number of backup configuration
	for (( i=0 ; i<$total_backup ; i++));
	do
		backup_status=0
		printLog "0" "Current Backup Job no. $i"
		#If backup type = 1 then create a proceed for a full backup
		if [ ${backup_type[i]} -eq 1 ]; then
			printLog "0" "|- Full Backup for Job $i detected"
			local newfullbackupdir=${backup_store_dir[i]}/new
			local oldfullbackupdir=${backup_store_dir[i]}/old
			mkdir -p $newfullbackupdir
			mkdir -p $oldfullbackupdir
			generateFullBackup ${backup_dir[i]} $newfullbackupdir
			#If backup is sucessfull then remove older backup files as per retention policy
			if [ $backup_status -eq 1 ]; then
				printLog "1" "Removing Older Backups from dir $oldfullbackupdir"
				#Get the file names that is older accroding to retention policy
				local oldbackuplist=`find $oldfullbackupdir -type f -mtime +${backup_retention[i]} -name '*.tar.gz' -exec echo {} +`
				printLog "3" "find $oldfullbackupdir -type f -mtime +${backup_retention[i]} -name '*.tar.gz' -exec echo {} +"
				removeFileByList $oldbackuplist
			fi
		#If backup type = 0 then proceed for a incremental backup
		elif [ ${backup_type[i]} -eq 0 ]; then
			printLog "0" "|- Incremental Backup for Job $i detected"
			local newincbackupdir=${backup_store_dir[i]}/new
			local oldincbackupdir=${backup_store_dir[i]}/old
			local modificationTime=${last_modification[i]}
			mkdir -p $newincbackupdir
			mkdir -p $oldincbackupdir
			generateIncrementalBackup ${backup_dir[i]} $newincbackupdir $modificationTime
			if [ $backup_status -eq 1 ]; then
				printLog "1" "Removing Older Backups from dir $oldincbackupdir"
				#Get the file names that is older accroding to retention policy
				local oldbackuplist=`find $oldincbackupdir -type f -mtime +${backup_retention[i]} -name '*.tar.gz' -exec echo {} +`
				printLog "3" "find $oldincbackupdir -type f -mtime +${backup_retention[i]} -name '*.tar.gz' -exec echo {} +"
				removeFileByList $oldbackuplist
			fi
		fi
	done

}



if (test -f $configfile ) then
	printLog "INFO" "configuration file found. Importing configurations to the script"
	. $configfile
	generateBackup
else
	generateConfigFile
fi

