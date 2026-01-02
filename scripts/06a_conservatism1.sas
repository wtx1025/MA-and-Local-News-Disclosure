*****************************************************************************;
* Last Update: 2025/11													    *;
* This SAS code calculate constrcut Conservatism as firm characteristics    *;
* following Ahmed et al. (2023)                                             *; 	
*****************************************************************************;

**************************************************************************************************; 
* This script constructs three non-market-based target accounting conservatism measures          *;
* following Ahmed et al. (2023, CAR) and merge them to the M&A sample. Measures built:           *;
*	(1) Skewdiff:																				 *;
*	    = - (skewness of earnings - skewness of operating casj flows),						     *;
*		where both earnings (IB) and cash flows (OANCF) are deflated by beginning total assets.  *;
*		Skewness is computed using a 5-year rolling window, requiring at least 4 valid annual    *;
*		observations. Ahmed et al. follow Givoly & Hayn (2000).									 *;
*	(2) Sumacc:																					 *;
*		= - (sum of accruals over the past 5 years),											 *;
*		where annual accruals = IB - OANCF + DP, deflated by beginning total assets.             *;
*		The rolling sum requires 5 valid annual observations.									 *;
*	(3) AvgSI:																					 *;
*		= average magnitude of negative special items over the past 5 years,					 *;
*		where positive or missing SPI is set to zero, values are deflated by beginning total     *;
*		assets, and the rolling average requires 5 valid annual observations.					 *;
**************************************************************************************************;

***************************************************
Part 1 : Import Compustat data and mna_media data
***************************************************;

proc import datafile="&data.\conservatism_compustat_data.csv"
	dbms=csv 
	out=comp_data 
	replace; 
	guessingrows=32767; 
	getnames=yes; 
run;

data mna_media; 
	set PROC.mna_media_final; 
run;

*******************************
Part 2 : Calculate Skewdiff
*******************************;

proc sort data=comp_data; by gvkey fyear; run; 
data comp_data; 
	set comp_data; by gvkey;
	at_lag = lag(at); 
	if first.gvkey then at_lag = .;
	earnings = ib / at_lag; cashflow = oancf / at_lag; 
run;

proc sort data=comp_data; 
	by gvkey fyear datadate; 
run;
 
data comp_data; 
	set comp_data; 
	by gvkey fyear datadate; 
	if last.fyear; 
run; 

proc expand data=comp_data out=comp_data method=none;
	by gvkey; id fyear;

	convert earnings = e_l0;
	convert earnings = e_l1 / transformout = (lag 1 trimleft 1);
	convert earnings = e_l2 / transformout = (lag 2 trimleft 2);
	convert earnings = e_l3 / transformout = (lag 3 trimleft 3);
	convert earnings = e_l4 / transformout = (lag 4 trimleft 4);

	convert cashflow = c_l0;
	convert cashflow = c_l1 / transformout = (lag 1 trimleft 1);
	convert cashflow = c_l2 / transformout = (lag 2 trimleft 2);
	convert cashflow = c_l3 / transformout = (lag 3 trimleft 3);
	convert cashflow = c_l4 / transformout = (lag 4 trimleft 4);
run;

data comp_data;
	set comp_data;
	ne = n(of e_l0-e_l4); nc = n(of c_l0-c_l4);
	if ne >= 4 then earn_skew = skewness(of e_l0-e_l4); else earn_skew = .;
	if nc >= 4 then cashflow_skew = skewness(of c_l0-c_l4); else cashflow_skew = .;
	if nmiss(earn_skew, cashflow_skew) = 0 then Skewdiff = -(earn_skew - cashflow_skew); else Skewdiff = .;
	drop ne nc;
run;

proc sort data=comp_data; 
	by fyear; 
run;

proc rank data=comp_data out=comp_data ties=mean groups=100;
	by fyear;
	var Skewdiff;
	ranks Skewdiff_pct;
run; 

*******************************
Part 3 : Calculate Sumacc
*******************************;

data comp_data; 
	set comp_data; accruals = (ib - oancf + dp) / at_lag; 
run;

data comp_data; 
	set comp_data; 
	acc_ind = accruals ne .; 
run;

proc sort data=comp_data; 
	by gvkey fyear; 
run;

proc expand data=comp_data out=comp_data method=none;
	by gvkey; id fyear; 
	convert accruals = accruals_sum / transformout=(movsum 5 trimleft 4); 
	convert acc_ind = cnt_accruals / transformout=(movsum 5 trimleft 4);
run;

data comp_data;
	set comp_data;
	if cnt_accruals = 5 then Sumacc = -accruals_sum; else Sumacc = .;
run;

proc sort data=comp_data; 
	by fyear; 
run;

proc rank data=comp_data out=comp_data ties=mean groups=100;
	by fyear;
	var Sumacc;
	ranks Sumacc_pct;
run; 

**************************
Part 4 : Calculate AvgSI
**************************;

proc sort data=comp_data; 
	by gvkey fyear; 
run;
 
data comp_data;
	set comp_data;
	by gvkey fyear;
	
	if missing(spi) then si = .; else if spi <0 then si = spi; else si = 0; 
	negSI_mag = abs(si);
	if at_lag > 0 then negSI_def = negSI_mag / at_lag; else negSI_def = .;
	cnt_negSI_def = (negSI_def ne .);
run;

proc sort data=comp_data; 
	by gvkey fyear; 
run;
 
proc expand data=comp_data out=comp_data method=none;
	by gvkey; id fyear; 
	convert negSI_def = sum_negSI / transformout=(movsum 5);
	convert cnt_negSI_def = cnt_negSI / transformout=(movsum 5);
run;

data comp_data;
	set comp_data;
	if cnt_negSI >= 5 then AvgSI = sum_negSI / cnt_negSI; else AvgSI = .;
run;

proc sort data=comp_data; 
	by fyear; 
run;

proc rank data=comp_data out=comp_data ties=mean groups=100;
	by fyear;
	var AvgSI;
	ranks AvgSI_pct;
run; 

*****************************************
Part 5 : Merge back to mna_media data
*****************************************;

data comp_data; 
	set comp_data; 
	gvkey_char = put(gvkey, z6.); 
run;

proc sql;
	create table mna_media_conservatism1 as 
	select a.*, b.Skewdiff_pct, b.Sumacc_pct, b.AvgSI_pct from 
	mna_media as a left join comp_data as b 
	on a.t_gvkey = b.gvkey_char and a.y_ann_num - 1 = b.fyear;
quit; 

*****************************************
Part 6 : Export mna_media_conservatism1
*****************************************;

data PROC.mna_media_conservatism1; 
	set mna_media_conservatism1; 
run; 