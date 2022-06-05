/* 
 * appserver_autoexec_usermods.sas
 *
 *    This autoexec file extends appserver_autoexec.sas.  Place your site-specific include 
 *    statements in this file.  
 *
 *    Do NOT modify the appserver_autoexec.sas file.  
 *    
 */



/* Инициализация макросов */ 
Options Mautosource
Sasautos=('C:\SAS\macro\common\','C:\SAS\macro\etl\','C:\SAS\macro\stg\','C:\SAS\macro\scm\',sasautos);

/* Инициализация библиотек */ 
libname WORK_STG BASE "\\pushserv\SAS\LIB\WORK_STG";
libname WORK_COM BASE "\\pushserv\SAS\LIB\WORK_COM";
libname SAS_STAT BASE "\\pushserv\SAS\LIB\SAS_STAT";
libname POSTGIS postgres dsn=PostgreSQL35W;
libname ETL_CTL postgres dsn=etlctl;


/* Глобальные переменные */
 %global ETL_CURRENT_JOB_ID ETL_PROCESS_ID;
 %let ETL_CURRENT_JOB_ID=;
 %let ETL_PROCESS_ID=1;