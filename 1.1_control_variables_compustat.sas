*****************************************************************************;
* Last Update: 2025/9													    *;
* This SAS code construct some of the control                               *; 
* variables needed in our work                                              *;																			*;
*****************************************************************************;
*
* <1> For each control variablthe detail of how I calculate it can be found in
*     control variables detail.xlsx, I also put the paper I refer to in the file 
* <2> For the way I deal with missing compustat variable I also put the detail
*     in control variables detail.xlsx, including the paper I refer to.  
*;

***************************************************
Part1 - Import mna data, compustat financial data
***************************************************; 

libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data";
data mna_media;
	set CKW.mna_03_18_media_ctr;
run;

proc import datafile="C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\compustat_data.csv"
	dbms=csv 
	out=comp_data
	replace;
run;

data comp_data(drop=costat curcd datafmt indfmt consol);
    set comp_data;
	if indfmt='INDL'; */some firm has both INDL and FS, we use INDL only; 
run;

**************************************************** 
Part2 - build lag total asset (for calculating ROA)
****************************************************;

proc sort data=comp_data;
	by gvkey fyear;
run; 

data comp_data;
	set comp_data;
	by gvkey;
	at_1 = lag(at);
	if first.gvkey then at_1 = .; *no previous year data;
	mean_at = (at + at_1) / 2; 
run;

*******************************************
Part3 - add acquirer data into mna_media
*******************************************;

*extract year of announcement date;
data mna_media;
	set mna_media;
	y_ann = year(d_ann);
	y_ann_num = input(y_ann, best12.);
run;

*change gvkey in comp_data into $6; 
data comp_data;
	set comp_data;
	gvkey_char = put(gvkey, z6.); 
run;

*merge compustat data to mna_media using gvkey=gvkey & y_ann-1=fyear; 
*make sure that we use previous year financial data as control variables; 
proc sql;
	create table mna_media_comp as
	select m.*, c.* from mna_media as m
	left join comp_data as c on m.a_gvkey=c.gvkey_char and c.fyear=m.y_ann_num-1;
quit; 

*rename the column in order to show that it is control variable with regard to acquirer;
*prefix all acquirer-related variable with 'ac_';
data mna_media_comp;
	set mna_media_comp(rename=(
		gvkey = ac_gvkey
		datadate = ac_datadate
		tic = ac_tic
		cik = ac_cik 
		fyr = ac_fyr
		fyrc = ac_fyrc 
		fyear = ac_fyear 
		at = ac_at 
		dltt = ac_dltt 
		dlc = ac_dlc 
		seq = ac_seq 
		ib = ac_ib 
		oibdp = ac_oibdp 
		xint = ac_xint 
		txt = ac_txt 
		csho = ac_scho 
		prcc_f = ac_prcc_f 
		at_1 = ac_at_1
		mean_at = ac_mean_at 
		capx = ac_capx 
		gvkey_char = ac_gvkey_char 
	));
run; 

*******************************************
Part4 - add target data into mna_media
*******************************************;

*merge compustat data to mna_media using gvkey=gvkey & y_ann-1=fyear; 
proc sql;
	create table mna_media_comp as
	select m.*, c.* from mna_media_comp as m
	left join comp_data as c on m.t_gvkey=c.gvkey_char and c.fyear=m.y_ann_num-1;
quit; 

*rename the column in order to show that it is control variable with regard to acquirer;
*prefix all target-related variable with 'ta_';
data mna_media_comp;
	set mna_media_comp(rename=(
		gvkey = ta_gvkey
		datadate = ta_datadate
		tic = ta_tic
		cik = ta_cik 
		fyr = ta_fyr
		fyrc = ta_fyrc 
		fyear = ta_fyear 
		at = ta_at 
		dltt = ta_dltt 
		dlc = ta_dlc 
		seq = ta_seq 
		ib = ta_ib 
		oibdp = ta_oibdp 
		xint = ta_xint 
		txt = ta_txt 
		csho = ta_scho 
		prcc_f = ta_prcc_f 
		at_1 = ta_at_1
		mean_at = ta_mean_at
		capx = ta_capx 
		gvkey_char = ta_gvkey_char 
	));
run; 

*for target firm, some of the data will not have matching results if use gvkey=gvkey & y_ann-1=fyear because
 there is no data for y_ann-1. Thus, we use y_ann-2;
data missing_rows;
	set mna_media_comp;
	if missing(ta_gvkey_char);
run; 

*deal with the problem mentioned above;
*the logic here is that I first select data that doesn't match with target firm,
 then merge them with compustat data where y_ann - 2 = fyear, finally merge
 them back to our main data;
