%macro scm_gen_color_filter(
mpGrpIndId=
);


PROC SQL;
   CREATE TABLE WORK.STAT_GEO_CR AS 
   SELECT t1.ind_gr_id, 
          t1.ind_id, 
          t3.year, 
          t3.ind_value
      FROM POSTGIS.WEB_GROUPS_X_STAT_CAT t1, POSTGIS.STAT_CATEGORIES t2, POSTGIS.STAT_MUNST_GEO t3
      WHERE (t1.ind_id = t2.ind_id AND t1.ind_id = t3.ind_id) AND (t1.ind_gr_id = &mpGrpIndId AND t1.ind_map_flg = 'Y');
QUIT;


PROC SQL noprint;
   SELECT DISTINCT t1.ind_id into :lmvIndId
      FROM POSTGIS.WEB_GROUPS_X_STAT_CAT t1, POSTGIS.STAT_CATEGORIES t2, POSTGIS.STAT_MUNST_GEO t3
      WHERE (t1.ind_id = t2.ind_id AND t1.ind_id = t3.ind_id) AND (t1.ind_gr_id = &mpGrpIndId AND t1.ind_map_flg = 'Y');
QUIT;


proc means data=STAT_GEO_CR(keep=ind_value) median min max;
output out=filterstat(keep=median_val max_val min_val) median=median_val max=max_val min=min_val;
run;

data color;
set filterstat;
i=1;
d=1;
clr=.;
output;
   do while(i<11 and clr <= max_val);
   	  if median_val >= 2 then do;
	  	clr = round((median_val/(32/d)),1);
	  end;
	  else do;
		clr = median_val/(32/d);
	  end;
	  d = d*2;
      i+1;
	  output;
   end;

run;

PROC SQL noprint;
   SELECT 
            (COUNT(DISTINCT(t1.clr_gr_id))) AS count_clr into : lmvCntClr
      FROM POSTGIS.STAT_COLOR_GROUPS t1;
QUIT;

%let lmvClrId = %random(1, &lmvCntClr);
%put &=lmvClrId;
PROC SQL;
   CREATE TABLE WORK.ADD_STAT_COLOR AS 
   SELECT t2.clr_cond, 
          t1.clr AS clr_cond_val, 
          t2.clr_hex_cd, 
          t2.clr_priority
      FROM WORK.COLOR t1
           INNER JOIN POSTGIS.STAT_COLOR_GROUPS t2 ON (t1.i = t2.clr_priority AND (t2.clr_gr_id = &lmvClrId))
      ORDER BY t2.clr_priority DESC;
QUIT;

	proc sql;
		insert into postgis.web_ind_color
			select "&lmvIndId" as ind_id, 
					&mpGrpIndId as ind_gr_id, 
					clr_cond,
					clr_cond_val,
					clr_hex_cd,
					clr_priority
			from WORK.ADD_STAT_COLOR
		;
	quit;

%mend scm_gen_color_filter;