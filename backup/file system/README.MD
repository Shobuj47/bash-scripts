# File System Backup Script

> Note:	Add each backups configuration as an array. Don't put the leading slash after each directory location
>> Tested within Red Hat Linux 7 and CentOS 7


### Configure Script Log Directory Location. i.e. /app/script_log
```Bash
logdir="/app/script_log"
```
## Full Backups
* Total number of days that each backup files are going to be keept. i.e. Number of days = 3
```Bash 
backup_retention[0]=3
```

* Direcotry path which is going to backup. i.e.  /app/some_nice_application
```Bash
backup_dir[0]="/app/some_nice_application"
```

* Backup Type. 0 = incremental , 1 = full. i.e. 1 for full backup
```Bash
#backup_type[0]=1
```
* Backup Store path where backup is going to be generated. i.e. /app/backup_framework is the path where the backup are going to be created.
```Bash
backup_store_dir[0]="/app/backup_framework"
```

## Incremental Backups
* Last Modification Time in minutes For Incremental Backup. i.e. 1440 for 24Hr or 1 Day. Files that are modified within these past minutes are going to be backup.
```Bash
last_modification[1]=7200
```

* Total number of days that each backup files are going to be keept. i.e. Number of days = 1
```Bash
backup_retention[1]=1
```

* Direcotry path which is going to backup. i.e.  /app/some_nice_application
```Bash
backup_dir[1]="/app/some_nice_application"
```
* Backup Type. 0 = incremental , 1 = full. i.e. 1 for full backup
```Bash 
backup_type[1]=0
```
* Backup Store path where backup is going to be generated. i.e. /app/backup_framework is the path where the backup are going to be created.
```Bash
backup_store_dir[1]="/app/backup_pm_diff"
```