data no_match;
	set mna_media_comp;
	if ta_gvkey_char = '' then output;
	drop ta_:; *drop empty column start with 'ta';
run; 

proc sql;
	create table re_match as select n.*, c.* from no_match as n 
	left join comp_data as c 
	on n.t_gvkey = c.gvkey_char and c.fyear = n.y_ann_num-2;
quit; 

data re_match;
	set re_match(rename=(
		gvkey = ta_gvkey
		datadate = ta_datadate
		tic = ta_tic
		cik = ta_cik 
		fyr = ta_fyr
		fyrc = ta_fyrc 
		fyear = ta_fyear 
		at = ta_at 
		dltt = ta_dltt 
		dlc = ta_dlc  
		seq = ta_seq  
		ib = ta_ib 
		oibdp = ta_oibdp 
		xint = ta_xint 
		txt = ta_txt 
		csho = ta_scho 
		prcc_f = ta_prcc_f 
		at_1 = ta_at_1
		mean_at = ta_mean_at
		capx = ta_capx 
		gvkey_char = ta_gvkey_char 
	));
run; 

data mna_media_comp;
	set mna_media_comp;
	if ta_gvkey_char ne ''; 
run; 

data mna_media_comp;
	set mna_media_comp re_match;
run;  

*********************************
Part5 - deal with missing value
*********************************;

proc means data=mna_media_comp n nmiss;
	var ac_at ta_at ac_dltt ta_dltt ac_dlc ta_dlc ac_seq ta_seq ac_ib
        ta_ib ac_oibdp ta_oibdp ac_xint ta_xint ac_txt ta_txt ac_scho ta_scho ac_prcc_f 
        ta_prcc_f ac_mean_at ta_mean_at ac_capx ta_capx;
run;

*for dltt, lct, and xint, we set them=0 if missing, following HXZ 2015 RFS;
*for capx, oibdp, and mean_at, the key variable needed is missing and we can't calculate it using
 alternative approach. Moreover, the variable needed can't be found in mna_03_18_media_ctr, so I 
 simply drop them (total of 2 observations);
*for scho and prcc_f used to calculate market value of equity, there are a few missing value neither
 of these values appear in CRSP and mna_03_18_media_ctr, so I drop them (total of 6 observation, all 
 of them have Closure=0);

data mna_media_comp;
    set mna_media_comp;
    if missing(ac_dltt) then ac_dltt = 0;
	if missing(ta_dltt) then ta_dltt = 0;
	if missing(ac_dlc) then ac_dlc = 0;
	if missing(ta_dlc) then ta_dlc = 0;
	if missing(ac_xint) then ac_xint = 0;
	if missing(ta_xint) then ta_xint = 0;
	if missing(ac_scho) then delete;
	if missing(ac_prcc_f) then delete;
	if missing(ta_scho) then delete;
	if missing(ta_prcc_f) then delete;
	if missing(ac_capx) then delete;
	if missing(ta_capx) then delete;
	if missing(ac_oibdp) then delete;
	if missing(ta_capx) then delete;
	if missing(ac_mean_at) then delete;
	if missing(ta_mean_at) then delete; 
run;

************************************
Part6 - compute control variables
************************************;

data mna_media_comp;
	set mna_media_comp;
	ac_size = log(ac_at);
	ta_size = log(ta_at);
	ac_leverage = (ac_dlc + ac_dltt) / ac_at;
	ta_leverage = (ta_dlc + ta_dltt) / ta_at; 
	ac_fcf = (ac_oibdp - ac_xint - ac_txt - ac_capx) / ac_at;
	ta_fcf = (ta_oibdp - ta_xint - ta_txt - ta_capx) / ta_at;
	ac_tobinq = (ac_at - ac_seq + ac_scho*ac_prcc_f) / ac_at;
	ta_tobinq = (ta_at - ta_seq + ta_scho*ta_prcc_f) / ta_at;
	ac_roa = ac_ib / ac_mean_at;
	ta_roa = ta_ib / ta_mean_at;
	ac_mtb = (ac_scho*ac_prcc_f) / ac_seq;
	ta_mtb = (ta_scho*ta_prcc_f) / ta_seq;
run;

proc means data=mna_media_comp n mean std min p25 median p75 max;
    var 
        ac_size ta_size 
        ac_leverage ta_leverage 
        ac_fcf ta_fcf 
        ac_tobinq ta_tobinq 
        ac_roa ta_roa 
        ac_mtb ta_mtb;
run;

************************************
Part7 - export the mna_media_comp
************************************;

libname outlib "C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\results\";

data outlib.mna_media_comp;
    set mna_media_comp;
run;