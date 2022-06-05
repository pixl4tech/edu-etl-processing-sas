%macro scm_delete_ind(
	mpGrpIndId=
);

proc sql;
create table work.del_ind as
select ind_id
from postgis.stat_categories
where ind_group_id=&mpGrpIndId
;
quit;

	%macro ___del_stat_ind;
		proc sql;
		   delete from postgis.stat_categories
		   where ind_id="&ind_id";
		quit;

		proc sql;
		   delete from postgis.stat_ind_x_reg
		   where ind_id="&ind_id";
		quit;

		proc sql;
		   delete from postgis.stat_munst_full
		   where ind_id="&ind_id";
		quit;

		proc sql;
		   delete from postgis.stat_munst_geo
		   where ind_id="&ind_id";
		quit;
	%mend ___del_stat_ind;

	%util_loop_data (mpData=work.del_ind, mpLoopMacro=___del_stat_ind);


%mend scm_delete_ind;