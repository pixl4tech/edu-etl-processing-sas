/*Запуск загрузки показателей и мэтчинг с postgis координатами*/
/**/
/*%scm_load_ind_to_postgis(*/
/*	mpInLib=WORK_STG,*/
/*	mpIn=IND_8003001,*/
/*	mpOut=postgis.geo_munst_stat*/
/*);*/

%macro scm_load_ind_to_postgis(
mpInLib=WORK_STG,
mpIn=,
mpOut=
);

PROC SQL;
   CREATE TABLE WORK.&mpIn._CLR AS 
   SELECT t1.*, 
          /* lname */
            (lowcase(t1.ENTITY_NM)) AS lname
      FROM &mpInLib..&mpIn t1
      ;
QUIT;

data WORK.&mpIn._CLR;
set WORK.&mpIn._CLR;

llname=strip(lname);
llname=CAT(' ',llname);
llname=tranwrd(llname,'ё','е');

llname=tranwrd(llname,'г.','');
llname=tranwrd(llname,'с.','');
llname=tranwrd(llname,'п.','');
llname=tranwrd(llname,'пгт.','');
llname=tranwrd(llname,'ст.','');
llname=tranwrd(llname,' муниципальные районы','');
llname=tranwrd(llname,' муниципальный район','');
llname=tranwrd(llname,' муниципальный','');
llname=tranwrd(llname,' поселения городского типа','');
llname=tranwrd(llname,' городского','');
llname=tranwrd(llname,' городcкие','');
llname=tranwrd(llname,' сельские','');
llname=tranwrd(llname,' сельское','');
llname=tranwrd(llname,' городское','');
llname=tranwrd(llname,' город','');
llname=tranwrd(llname,' поселок','');
llname=tranwrd(llname,' поселение','');
llname=tranwrd(llname,' район','');
llname=tranwrd(llname,' округ','');
llname=tranwrd(llname,' село','');
llname=tranwrd(llname,' пгт ','');
llname=tranwrd(llname,' гп ','');
llname=tranwrd(llname,' сп ','');
llname=tranwrd(llname,' г ','');
llname=tranwrd(llname,' с ','');
llname=tranwrd(llname,' п ','');


llname=compress(llname,'.,%-"()*:\/');
llname=compress(llname,"'");
llname=strip(llname);


run;



PROC SQL;
   CREATE TABLE WORK.&mpIn._GEO AS 
   SELECT t1.gid, 
          t2.STAT_ID, 
          t2.YEAR, 
          t2.STAT_IND
      FROM WORK_COM.ADM_GEO_CLR t1
           LEFT JOIN WORK.&mpIn._CLR t2 ON (t1.llname = t2.llname) AND (t1.adm4_name = t2.REG_NM)
      WHERE t2.STAT_IND NOT IS MISSING
      GROUP BY t1.gid, t2.YEAR
      HAVING (COUNT(t1.gid)) = 1;
QUIT;

proc append base=&mpOut data=WORK.&mpIn._GEO;
run;

%member_drop(&mpIn._GEO);
%member_drop(&mpIn._CLR);

%put NOTE: Загрузка &mpIn завершена;

%mend scm_load_ind_to_postgis; 

