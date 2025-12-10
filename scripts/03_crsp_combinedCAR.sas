***********************************************************************************;
* Last Update: 2025/11													          *;
* This SAS code build combined CAR, which is main dependent variable in our work  *;																	
***********************************************************************************;

***************************************************
Part 1 - Import mna data, crsp daily stock data
***************************************************; 

data mna_media_comp_crsp; 
	set PROC.mna_media_comp_crsp; 
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

**********************************************************************
Part 2 - get acquirer outstanding shares & price before announcement
**********************************************************************;
*
* Cai & Sevilir 2012 JFE use market cap 2 months before announcement date 
* (approxinate 44-46 trading days);  

*select data for each M&A deal where date < announcement date;
proc sql;
	create table amve_before_ann as 
	select a.dealid, a.a_permno, a.d_ann, c.date, c.prc, c.shrout
	from mna_media_comp_crsp as a left join crsp_data as c 
	on c.permno = a.a_permno and c.date < a.d_ann;
quit;

*select the 44th trading day before announcement date;
*initially I use 4th trading day so the variable are like ad4_date, amve_ad4...; 
proc sort data=amve_before_ann; by dealid descending date; run;

data td4_amve__before_ann;
	set amve_before_ann;
	by dealid;
	retain rk;
	if first.dealid then rk = 0;
	rk + 1;
	if rk = 44 then do;
		ad4_date = date;
		amve_ad4 = abs(prc) * shrout;
		format d_ann ad4_date yymmdd10.;
		output;
	end;
	keep dealid d_ann a_permno ad4_date prc shrout amve_ad4;
run;

*merge the data back to mna_media_comp_crsp;
proc sql;
	create table mna_media_with_acad4 as 
	select a.*, b.ad4_date, b.amve_ad4
	from mna_media_comp_crsp as a left join td4_amve__before_ann as b 
	on a.dealid = b.dealid;
quit; 

*******************************************************************
Part 3 - get target outstanding shares & price before announcement
*******************************************************************;
*
* This part does exactly the same thing in part 2, but to target ;

proc sql;
	create table tmve_before_ann as 
	select a.dealid, a.t_permno, a.d_ann, c.date, c.prc, c.shrout
	from mna_media_comp_crsp as a left join crsp_data as c 
	on c.permno = a.t_permno and c.date < a.d_ann;
quit;
   
proc sort data=tmve_before_ann; by dealid descending date; run;

data td4_tmve__before_ann;
	set tmve_before_ann;
	by dealid;
	retain rk;
	if first.dealid then rk = 0;
	rk + 1;
	if rk = 44 then do;
		ad4_date = date;
		tmve_ad4 = abs(prc) * shrout;
		format d_ann ad4_date yymmdd10.;
		output;
	end;
	keep dealid d_ann t_permno ad4_date prc shrout tmve_ad4;
run;

proc sql;
	create table mna_media_with_taad4 as 
	select a.*, b.tmve_ad4
	from mna_media_with_acad4 as a left join td4_tmve__before_ann as b 
	on a.dealid = b.dealid;
quit; 


*********************************
Part 4 - calculate combined CAR
*********************************;

data mna_media_with_taad4;
	set mna_media_with_taad4;
	combined_car3 = (amve_ad4 * a_car3_ffm + tmve_ad4 * t_car3_ffm) / (amve_ad4 + tmve_ad4);
	combined_car5 = (amve_ad4 * a_car5_ffm + tmve_ad4 * t_car5_ffm) / (amve_ad4 + tmve_ad4);
run;

*************************
Part 5 - export mna data
*************************;

data PROC.mna_media_ccar; 
	set mna_media_with_taad4; 
run; 