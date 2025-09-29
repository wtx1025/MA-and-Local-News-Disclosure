*****************************************************************************;
* Last Update: 2025/9													    *;
* This SAS code construct some of the control                               *; 
* variables needed in our work                                              *;																			*;
*****************************************************************************;

***************************************************
Part1 - Import mna data, compustat financial data
***************************************************; 

libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results"; 
data mna_media;
	set CKW.mna_media_big4;
run;

proc import datafile="C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\additional_compustat_data.csv"
	dbms=csv 
	out=comp_data
	replace;
run;

data comp_data(drop=costat curcd datafmt indfmt consol);
    set comp_data;
	if indfmt='INDL'; */some firm has both INDL and FS, we use INDL only; 
run;

*****************************************************
Part2 - construct liquidity and SaleGR for acquirer
*****************************************************;

proc sort data=comp_data; by gvkey fyear datadate; run; 

data comp_data;
	set comp_data;
	by gvkey fyear datadate;
	if last.fyear;
run; 

data comp_data;
	set comp_data;
	by gvkey;
	gvkey_char = put(gvkey, z6.);
	liquidity = (che + lct) / at;

	sale_lag = lag(sale);
	if first.gvkey then sale_lag = .;
	d_sale = (sale - sale_lag) / sale_lag;
run;

proc sort data=comp_data; by gvkey fyear; run; 

proc expand data=comp_data out=comp_data method=none;
	by gvkey;
	id fyear;
	convert d_sale = saleGR / transformout = (movave 3);
run;

proc sql;
	create table mna_media_ac as 
	select a.*, b.liquidity as ac_liquidity, b.SaleGR as ac_SaleGR
	from mna_media as a left join comp_data as b 
	on a.a_gvkey = b.gvkey_char and a.y_ann_num - 1 = b.fyear;
quit; 

*********************************************
Part3 - liquidity and SaleGR for target
*********************************************;
 
proc sql;
	create table mna_media_ta as 
	select a.*, b.liquidity as ta_liquidity, b.SaleGR as ta_SaleGR
	from mna_media_ac as a left join comp_data as b 
	on a.t_gvkey = b.gvkey_char and a.y_ann_num - 1 = b.fyear;
quit; 

**************************
Part4 - export the data
**************************;

libname outlib "C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\results\";

data outlib.mna_media_saleGR;
    set mna_media_ta; 
run; 

libname outlib clear;
libname CKW clear;
