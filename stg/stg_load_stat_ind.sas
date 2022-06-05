/* Импортирует файл показателя из файла и загружает в стейджинг-таблицу */

%macro stg_load_stat_ind(
	mpFilePath=,
	mpFileName=,
	mpFormat=%str(best12.),
	mpIndId=,
	mpYear=
);

%local lmvRegNm;
%let lmvRegNm =%sysfunc(scan(&mpFileName, 1,_));

filename 
foo "&mpFilePath.&mpFileName" 
encoding="windows-1251" 
lrecl=30000;

proc import datafile=foo 
out=buf_data dbms=csv replace; 
getnames=no;
delimiter=';';
datarow=1;
guessingrows=200000;
run;


%let dsvars = %member_vars (mpIn=buf_data,mpDrop=VAR1);
%if ^%is_blank(dsvars) %then %do;
	%let dsvars_a=%sysfunc(tranwrd(&dsvars,VAR,AVAR));

	     %macro inner (mpField);
	        A&mpField = input(tranwrd(&mpField,',','.'),&mpFormat);
	     %mend inner;
	    
	data buf_data;
	set buf_data;
	format &dsvars_a Best12. ;

	%util_loop (mpMacroName=inner, mpWith=&dsvars);

	STAT_IND = MAX(of _numeric_);
	V1FLG=ifn(missing(VAR1),1,0);
	keep VAR1 STAT_IND V1FLG;
	run;

	%let lmvStatNm=;
	data buf_data_add;
	length ENTITY_NM $ 400 STAT_IND 8 STAT_NM $ 800 STAT_ID $ 32 REG_NM $ 300 YEAR 8; 
	format ENTITY_NM $400. STAT_IND Best12. STAT_NM $800. STAT_ID $32. REG_NM $300. YEAR 8.;
	drop V1FLG;
	set buf_data(rename=(VAR1=ENTITY_NM));
	if NOT(missing(ENTITY_NM)) and missing(STAT_IND) and missing(lag(STAT_IND)) and lag(V1FLG)=1 then do; 
		call symput('lmvStatNm',ENTITY_NM);
	end;
	else if NOT(missing(STAT_IND)) and NOT(missing(ENTITY_NM)) then do;
		STAT_NM=symget('lmvStatNm');
		STAT_ID="&mpIndId";
		REG_NM="&lmvRegNm";
		YEAR=&mpYear;
		output;
	end;
	run;


        data I&mpIndId;
			set buf_data_add;
			where STAT_ID="&mpIndId";
		run;
		%if %member_obs (mpData=work.I&mpIndId)> 0 %then %do;
			%if ^%member_exists (WORK_STG.I&mpIndId.) %then %do;
				data WORK_STG.I&mpIndId.;
					set WORK_COM.DATA_OBS_D;
					if 1=0 then output;
				run;
			%end;

			proc append base=WORK_STG.I&mpIndId. data=I&mpIndId;
			run;
		%end;
		%member_drop(work.I&mpIndId);
    
	
	data work.registry_load;
	length RLOAD_TABNAME $ 120 RLOAD_IND_ID $ 96 RLOAD_YEAR $ 18 RLOAD_STAGE_CD $ 18  ETL_PR_ID 8;
		RLOAD_TABNAME=strip(cat('WORK_STG.I',"&mpIndId"));
		RLOAD_IND_ID="&mpIndId";
		RLOAD_YEAR="&mpYear";
		RLOAD_STAGE_CD='STG';
		ETL_PR_ID=&ETL_PROCESS_ID;
	run;
		

%end;

%mend stg_load_stat_ind;