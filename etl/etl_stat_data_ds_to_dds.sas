%macro etl_stat_data_ds_to_dds(
mpFolderDs=
);

	/* Инициализируем новый процесс ETL */
	%etl_init_load_id(
		mpFolder=&mpFolderDs
	);

	/* Запуск этапа STG */
	%stg_load_all_inds(
		mpPath=&mpFolderDs
	);
	
	/* Запуск этапа IA */
	%scm_load_all_to_postgis(
		mpLoadId=&ETL_PROCESS_ID
	);
	
	/* Завершение процесса ETL */
	%etl_upd_status_process(
	mpLoadId=&ETL_PROCESS_ID,
	mpStatusCd=L
	);

%mend etl_stat_data_ds_to_dds;