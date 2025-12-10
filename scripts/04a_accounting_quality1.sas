*****************************************************************************;
* Last Update: 2025/11													    *;
* This SAS code calculate constrcut Accounting Quality as control variable, *;
* following McNichols (2002)                                                *; 	
*****************************************************************************;

***********************************************************************************;
* This program constructs accounting quality (AQ) following McNichols (2002).     *;
* We compute scaled working capital accruals (£GWC) and regress them on scaled     *;
* CFO_{t-1}, CFO_{t}, CFO_{t+1}, £GSales_{t}, and PPE_{t} within each two digit    *;
* SIC by fiscal year group (min 15 obs per group, robust regression). The         *;
* residuals represent firm specific accrual errors. AQ is the negative rolloing   *;
* five year standard deviation of these residuals (at least four valid years      *;
* required), so higher AQ implies better quality. AQ is then converted to yearly  *;
* percentiles and merged to the M&A sample as a lagged control using target gvkey *;
* and announcement year.                                                          *;
***********************************************************************************;

******************************************************
Part 1 - Import compustat data & mna_media_ccar
******************************************************;

data mna_media_ccar; 
	set PROC.mna_media_ccar; 
run;

proc import datafile="&data.\aq_compustat_data2.csv"
	dbms=csv 
	out=comp_data 
	replace; 
	guessingrows=1000; 
	getnames=yes; 
run;
 
data comp_data; 
	set comp_data; 
	if indfmt = 'INDL'; 
run;

****************************************************************************
Part 2 - Construct dependent and independent variable for group regression
****************************************************************************;

proc sort data=comp_data; 
	by gvkey fyear; 
run;

*Follow McNichols (2002);
*Regression morel: £GWC = CFO_{t-1} + CFO_{t} + CFO_{t+1} + £GSales_{t} + PPE_{t};
data comp_data;
	set comp_data;
	by gvkey fyear;
 
	* d_wc_raw = -(recch + invch + apalch + txach + aoloch);
	at_lag = lag(at);
	if first.gvkey then at_lag = .;

	miss5 = (cmiss(of recch invch apalch txach aoloch) = 5);
	d_wc_raw = -sum(recch, invch, apalch, txach, aoloch);
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
	d_sale = d_sale_raw / at_lag; 

	ppe = ppegt / at_lag; 
run;

proc sort data=comp_data out=comp_sorted; 
	by gvkey descending fyear; 
run;

data comp_data; 
	set comp_sorted; 
	by gvkey; cfo_lead = lag(oancf); 
	if first.gvkey then cfo_lead = .; 
run;

proc sort data=comp_data; 
	by gvkey fyear; 
run;

**************************************
Part 3 - Estimate regression by group
**************************************;

*we run regression in sic2*fyear group 
*construct 2-code sic;
data comp_data; 
	set comp_data; 
	if 0 <= sich <= 9999 then sic2 = floor(sich/100); 
	else sic2 = .; 
run;

proc freq data=comp_data noprint; tables sic2*fyear / out=ind_year_counts; 
run; 

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
proc sort data=reg_input; 
	by sic2 fyear; 
run;

proc robustreg data=reg_input method=M plots=none; 
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
Part 4 - Calculating accounting quality measure
************************************************;

proc sort data=comp_data; 
	by gvkey fyear datadate; 
run;
 
data comp_data; 
	set comp_data; 
	by gvkey fyear datadate; 
	if last.fyear; 
run; 

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
	if cnt_resid_5y >=4 then aq = -sd_resid_5y;
	else aq = .;
run;

proc sort data=comp_data; 
	by fyear; 
run;

proc rank data=comp_data groups=100 out=comp_data ties=mean;
	by fyear;
	var aq;
	ranks aq_pctl;
run; 
 
*************************************
Part 5 - Merge back to main dataset
*************************************;

data comp_data; 
	set comp_data; 
	gvkey_char = put(gvkey, z6.); 
run;

proc sql;
	create table mna_media_aq as 
	select a.*, b.aq_pctl as aq_lag1
	from mna_media_ccar as a 
	left join comp_data as b 
	on a.t_gvkey = b.gvkey_char and b.fyear = a.y_ann_num - 1;
quit; 

data mna_media_aq;
	set mna_media_aq;
	if missing(combined_car3) then delete;
	if missing(combined_car5) then delete;
	if missing(aq_lag1) then delete; 
run;

*************************************
Part 6 - Export final dataset
*************************************;

data PROC.mna_media_aq; 
	set mna_media_aq; 
run; 