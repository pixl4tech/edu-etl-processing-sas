
/* Получает список файлов из директории показателя и загружает все файлы в стейджинг */

/*
ПРИМЕР ВЫЗОВА:
%stg_loop_load_inds(
	mpFilePath=C:\Users\XeonServ\PycharmProjects\untitled\CSV\8055003\,
	ind_cd=8055003,
	mpYear=2015
);
*/

%macro stg_loop_load_inds(
	mpFilePath=,
	mpIndGroupId=
);

	%folder_list(
	mpInFolderName="&mpFilePath", 
	mpOut=indcd_list(RENAME=(file_nm=ind_cd))
	);

	%macro _inner_by_inds;
		%folder_list(
		mpInFolderName="%TRIM(%sysfunc(CAT(&mpFilePath,&ind_cd,\)))", 
		mpOut=years_list(RENAME=(file_nm=year_nm))
		);

		%macro _inner_by_year;
			%folder_list(
			mpInFolderName="%TRIM(%sysfunc(CAT(&mpFilePath,&ind_cd,\,&year_nm,\)))",
			mpFilter=".csv$", 
			mpOut=File_list);
			
			%if ^%member_exists (WORK_STG.I&ind_cd.) %then %do;
				data WORK_STG.I&ind_cd.;
					set WORK_COM.DATA_OBS_D;
					if 1=0 then output;
				run;
			%end;
			
			data work.registry_load(drop=RLOAD_PROCESS_DTTM);
			set etl_ctl.registry_load(obs=0);
			run;

			%macro ___load_stat_ind;
				%stg_load_stat_ind(
					mpFilePath=%TRIM(%sysfunc(CAT(&mpFilePath,&ind_cd,\,&year_nm,\))),
					mpFileName=%str(&file_nm),
					mpIndId=&ind_cd,
					mpYear=&year_nm
				);
			%mend ___load_stat_ind;

			%util_loop_data (mpData=File_list, mpLoopMacro=___load_stat_ind);

			%local lmvAddDttm;
			%let lmvAddDttm=%sysfunc(datetime());
			
			proc sql;
				insert into etl_ctl.registry_load
				select
				  RLOAD_TABNAME,
				  RLOAD_YEAR,
				  RLOAD_STAGE_CD,
				  &lmvAddDttm as RLOAD_PROCESS_DTTM,
				  ETL_PR_ID,
				  &mpIndGroupId as RLOAD_GRP_IND_ID,			  
				  RLOAD_IND_ID
				  from work.registry_load
				  ;
			quit;
		%mend _inner_by_year;
		
		%util_loop_data (mpData=years_list, mpLoopMacro=_inner_by_year);
	%mend _inner_by_inds;
	
	%util_loop_data (mpData=indcd_list, mpLoopMacro=_inner_by_inds);
%mend stg_loop_load_inds;