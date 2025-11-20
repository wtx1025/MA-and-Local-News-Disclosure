***********************************************************************************;
* Last Update: 2025/9													          *;
* This SAS code build combined CAR, which is main dependent variable in our work  *;																	
***********************************************************************************;

***************************************************
Part1 - Import mna data, crsp daily stock data
***************************************************; 

libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results"; 
%let crsp_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\crsp_data.csv;
%let out = C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\results\;

data mna_media_comp_crsp; set CKW.mna_media_comp_crsp; run;
data crsp_data;
	infile "&crsp_file"
		dsd firstobs=2 lrecl=32767 truncover;
	length permno 8 date 8 permco 8 prc 8 ret_char $10 shrout 8 vwretd 8;
	informat date yymmdd10.;
	format date yymmdd10.;
	input permno date permco prc ret_char shrout vwretd;
	ret = input(ret_char, best32.);
run;

****************************************************************************
Part2 - get acquirer outstanding shares & price 50 days before announcement
****************************************************************************;
*
* Cai & Sevilir 2012 JFE use market cap 2 months before announcement date (approxinate 46 days) 

*select data for each M&A deal where date < announcement date;
proc sql;
	create table amve_before_ann as 
	select a.dealid, a.a_permno, a.d_ann, c.date, c.prc, c.shrout
	from mna_media_comp_crsp as a left join crsp_data as c 
	on c.permno = a.a_permno and c.date < a.d_ann;
quit;

*select the 4th trading day before announcement date, following IX 2014, JFE;   
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

*merge the data of 4th trading day before announcement date back to mna_media_comp_crsp;
proc sql;
	create table mna_media_with_acad4 as 
	select a.*, b.ad4_date, b.amve_ad4
	from mna_media_comp_crsp as a left join td4_amve__before_ann as b 
	on a.dealid = b.dealid;
quit; 

****************************************************************************
Part3 - get target outstanding shares & price 50 days before announcement
****************************************************************************;

*select data for each M&A deal where date < announcement date;
proc sql;
	create table tmve_before_ann as 
	select a.dealid, a.t_permno, a.d_ann, c.date, c.prc, c.shrout
	from mna_media_comp_crsp as a left join crsp_data as c 
	on c.permno = a.t_permno and c.date < a.d_ann;
quit;

*select the 4th trading day before announcement date, following IX 2014, JFE;   
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

*merge the data of 4th trading day before announcement date back to mna_media_comp_crsp;
proc sql;
	create table mna_media_with_taad4 as 
	select a.*, b.tmve_ad4
	from mna_media_with_acad4 as a left join td4_tmve__before_ann as b 
	on a.dealid = b.dealid;
quit; 


*********************************
Part4 - calculate combined CAR
*********************************;

data mna_media_with_taad4;
	set mna_media_with_taad4;
	combined_car3 = (amve_ad4 * a_car3_ffm + tmve_ad4 * t_car3_ffm) / (amve_ad4 + tmve_ad4);
	combined_car5 = (amve_ad4 * a_car5_ffm + tmve_ad4 * t_car5_ffm) / (amve_ad4 + tmve_ad4);
run;

*********************************
Part4 - export mna_media_final
*********************************;

libname outlib "&out";
data outlib.mna_media_ccar; set mna_media_with_taad4; run; 
libname outlib clear; 
libname CKW clear; 