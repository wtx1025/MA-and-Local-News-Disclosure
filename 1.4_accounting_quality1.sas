*****************************************************************************;
* Last Update: 2025/9													    *;
* This SAS code calculate constrcut accrual quality as control variable,    *;
* following Ahmed 2023                                                      *; 	
*****************************************************************************;

******************************************************
Part1 - Import compustat data & mna_media_ccar
******************************************************;

libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results"; 
%let ac_compustat_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\aq_compustat_data2.csv;
%let out = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results\\;

data mna_media_ccar; set CKW.mna_media_ccar; run;

proc import datafile="&ac_compustat_file" dbms=csv out=comp_data replace; guessingrows=1000; getnames=yes; run; 
data comp_data; set comp_data; if indfmt = 'INDL'; run;

****************************************************************************
Part2 - Construct dependent and independent variable for group regression
****************************************************************************;

proc sort data=comp_data; by gvkey fyear; run;
data comp_data;
	set comp_data;
	by gvkey fyear;
 
	d_wc_raw = -(recch + invch + apalch + txach + aoloch);
	at_lag = lag(at);
	if first.gvkey then at_lag = .;

	miss5 = (cmiss(of recch invch apalch txach aoloch) = 5);
	d_wc_raw = -sum(recch, invch, apalch, txach) + sum(aoloch);
	if at_lag > 0 then do;
        if miss5 then d_wc = 0;
        else d_wc = d_wc_raw / at_lag;
    end;
    else d_wc = .;

	cfo_lag = lag(oancf); *CFO_{t-1};
	cfo = oancf; *CFO_{t};
	if first.gvkey then cfo_lag = .;

	sale_lag = lag(sale); 
	if first.gvkey then sale_lag = .;
	d_sale_raw = sale - sale_lag; 
	d_sale = d_sale_raw / at_lag; *deflated by beginning total assets;

	ppe = ppegt / at_lag; *deflated by beginning total assets; 
run;

proc sort data=comp_data out=comp_sorted; by gvkey descending fyear; run;

data comp_data; set comp_sorted; by gvkey; cfo_lead = lag(oancf); if first.gvkey then cfo_lead = .; run;
proc sort data=comp_data; by gvkey fyear; run;

**************************************
Part3 - Estimate regression by group
**************************************;

*construct 2-code sic;
data comp_data; set comp_data; if 0 <= sich <= 9999 then sic2 = floor(sich/100); else sic2 = .; run;
proc freq data=comp_data noprint; tables sic2*fyear / out=ind_year_counts; run; 

data reg_base;
	set comp_data;
	if sic2 ne . and fyear ne .; 
	if nmiss(d_wc, cfo_lag, cfo, cfo_lead, d_sale, ppe) = 0;
run; 

*see how mmay observations are in each group;
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
proc reg data=reg_input noprint 
	outest=coef_raw; 
	by sic2 fyear; 
	model d_wc = cfo_lag cfo cfo_lead d_sale ppe; 
	output out=resids residual=resid;
quit; 

proc sql;
    create table comp_data as
    select a.*, b.resid from comp_data as a
    left join resids as b
    on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

************************************************
Part4 - Calculating accounting quality measure
************************************************;

proc sort data=comp_data; by gvkey fyear datadate; run; 
data comp_data; set comp_data; by gvkey fyear datadate; if last.fyear; run; 

data comp_data;
	set comp_data;
	resid_miss = 0;
	if resid ne . then resid_miss = 1;
run;

proc expand data=comp_data out=comp_data method=none;
	by gvkey;
	id fyear;
    convert resid = sd_resid_5y / transformout = (movstd 5);
	convert resid_miss = cnt_resid_5y / transformout = (movsum 5);
run;

data comp_data;
	set comp_data;
	if cnt_resid_5y >=3 then aq = -sd_resid_5y;
	else aq = .;
run;

proc sort data=comp_data; by fyear; run; 
proc rank data=comp_data groups=100 out=comp_data ties=mean;
	by fyear;
	var aq;
	ranks aq_pctl;
run; 

*************************************
Part5 - Merge back to main dataset
*************************************;

data comp_data; set comp_data; gvkey_char = put(gvkey, z6.); run;
proc sql;
	create table mna_media_aq as 
	select a.*, b.aq_pctl as aq_lag1
	from mna_media_ccar as a 
	left join comp_data as b 
	on a.t_gvkey = b.gvkey_char and a.y_ann_num - 1 = b.fyear;
quit; 

data mna_media_aq;
	set mna_media_aq;
	if missing(combined_car3) then delete;
	if missing(combined_car5) then delete;
	if missing(aq_lag1) then delete;
run;

*************************************
Part6 - Export final dataset
*************************************;

libname outlib "&out";
data outlib.mna_media_aq; set mna_media_aq; run; 
libname outlib clear;
libname CKW clear; 