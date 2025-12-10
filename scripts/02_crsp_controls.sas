*****************************************************************************;
* Last Update: 2025/11													    *;
* This SAS code construct some of the control variables needed              *;																
*****************************************************************************;

********************************************************************************************;
* Runup: buy and hold abnormal return from 42 days to 4 days before the announcement date, *;
*        adjusted by value weighted market return										   *;
* Relative deal size: deal value / acquirer's MVE, Masulis et al. 2017 (JF)				   *;
********************************************************************************************;

***************************************************
Part 1 - Import mna data, crsp daily stock data
***************************************************; 

data mna_media; 
	set PROC.mna_media_comp; 
run;

data crsp_data;
	infile "&data.\crsp_data.csv" 
		dsd firstobs=2 lrecl=32767 truncover;
	length permno 8 date 8 permco 8 prc 8 ret_char $10 shrout 8 vwretd 8;
	informat date yymmdd10.;
	format date yymmdd10.;
	input permno date permco prc ret_char shrout vwretd;
	ret = input(ret_char, best32.);
run;

*******************************************
Part 2 - Compute runup for target firms
*******************************************;

*select the event window [-42, -4];
data events;
	set mna_media(keep=dealid t_permno a_permno d_ann);
	window_start = d_ann - 42;
	window_end = d_ann - 4;
run; 

*merge events with CRSP daily stock data;
proc sql;
	create table ta_event_ret as 
	select e.dealid, e.t_permno, e.d_ann, c.date, c.ret, c.vwretd, (c.ret - c.vwretd) as ar
    from events as e left join crsp_data as c 
	on c.permno = e.t_permno and c.date between e.window_start and e.window_end;
quit; 

proc sort data=ta_event_ret out=ta_event_ret_sorted; 
	by dealid date; 
run;

*calculate abnormal return for each M&A deal;
proc sql;
	create table ta_runup as 
	select dealid, exp(sum(log(1+ret)))-exp(sum(log(1+vwretd))) as runup, count(ar) as n_days
	from ta_event_ret_sorted group by dealid;
quit;

*merge the abnormal return back to mna_media data;
proc sql;
	create table mna_media_with_tarunup as 
	select a.*, b.runup as ta_runup, b.n_days from mna_media as a left join ta_runup as b
	on a.dealid = b.dealid;
quit; 

*******************************************
Part 3 - Compute runup for acquirer firms
*******************************************;

*merge events with CRSP daily stock data;
proc sql;
	create table ac_event_ret as 
	select e.dealid, e.a_permno, e.d_ann, c.date, c.ret, c.vwretd, (c.ret - c.vwretd) as ar
    from events as e left join crsp_data as c 
	on c.permno = e.a_permno and c.date between e.window_start and e.window_end;
quit; 

proc sort data=ac_event_ret out=ac_event_ret_sorted; by dealid date; run;

*calculate abnormal return for each M&A deal;
proc sql;
	create table ac_runup as 
	select dealid, exp(sum(log(1+ret)))-exp(sum(log(1+vwretd))) as runup, count(ar) as n_days
	from ac_event_ret_sorted group by dealid;
quit;

*merge the abnormal return back to mna_media data;
proc sql;
	create table mna_media_with_acrunup as 
	select a.*, b.runup as ac_runup, b.n_days from mna_media_with_tarunup as a left join ac_runup as b
	on a.dealid = b.dealid;
quit; 

****************************************
Part 4 - Calculate relative deal size
****************************************;

*select data for each M&A deal where date < announcement date;
proc sql;
	create table before_ann as 
	select a.dealid, a.a_permno, a.d_ann, c.date, c.prc, c.shrout
	from mna_media_with_acrunup as a left join crsp_data as c 
	on c.permno = a.a_permno and c.date < a.d_ann;
quit;

*select the 11th trading day before announcement date, following MWX 2015, JF;
proc sort data=before_ann; 
	by dealid descending date; 
run;

data td11_before_ann;
	set before_ann;
	by dealid;
	retain rk;
	if first.dealid then rk = 0;
	rk + 1;
	if rk = 11 then do;
		ad11_date = date;
		mve_ad11 = abs(prc) * shrout;
		format d_ann ad11_date yymmdd10.;
		output;
	end;
	keep dealid d_ann ad11_date prc shrout mve_ad11;
run;

*merge the data of 11th trading day before announcement date back to mna_media_with_acrunup;
proc sql;
	create table mna_media_with_ad11 as 
	select a.*, b.ad11_date, b.mve_ad11
	from mna_media_with_acrunup as a left join td11_before_ann as b 
	on a.dealid = b.dealid;
quit; 

*calculate relative deal size using tranvalue / MVE;
data mna_media_with_ad11; 
	set mna_media_with_ad11; 
	rel_deal_size = tranvalue / mve_ad11;
run; 

****************************************
Part 5 - export the mna_media_with_ad11
****************************************;

data PROC.mna_media_comp_crsp; 
	set mna_media_with_ad11; 
run;