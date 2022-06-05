%macro scm_load_all_to_postgis(
mpLoadId=
);

	PROC SQL;
	   CREATE TABLE WORK.LOAD_TABLES AS 
	   SELECT DISTINCT t1.RLOAD_TABNAME, 
	          t1.RLOAD_IND_ID, 
	          t1.RLOAD_GRP_IND_ID
	      FROM ETL_CTL.REGISTRY_LOAD t1
	      WHERE t1.ETL_PR_ID = &mpLoadId AND t1.RLOAD_STAGE_CD = 'STG';
	QUIT;

	%macro loop_load_all_to_postgis;
		/*Проверка наличия показателя в базе*/
		%local lmvExistFlg;
			PROC SQL noprint;
			   SELECT
			      (COUNT(t1.ind_id)) AS COUNT_of_ind_id into :lmvExistFlg
			      FROM POSTGIS.STAT_CATEGORIES t1
			      WHERE t1.ind_id = "&RLOAD_IND_ID";
			QUIT;
		%put &=lmvExistFlg;
		/* Если нет, то добавляем*/
		%if &lmvExistFlg=0 %then %do;
			data insert_cat_ind;
			set &RLOAD_TABNAME(OBS=1);
				ind_id = STAT_ID;
				ind_name = STAT_NM;
				geo_flg = 'Y';
				keep ind_id ind_name geo_flg;
			run;

			proc sql;
			insert into postgis.stat_categories
				select ind_name, geo_flg, &RLOAD_GRP_IND_ID, ind_id
				from insert_cat_ind
			;
			quit;
		%end;

		PROC SQL;
		   CREATE TABLE WORK.STAT_MUNST_FULL AS 
		   SELECT strip(t2.oktmo_cd) as oktmo_cd LENGTH=48, 
		          strip(t1.ENTITY_NM) AS name LENGTH=1024, 
		          t1.STAT_IND AS ind_value, 
		          t3.reg_id, 
		          t1.YEAR AS year,
				  t1.STAT_ID AS ind_id LENGTH=96
		      FROM &RLOAD_TABNAME t1
		           LEFT JOIN POSTGIS.GKS_OKTMO t2 ON (t1.ENTITY_NM = t2.oktmo_name) AND (t1.REG_NM = t2.oktmo_reg) AND 
		          (t2.ind_cd = &RLOAD_GRP_IND_ID)
		           LEFT JOIN POSTGIS.STAT_REGION t3 ON (t1.REG_NM = t3.reg_name)
		      ORDER BY t1.YEAR,
		               t1.REG_NM,
		               t1.ENTITY_NM;
		QUIT;

		proc append base=postgis.stat_munst_full data=WORK.STAT_MUNST_FULL;
		run;

		PROC SQL;
		   CREATE TABLE work.stat_ind_x_reg AS 
		   SELECT DISTINCT t1.reg_id, 
		          t1.year,
				  t1.ind_id
		      FROM WORK.STAT_MUNST_FULL t1
		      ORDER BY t1.year DESC,
		               t1.reg_id;
		QUIT;
			
		proc append base=postgis.stat_ind_x_reg data=work.stat_ind_x_reg;
		run;

		PROC SQL;
		   CREATE TABLE WORK.STAT_MUNST_FULL1 AS 
		   SELECT /* oktmo_cd */
		            (ifc(length(t1.oktmo_cd)=7,CAT('0',strip(t1.oktmo_cd)),t1.oktmo_cd)) AS oktmo_cd, 
		          t1.name, 
		          t1.ind_value, 
		          t1.reg_id, 
		          t1.year,
				  t1.ind_id
		      FROM WORK.STAT_MUNST_FULL t1;
		QUIT;

		PROC SQL;
		   CREATE TABLE WORK.STAT_MUNST_GEO AS 
		   SELECT DISTINCT t2.gid,  
		          t1.year, 
		          t1.ind_value,
				  t1.ind_id
		      FROM WORK.STAT_MUNST_FULL1 t1
		           INNER JOIN WORK_COM.TEST_GIS1 t2 ON (t1.oktmo_cd = t2.oktmo_code);
		QUIT;

		proc append base=postgis.STAT_MUNST_GEO data=WORK.STAT_MUNST_GEO;
		run;

		%local lmvAddDttm;
		%let lmvAddDttm=%sysfunc(datetime());
		/* insert to rload (dds) */
		proc sql;
		    insert into etl_ctl.registry_load
			values( 
			"&RLOAD_TABNAME",
			"ALL","DDS",
			&lmvAddDttm,
			&mpLoadId,
			&RLOAD_GRP_IND_ID,
			"&RLOAD_IND_ID"
			);
		quit;

		%member_drop(WORK.STAT_MUNST_FULL);
		%member_drop(WORK.STAT_MUNST_FULL1);
		%member_drop(WORK.STAT_MUNST_GEO);
		%member_drop(work.stat_ind_x_reg);
	%mend loop_load_all_to_postgis;

	%util_loop_data (mpData=WORK.LOAD_TABLES, mpLoopMacro=loop_load_all_to_postgis);


%mend scm_load_all_to_postgis;

