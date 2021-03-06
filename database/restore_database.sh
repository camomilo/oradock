#!/bin/bash
source ~/.bash_profile

restore(){
  backup_dir=$1
  db_restore=$(echo "$2" | sed 's/,/ /g')
  db_memory_distribution=$3
  db_main_service=$4
  script_home=$5
  data_dir=$6
  spfile_backup_name=$7
  controlfile_backup_name=$8
  parallel_level=$9
  position=1

  cp ${script_home}/conf/listener/listener_template.ora $ORACLE_HOME/network/admin/listener.ora
  sed -i "s|\${hostname}|$(hostname)|g" $ORACLE_HOME/network/admin/listener.ora

  for database in ${db_restore}
  do
    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: restore & recovering ${database} database. Log will be save at '/tmp/restore_${database}.log' on inside container"

    export ORACLE_SID=${database}
    memory_distribution=$(echo "${db_memory_distribution}" | awk -F"," '{print $'${position}'}')
	backup_db_dir=$(echo "${backup_dir}" | awk -F"," '{print $'${position}'}')
    main_service=$(echo "${db_main_service}" | awk -F"," '{print $'${position}'}')

    echo "DB_NAME='${database}'" > $ORACLE_HOME/dbs/init${database}.ora
    
	if [ -d ${backup_db_dir} ]
	then
		backup_spfile=$(find ${backup_db_dir} -iname ${spfile_backup_name} -exec ls -trh "{}" + | tail -1)
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: spfile does not exists"
		continue
	fi

    rman target=/ > /tmp/restore_${database}.log << EOF
    startup nomount force;
    restore spfile from '${backup_spfile}';
    shutdown abort;
    exit;
EOF

    echo "SPFILE='$ORACLE_HOME/dbs/spfile${database}.ora'" > $ORACLE_HOME/dbs/init${database}.ora
    mkdir -p /u01/app/oracle/admin/${database}/adump
    chown -R oracle:oinstall /u01/app/oracle/admin/${database}/adump
    mkdir -p ${data_dir}/${database}
    chown -R oracle:oinstall ${data_dir}/${database}
    rm -rf ${data_dir}/${database}/*
    mkdir -p ${data_dir}/${database}/controlfile
    mkdir -p ${data_dir}/${database}/datafile
    mkdir -p ${data_dir}/${database}/fast_recovery_area
    mkdir -p ${data_dir}/${database}/redolog
    mkdir -p ${data_dir}/${database}/spfile

    sqlplus / as sysdba >> /tmp/restore_${database}.log << EOF
      create pfile='/tmp/old_pfile${database}.ora' from spfile='$ORACLE_HOME/dbs/spfile${database}.ora';
      exit;
EOF

    rm -f $ORACLE_HOME/dbs/spfile${database}.ora

	if [ -e /tmp/old_pfile${database}.ora ]; then
	  grep -v "^${database}.__" /tmp/old_pfile${database}.ora > /tmp/new_pfile${database}.ora
	else
	  echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: spfile does not exists"
	  exit 1
	fi
    #comment all parameters to rewrite
    sed -i "s|\*.control_files=|\#\*.control_files=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.db_create_file_dest=|\#\*.db_create_file_dest=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.db_file_name_convert=|\#\*.db_file_name_convert=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.db_create_online_log_dest_|\#\*.db_create_online_log_dest_|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_file_name_convert=|\#\*.log_file_name_convert=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.db_recovery_file_dest=|\#\*.db_recovery_file_dest=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.db_recovery_file_dest_size=|\#\*.db_recovery_file_dest_size=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.local_listener=|\#\*.local_listener=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.sga_max_size=|\#\*.sga_max_size=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.sga_target=|\#\*.sga_target=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.pga_aggregate_target=|\#\*.pga_aggregate_target=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.memory_max_target=|\#\*.memory_max_target=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.memory_target=|\#\*.memory_target=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.processes=|\#\*.processes=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.use_large_pages=|\#\*.use_large_pages=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_config=|\#\*.log_archive_config=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_1=|\#\*.log_archive_dest_1=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_2=|\#\*.log_archive_dest_2=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_3=|\#\*.log_archive_dest_3=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_4=|\#\*.log_archive_dest_4=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_5=|\#\*.log_archive_dest_5=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_6=|\#\*.log_archive_dest_6=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_7=|\#\*.log_archive_dest_7=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_8=|\#\*.log_archive_dest_8=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_9=|\#\*.log_archive_dest_9=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_10=|\#\*.log_archive_dest_10=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_11=|\#\*.log_archive_dest_11=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_12=|\#\*.log_archive_dest_12=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_13=|\#\*.log_archive_dest_13=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_14=|\#\*.log_archive_dest_14=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_15=|\#\*.log_archive_dest_15=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_16=|\#\*.log_archive_dest_16=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_17=|\#\*.log_archive_dest_17=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_18=|\#\*.log_archive_dest_18=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_19=|\#\*.log_archive_dest_19=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_20=|\#\*.log_archive_dest_20=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_21=|\#\*.log_archive_dest_21=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_22=|\#\*.log_archive_dest_22=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_23=|\#\*.log_archive_dest_23=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_24=|\#\*.log_archive_dest_24=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_25=|\#\*.log_archive_dest_25=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_26=|\#\*.log_archive_dest_26=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_27=|\#\*.log_archive_dest_27=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_28=|\#\*.log_archive_dest_28=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_29=|\#\*.log_archive_dest_29=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_30=|\#\*.log_archive_dest_30=|g" /tmp/new_pfile${database}.ora
    sed -i "s|\*.log_archive_dest_31=|\#\*.log_archive_dest_31=|g" /tmp/new_pfile${database}.ora

    #setting min parameters to restore
    echo "*.control_files='${data_dir}/${database}/controlfile/control01.ctl','${data_dir}/${database}/controlfile/control02.ctl'" >> /tmp/new_pfile${database}.ora
    echo "*.db_create_file_dest='${data_dir}/${database}/datafile'" >> /tmp/new_pfile${database}.ora
    echo "*.db_create_online_log_dest_1='${data_dir}/${database}/redolog'" >> /tmp/new_pfile${database}.ora
    echo "*.db_create_online_log_dest_2='${data_dir}/${database}/redolog'" >> /tmp/new_pfile${database}.ora
    echo "*.db_create_online_log_dest_3='${data_dir}/${database}/redolog'" >> /tmp/new_pfile${database}.ora
    echo "*.db_create_online_log_dest_4='${data_dir}/${database}/redolog'" >> /tmp/new_pfile${database}.ora
    echo "*.db_create_online_log_dest_5='${data_dir}/${database}/redolog'" >> /tmp/new_pfile${database}.ora
    echo "*.db_recovery_file_dest='${data_dir}/${database}/fast_recovery_area'" >> /tmp/new_pfile${database}.ora
    echo "*.db_recovery_file_dest_size=50G" >> /tmp/new_pfile${database}.ora
    total_mem_gb=$(free -m | grep "Mem:" | awk '{print $2}')
    sga_and_process_size=$(echo "scale=1; ${total_mem_gb}*${memory_distribution}/100*0.6" | bc -l | awk -F. '{print $1}')
    echo "*.sga_max_size=${sga_and_process_size}M" >> /tmp/new_pfile${database}.ora
    echo "*.sga_target=${sga_and_process_size}M" >> /tmp/new_pfile${database}.ora
    pga_size=$(echo "scale=1; ${total_mem_gb}*${memory_distribution}/100*0.4" | bc -l | awk -F. '{print $1}')
    echo "*.pga_aggregate_target=${pga_size}M" >> /tmp/new_pfile${database}.ora
    echo "*.processes=${sga_and_process_size}" >> /tmp/new_pfile${database}.ora

    echo "SPFILE='${data_dir}/${database}/spfile/spfile${database}.ora'" > $ORACLE_HOME/dbs/init${database}.ora
    sqlplus / as sysdba >> /tmp/restore_${database}.log << EOF
      create spfile='${data_dir}/${database}/spfile/spfile${database}.ora' from pfile='/tmp/new_pfile${database}.ora';
      startup nomount;
EOF

    backup_controlfile=$(find ${backup_db_dir} -iname ${controlfile_backup_name} -exec ls -trh "{}" + | tail -1)

    rman target=/ >> /tmp/restore_${database}.log << EOF
      restore controlfile from '${backup_controlfile}';
      alter database mount;
      sql 'alter database flashback off';
EOF

    sqlplus -s / as sysdba > /dev/null << EOF
      alter database disable block change tracking;
EOF

    channels=""
    for ((cpu_count=1; cpu_count <= ${parallel_level}; cpu_count++))
    do
      channels=$(echo -e "${channels} allocate channel channel${cpu_count} device type disk;")
    done

    release_channels=""
    for ((cpu_count=1; cpu_count <= $(cat /proc/cpuinfo | grep processor | wc -l); cpu_count++))
    do
      release_channels=$(echo -e "${release_channels} release channel channel${cpu_count};")
    done

    rman target=/ >> /tmp/restore_${database}.log << EOF
      RUN {
        set newname for database to '${data_dir}/${database}/datafile/%b';

        ${channels}

        catalog start with '${backup_db_dir}' noprompt;
        restore database;
        switch datafile all;
        recover database;
        ${release_channels}
      }
EOF

    sqlplus -s / as sysdba > /tmp/rename_redolog_${database}.sql << EOF
    set lines 500;
    set pages 500;
    set feedback off;
    set pagesize 0;
    set termout off;

    SELECT 'ALTER DATABASE RENAME FILE '''
    || old_redo.redo_files
    || ''' to '''
    || new_redo.new_redo_files
    || ''';' AS command
  FROM
    (SELECT group_number,
      redo_files
    FROM
      (SELECT group# AS group_number,
        listagg(member, ''',''') within GROUP (
      ORDER BY group#) AS redo_files
      FROM v\$logfile
      GROUP BY group#
      )
    ) old_redo,
    (SELECT group# AS group_number,
      listagg('${data_dir}/${database}/redolog/'
      || new_redologs, ''',''') within GROUP (
    ORDER BY group#) AS new_redo_files
    FROM
      (SELECT redologs.*,
        'redo0'
        || rownum
        || '.log' AS new_redologs
      FROM v\$logfile redologs
      )
    GROUP BY group#
    ) new_redo
  WHERE old_redo.group_number = new_redo.group_number;
EOF

    sqlplus / as sysdba >> /tmp/restore_${database}.log << EOF
      @/tmp/rename_redolog_${database}.sql;
      alter database open resetlogs;
      alter system set service_names='${main_service}';

      shutdown immediate;
      startup mount;
      alter database archivelog;
      alter database open;
EOF

    if [ $(grep -e "^ORA-" /tmp/restore_${database}.log | wc -l) -ne 0 ]
    then
      echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR: fail to restore database ${database}. Please check logfile '/tmp/restore_${database}.log'"
      continue
    fi

    echo "${database}:$ORACLE_HOME:Y		# line added by Agent" >> /etc/oratab

    echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: restore & recover of ${database} database finished"
    position=$((position+1))
  done

  echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: starting listener, logfile '/tmp/start_listener.log' inside container"
  lsnrctl start > /tmp/start_listener.log
  crontab_config ${script_home}
  echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: container ready to use"
}

crontab_config(){
  echo "$(date +"%Y-%m-%d %H:%M:%S") INFO: configuring crontab"
  crontab ${script_home}/conf/cron/crontab.config
}

main(){
  backup_dir=$1
  db_restore=$2
  db_memory_distribution=$3
  db_main_service=$4
  script_home=$5
  data_dir=$6
  spfile_backup_name=$7
  controlfile_backup_name=$8
  parallel_level=$9

  restore ${backup_dir} ${db_restore} ${db_memory_distribution} ${db_main_service} ${script_home} ${data_dir} ${spfile_backup_name} ${controlfile_backup_name} ${parallel_level}
}

main $1 $2 $3 $4 $5 $6 $7 $8 $9
