%macro etl_init_load_id(
mpFolder=
);
	%local lmvInsLoadId;
	proc sql noprint;
	SELECT (coalesce(max(ETL_PR_ID),0)+1) as max into :lmvInsLoadId
		FROM etl_ctl.etl_process
	;
	quit;
	%local lmvAddDttm;
	%let lmvAddDttm=%sysfunc(datetime());
	proc sql ;
	insert into etl_ctl.etl_process
	VALUES (&lmvInsLoadId,"&mpFolder","C", &lmvAddDttm, .)
	;
	quit;
	
	%let ETL_PROCESS_ID=&lmvInsLoadId;

%mend etl_init_load_id;