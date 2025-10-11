**********************************************************************;
* Last Update: 2025/10											     *;
* This SAS code construct conservatism measure following KW(2009)    *;																			*;
**********************************************************************;

*********************
Part1 : Import data
*********************;

%let comp_data_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\conservatism_compustat_data.csv;
%let crsp_data_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\crsp_monthly_data.csv;
%let out_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results\\mna_media_conservatism.csv;
%let out = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results\\;
libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results"; 
libname CKW2 "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data";

proc import datafile="&comp_data_file" dbms=csv out=comp_data replace; guessingrows=32767; getnames=yes; run;
proc import datafile="&crsp_data_file" dbms=csv out=crsp_data replace; guessingrows=32767; getnames=yes; run;
data mna_media; set CKW.mna_media_conservatism1; run;
data link_table; set CKW2.comp_crsp_00_23; run;

***************************************************
Part2 : Add permno to comp_data using link table 
***************************************************;

data comp_data; set comp_data; gvkey_char = put(gvkey, z6.); run;
proc sql;
	create table comp_data as 
	select a.*, b.permno from comp_data as a left join link_table as b 
	on a.gvkey_char = b.gvkey and a.datadate = b.datadate
	order by a.gvkey, a.datadate;
quit;

proc sort data=comp_data; by gvkey datadate; run; 
data comp_data;
	set comp_data;
	size = log(at);
	mtb = (csho * prcc_f) / ceq;
	leverage = (dltt + lct) / at;
	mve = csho * prcc_f;
	mve_lag = lag(mve);
	if first.gvkey then mve_lag = .;
	earnings = ib / mve_lag; 
	keep gvkey datadate fyear earnings size mtb leverage permno;
run;

**********************************************************
Part3 : Construct 12 months return after fiscal year end 
**********************************************************;

data events;
	set comp_data;
	start_m = intnx('month', datadate, 4, 'B');
	end_m = intnx('month', datadate, 15, 'E');
run;

proc sql;
	create table event_ret as 
	select e.*, c.date format yymmdd10., c.ret, c.prc
	from events as e left join crsp_data as c 
	on e.permno = c.permno and c.date between e.start_m and e.end_m;
quit;

proc sort data=event_ret out=event_ret_sorted; by gvkey datadate date; run;

data cumret_12m;
	set event_ret_sorted;
	by gvkey datadate;

	retain prod n nmiss;
	if first.datadate then do; prod = 1; n = 0; nmiss = 0; end;
	n + 1;
	if missing(ret) then nmiss + 1;
	else prod = prod * (1 + ret);

	if last.datadate then do;
		if n = 12 and nmiss = 0 then cumret12 = prod - 1;
		else cumret12 = .;
		output;
	end;
run;

****************************************
Part4 : Estmate regression in group 
****************************************;

data cumret_12m;
	set cumret_12m;
	if cumret12 < 0 then D = 1; else D = 0;
	R_size = cumret12 * size;
	R_mtb = cumret12 * mtb;
	R_lev = cumret12 * leverage;
	D_R = D * cumret12;
	D_R_size = D * cumret12 * size;
	D_R_mtb = D * cumret12 * mtb;
	D_R_lev = D * cumret12 * leverage;
	D_size = D * size;
	D_mtb = D * mtb;
	D_lev = D * leverage; 
run;

data reg_data;
	set cumret_12m;
	if nmiss(of earnings, D, cumret12, size, mtb, leverage) > 0 then delete;
run;

proc sort data=reg_data; by fyear; run;
proc reg data=reg_data noprint outest = coef_raw; 
	by fyear;
	model earnings = D cumret12 R_size R_mtb R_lev D_R D_R_size D_R_mtb D_R_lev 
	                 size mtb leverage D_size D_mtb D_lev;
quit;

***************************
Part5 : Calculate C-Score 
***************************;

proc sql;
	create table cumret_12m_lambda as 
	select a.*, b.D_R as lambda1, b.D_R_size as lambda2, b.D_R_mtb as lambda3, b.D_R_lev as lambda4
	from cumret_12m as a left join coef_raw as b 
	on a.fyear = b.fyear 
	order by a.gvkey, a.datadate;
quit; 

data cumret_12m_lambda;
	set cumret_12m_lambda;
	cscore = lambda1 + lambda2 * size + lambda3 * mtb + lambda4 * leverage;
run;

proc sort data=cumret_12m_lambda; by fyear; run;
proc rank data=cumret_12m_lambda out=cumret_12m_lambda ties=mean groups=100;
	by fyear;
	var cscore;
	ranks cscore_pct;
run; 

*******************************************************************
Part6 : Merge cumret_12m_lambda back to mna_media_conservatism1 
*******************************************************************;

data cumret_12m_lambda; set cumret_12m_lambda; gvkey_char = put(gvkey, z6.); run;
proc sql;
	create table mna_media_conservatism2 as 
	select a.*, b.cscore_pct from
	mna_media as a left join cumret_12m_lambda as b
	on a.t_gvkey = b.gvkey_char and a.y_ann_num - 1 = b.fyear; 
quit; 

data mna_media_conservatism2;
	set mna_media_conservatism2;
	conservatism = (Skewdiff_pct + Sumacc_pct + AvgSI_pct + cscore_pct) / 4;
	c_conservatism = Closure * conservatism;
	cm_conservatism = Closure_Merge * conservatism; 
run;

*****************************************
Part7 : Export mna_media_conservatism1 
*****************************************;

libname outlib "&out";
data outlib.mna_media_conservatism2; set mna_media_conservatism2; run; 
proc export data=outlib.mna_media_conservatism2 outfile="&out_file" dbms=csv replace; putnames=yes; run;
libname outlib clear;
libname CKW clear; 
libname CKW2 clear;