****************************************************************************************;
* Last Update: 2025/10													               *;
* This SAS code construct Accounting Comparability measure following Chen et al. (2017)*;																			*;
****************************************************************************************;

************************************************************************************
Part 1: Import Compustat quarterly data, CRSP daily data, mna data, and link table
************************************************************************************
In this code, we have compustat quarterly data, CRSP daily data, M&A ata, and 
link table for merging Compustat and CRSP
;

%let comp_quarterly_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\compustat_quarterly_data.csv;
%let crsp_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\crsp_data.csv;
%let out_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results\\mna_media_comparability.csv;
%let out = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results\\;
libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results"; 
libname CKW2 "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data";

proc import datafile="&comp_quarterly_file" dbms=csv out=comp_data replace; run;
data mna_media; set CKW.mna_media_final; run;
data link_table; set CKW2.comp_crsp_00_23; run;
data crsp_data;
	infile "&crsp_file" 
		dsd firstobs=2 lrecl=32767 truncover;
	length permno 8 date 8 permco 8 prc 8 ret_char $10 shrout 8 vwretd 8;
	informat date yymmdd10.;
	format date yymmdd10.;
	input permno date permco prc ret_char shrout vwretd;
	ret = input(ret_char, best32.);
run;

*************************************************************
Part 2: Merge Quarterly Compustat and quarterly return data 
*************************************************************
Since we aim to run regression using earnings as dependent variable
and quarterly return as independent variable, we will merge Compustat
quarterly data and CRSP daily data, first calculating quarterly return 
from CRSP daily data, and then merge the quarterly Compustat and CRSP data 
;

data comp_data; set comp_data; gvkey_char = put(gvkey, z6.); run;
proc sql;
	create table comp_data as 
	select a.*, b.permno from comp_data as a left join link_table as b 
	on a.gvkey_char = b.gvkey and a.fyearq = b.fyear
	order by a.gvkey, a.datadate; *Add PERMNO to the Compustat data;
quit;

proc sort data=comp_data; by permno datadate; run;
proc sort data=crsp_data; by permno date; run;

*The following code block constructs the window for computing quarterly returns based on datadate;
data comp_window;
	set comp_data; 
	by permno datadate;
	retain prev_dt;
	if first.permno then prev_dt = .;
	
	lag_dt = prev_dt;
	if not missing(lag_dt) then q_start = intnx('day', lag_dt, 1, 'same');
	else q_start = .;
	q_end = datadate;

	format q_start q_end yymmdd10.;
	output;
	prev_dt = datadate;
	keep gvkey permno datadate fyear q_start q_end;
run; 

*For each gvkey*datadate, add the actual data in the window;
proc sql;
	create table dly_in_window as 
	select a.*, b.date, b.ret from comp_window as a left join crsp_data as b 
	on a.permno = b.permno and (b.date > a.q_start and b.date <= a.q_end)
	order by a.permno, a.q_end, b.date;
quit; 

data comp_qret;
	set dly_in_window;
	by permno datadate;
	retain prod n_days;
	if first.datadate then do; prod = 1; n_days = 0; end;
	if not missing(ret) then do; prod = prod * (1+ret); n_days + 1; end; 
	if last.datadate then do;
		if n_days >= 58 then q_bhret = prod - 1;
		else q_bhret = .;
		output;
	end;

	keep gvkey permno datadate q_start q_end n_days q_bhret;
run; 

proc sql;
	create table comp_data as 
	select a.*, b.q_bhret, b.n_days 
	from comp_data as a left join comp_qret as b 
	on a.gvkey = b.gvkey and a.datadate = b.datadate
	order by a.gvkey, a.datadate;
quit; 

*************************************************************
Part 3: Find peers for each target firm in our sample (temp) 
*************************************************************
Here, for every dealid, we attach to the target firm the set of firms
in the same industry within the same year
;
data comp_panel;
	set comp_data;
	if not missing(sic) then sic2 = floor(sic/100);
	year = year(datadate);
run;

data comp_panel;
	set comp_panel;
	by gvkey;
	atq_lag = lag(atq);
	cshoq_lag = lag(cshoq);
	prccq_lag = lag(prccq);
	if first.atq then atq_lag = .;
	if first.cshoq then cshoq_lag = .;
	if first.prccq then prccq_lag = .; 
	mve_lag = cshoq_lag * prccq_lag;
	mve = cshoq * prccq; 
	earnings = ibq / mve;
run;

data mna_media;
	set mna_media;
	t_sic_num = input(strip(t_sic), ?? best32.);
	t_sic2 = floor(t_sic_num/100);
run; 

data mna_evts; 
	set mna_media(keep=dealid t_gvkey t_sic2 d_ann); 
	year = year(d_ann);  
run;

proc sql;
	create table peer_pool as 
	select distinct a.dealid, a.t_gvkey, a.t_sic2, a.d_ann, b.gvkey, b.sic2
	from mna_evts as a left join comp_panel as b on a.t_sic2 = b.sic2 and a.year = b.year;
quit; 

