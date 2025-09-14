*****************************************************************************;
* Last Update: 2025/9													    *;
* This SAS code calculate constrcut accounting quality as control variable, *;
* following Ahmed 2022                                                      *; 	
*****************************************************************************;

******************************************************
Part1 - Import compustat data & mna_media_comp_crsp
******************************************************;

libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results"; 
data mna_media_ccar;
	set CKW.mna_media_ccar;
run;

proc import datafile="C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\aq_compustat_data.csv" 
	dbms=csv 
	out=comp_data
	replace;
run; 

****************************************************************************
Part2 - Construct dependent and independent variable for group regression
****************************************************************************;

proc sort data=comp_data;
	by gvkey fyear;
run; 

data comp_data;
  set comp_data;
  by gvkey;

  lagged_at   = lag(at);   
  lagged_sale = lag(sale);   
  lagged_rect   = lag(rect);  

  if first.gvkey then call missing(lagged_at, lagged_sale, lagged_rect);
run;

data comp_data;
	set comp_data;
	accrual = ib - oancf;
	delta_sale = sale - lagged_sale;
	delta_rect = rect - lagged_rect; 
	y = accrual / lagged_at;
	x1 = 1 / lagged_at;
	x2 = delta_sale / lagged_at;
	x3 = ppegt / lagged_at;
run;
	
**************************************
Part3 - Estimate regression by group
**************************************;

*construct 2-code sic;
data comp_data;
	set comp_data;
	if 0 <= sich <= 9999 then sic2 = floor(sich/100);
	else sic2 = .;
run;

proc freq data=comp_data noprint;
	tables sic2*fyear / out=ind_year_counts;
run; 

data reg_base;
	set comp_data;
	if sic2 ne . and fyear ne .; 
	if nmiss(y, x1, x2, x3) = 0;
run; 

*see homay observations are in each group;
*we will run regression only in group where observations>=15;
proc sql;
	create table grp_n as 
	select sic2, fyear, count(*) as nfirms from reg_base 
	group by sic2, fyear;
quit; 

proc sql;
	create table reg_input as 
	select a.*, b.nfirms from reg_base as a 
	inner join grp_n as b on a.sic2 = b.sic2 and a.fyear = b.fyear
	where b.nfirms >= 15;
quit; 

*run regression in each sic2*year group;
proc sort data=reg_input; by sic2 fyear; run;
proc reg data=reg_input noprint outest=coef_raw;
	by sic2 fyear;
	model y = x1 x2 x3; 
quit; 

**************************
Part4 - Calculate DiscACC
**************************;

proc sql;
	create table coef_table as 
	select r.sic2, r.fyear, n.nfirms, r.Intercept, r.x1, r.x2, r.x3
	from coef_raw as r inner join grp_n as n 
	on r.sic2 = n.sic2 and r.fyear=n.fyear
	where r._TYPE_='PARMS';
quit; 

data coef_table;
	set coef_table;
	rename Intercept=b0 x1=b1 x2=b2 x3=b3;
run; 

proc sql;
	create table comp_with_coef as 
	select a.*, b.b0, b.b1, b.b2, b.b3
	from comp_data as a left join coef_table as b
	on a.sic2=b.sic2 and a.fyear=b.fyear;
quit; 

data comp_with_coef;
	set comp_with_coef;
	na = b0 + b1 * x1 + b2 * (delta_sale - delta_rect) / lagged_at + b3 * x3;
	DiscACC = accrual / lagged_at - na; 
run;

*************************************
Part5 - Merge back to main dataset
*************************************;

data comp_with_coef;
	set comp_with_coef;
	gvkey_char = put(gvkey, z6.); 
run;

proc sql;
	create table mna_media_final as 
	select a.*, b.DiscACC as DiscACC_lag1 
	from mna_media_ccar as a 
	left join comp_with_coef as b 
	on a.t_gvkey = b.gvkey_char and a.y_ann_num - 1 = b.fyear;
quit; 

data mna_media_final;
	set mna_media_final;
	if missing(combined_car3) then delete;
	if missing(combined_car5) then delete;
	if missing(DiscACC_lag1) then delete;
run;

*************************************
Part6 - Export final dataset
*************************************;

*libname outlib "C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\results\";

data outlib.mna_media_final;
    set mna_media_final; 
run; 

