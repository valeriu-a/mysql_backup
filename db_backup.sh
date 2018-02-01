#!/bin/bash

### Make sure to redirect it to a logfile, as below:
### 0 3 * * * root db_backup.sh >> /var/log/db_backup.log 2>&1

### Catch the hour and minute with the following format: 0300
hour=$(date +%H%M)
### Get day of the week (Mon - Sun)
day_of_week=$(date +%a)
### Get the day of month
day_of_month=$(date +%d)

### Set the daily, weekly and monthly run. Make sure you set
### the run_hour, run_day and run_mday with with the exact
### same format as hour, day_of_week and day_of_month. Also,
### make sure you set the cron to run exactly at the same
### time as the run_hour (granularity is 1 minute)

run_hour="0300" ### 03:00 AM. Cron in this case: 0 3 * * *
run_day="Sat"
run_mday="01"

### Set the location of your backups
backup_location="/var/backups/mysql_backups"

### Set the details for the DB that will be backed up
user="user"
password="pass"
database="db"

### Set the timestamp format -- ex: 010220182159_Thu_Feb
timestamp=$(date +%d%m%Y%H%M_%a_%b)
dumpname="${database}_${timestamp}"
nicedate=$(date +%d.%m.%Y-%H:%M:%S)

### Create daily, weekly and monthly folders if they don't exist.
mkdir -p "${backup_location}"/daily
mkdir -p "${backup_location}"/weekly
mkdir -p "${backup_location}"/monthly

### Define the Mysql dump function and archival of the dump
function mysql_dump() {
  mysqldump -u "${user}" -p"${password}" -B "${database}" > "${dumpname}".sql
  tar -czf "${dumpname}".sql.tar.gz "${dumpname}".sql
  rm -rf "${dumpname}".sql
}

### Define the daily backup
function daily() {
  if [[ "${hour}" == "${run_hour}" ]]; then
    cd "${backup_location}"/daily
    echo "${nicedate} Dumping daily ${database} backup."
    mysql_dump
    echo "${nicedate} Daily backup done: ${backup_location}/daily/${dumpname}"
  else
    echo "${nicedate} Daily backup skipped."
  fi;

}

### Define the weekly backup
function weekly() {
  if [[ "${day_of_week}" == "${run_day}" && "${hour}" == "${run_hour}"  ]]; then
    cd "${backup_location}"/weekly
    echo "${nicedate} Dumping weekly ${database} backup."
    mysql_dump
    echo "${nicedate} Weekly backup done: ${backup_location}/daily/${dumpname}"
  else
    echo "${nicedate} Weekly backup skipped."
  fi;
}

### Define the monthly backup
function monthly() {
  if [[ "${day_of_month}" == "${run_mday}" && "${hour}" == "${run_hour}" ]]; then
    cd "${backup_location}"/monthly
    echo "${nicedate} Dumping monthly ${database} backup."
    mysql_dump
    echo -e "${nicedate} Monthly backup done: ${backup_location}/daily/${dumpname}\\n*****************************************"
  else
    echo -e "${nicedate} Monthly backup skipped.\\n*****************************************"

  fi;
}

### Cleanup before performing backups -- daily backups deleted if older than
### 7 days, weekly if older than 30 days and monthly if older than 355 days.
find "${backup_location}"/daily -type f -mtime +6 -exec rm -f {} \;
find "${backup_location}"/weekly -type f -mtime +30 -exec rm -f {} \;
find "${backup_location}"/monthly -type f -mtime +354 -exec rm -f {} \;

### Perform daily backup
daily
### Perform weekly backup
weekly
### Perform monthly backup
monthly