*Some targets in mna_media doesn't match themselves, we add them to peer_pool manually;
data peer_pool; set peer_pool; gvkey_char = put(gvkey, z6.); run;
proc sql;
	create table missing_self as
	select a.dealid, a.t_gvkey, a.t_sic2, a.d_ann, b.gvkey, b.sic2, b.gvkey_char from mna_evts as a 
	left join peer_pool as b 
	on a.dealid = b.dealid and a.t_gvkey = b.gvkey_char
	where b.gvkey = . 
	order by a.dealid;
quit; 

data missing_self;
	set missing_self;
	gvkey = input(t_gvkey, best32.);
	sic2 = t_sic2;
	gvkey_char = t_gvkey;
run;

data peer_pool; 
	set peer_pool missing_self; 
	if t_gvkey = gvkey_char then isTarget = 1; else isTarget = 0; 
run;

********************************************
Part 4: Estimate regression for each group 
********************************************;

*For each gvkey and date, add previous quarterly return;
proc sql;
	create table pre_announce as 
	select a.dealid, a.gvkey, a.t_gvkey, a.t_sic2, a.d_ann, a.isTarget, b.datadate, b.earnings, b.q_bhret
	from peer_pool as a inner join comp_panel as b 
	on a.gvkey = b.gvkey and b.datadate < a.d_ann
	order by a.dealid, a.gvkey, b.datadate;
quit; 

proc sort data=pre_announce; by dealid gvkey descending datadate; run;
data pre_announce;
	set pre_announce;
	by dealid gvkey descending datadate;
	retain k;
	if first.gvkey then k = 0;
	k + 1;
run; 

proc sql;
	create table last16 as 
	select dealid, gvkey, t_gvkey, t_sic2, d_ann, isTarget, datadate, earnings, q_bhret
	from pre_announce
	where k <= 16 
	order by dealid, gvkey, datadate;
quit;

proc sql;
  create table last16_filt as
  select *
  from last16
  where not missing(earnings) and not missing(q_bhret)
  group by dealid, gvkey
  having count(*) >= 14
  order by dealid, gvkey, datadate;
quit;

proc reg data=last16_filt noprint outest = coef_raw; 
	by dealid gvkey;
	model earnings = q_bhret; 
quit;

proc sql;
	create table last16_with_coef as 
	select a.*, b.Intercept as alpha, b.q_bhret as beta
	from last16_filt as a left join coef_raw as b 
	on a.dealid = b.dealid and a.gvkey = b.gvkey
	order by a.dealid, a.gvkey, a.datadate;
quit;

********************************************************************
Part 5: Calculate expected earnings and accounting conparability 
********************************************************************
Here, we want to add quarterly return of targets to last16_with_coef
in order to calculate expected earnings accounting comparability
;

*last16_with_coef left join target quarter return;
data target_qret;
	set last16_with_coef;
	if isTarget = 1;
run;

proc sql;
	create table last16_with_coef as 
	select a.*, b.q_bhret as t_return from last16_with_coef as a 
	left join target_qret as b on a.t_gvkey = b.t_gvkey and a.datadate = b.datadate;
run; 

*Calculate expected earnings;
data last16_with_coef;
	set last16_with_coef;
	exp_earnings = alpha + beta * t_return;
run;

*Calculate accounting comparability;
data target_earnings;
	set last16_with_coef;
	if isTarget = 1;
run;

proc sql;
	create table last16_with_coef as 
	select a.*, b.exp_earnings as t_earnings from 
	last16_with_coef as a left join target_earnings as b 
	on a.t_gvkey = b.t_gvkey and a.datadate = b.datadate;
quit; 

data last16_with_coef;
	set last16_with_coef;
	earn_diff = abs(exp_earnings - t_earnings);
	if isTarget = 0; 
run;

proc sql;
	create table CompAcct as 
	select dealid, gvkey, mean(earn_diff) as comp_acct
	from last16_with_coef group by dealid, gvkey;
quit; 

proc sql;
	create table comparability as 
	select dealid, mean(comp_acct) as compare 
	from CompAcct group by dealid;
run;

********************************************************************
Part 6: Merge comparability measire back to M&A data 
********************************************************************; 

proc sql;
	create table mna_media_comparability as 
	select a.*, b.compare from 
	mna_media as a left join comparability as b 
	on a.dealid = b.dealid; 
run;

data mna_media_comparability;
	set mna_media_comparability;
	compare = -1 * compare;
	c_compare = Closure * compare;
	cm_compare = Closure_Merge * compare;
run; 

proc sort data=mna_media_comparability; by y_ann_num; run;
proc rank data=mna_media_comparability out=mna_media_comparability ties=mean groups=100;
	by y_ann_num; 
	var compare;
	ranks compare_pct;
run; 

*****************************************
Part7 : Export mna_media_comparability
*****************************************; 

libname outlib "&out";
data outlib.mna_media_comparability; set mna_media_comparability; run; 
proc export data=outlib.mna_media_comparability outfile="&out_file" dbms=csv replace; putnames=yes; run;
libname outlib clear;
libname CKW clear; 
libname CKW2 clear;	
