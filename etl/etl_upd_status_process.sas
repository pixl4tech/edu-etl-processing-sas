%macro etl_upd_status_process(
mpLoadId=,
mpStatusCd=
);
	%local lmvFinDttm;
	%let lmvFinDttm=%sysfunc(datetime());

	proc sql ;
	update etl_ctl.etl_process
	SET ETL_PR_STATUS_CD="&mpStatusCd", ETL_PR_FINISH_DTTM=&lmvFinDttm
	where ETL_PR_ID=&mpLoadId
	;
	quit;

%mend etl_upd_status_process;