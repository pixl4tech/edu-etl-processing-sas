
/*
%stg_load_all_inds(
	mpPath=\\PUSHSERV\ServerFiles\LOAD_PMO\CSV\
);
*/

%macro stg_load_all_inds(
mpPath=
);
	 %folder_list(mpInFolderName="&mpPath", mpOut=grpInd_list(RENAME=(file_nm=grp_ind_cd)));
	 %macro ___imp_sfiles_loop;
		%let lmvFilePath=%TRIM(%sysfunc(CAT(&mpPath,&grp_ind_cd,\)));
		%stg_loop_load_inds(
			mpFilePath=&lmvFilePath,
			mpIndGroupId=&grp_ind_cd
		);
	%mend ___imp_sfiles_loop;

	%util_loop_data (mpData=grpInd_list, mpLoopMacro=___imp_sfiles_loop);

%mend stg_load_all_inds;


