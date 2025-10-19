*****************************************************************************;
* Last Update: 2025/9													    *;
* This SAS code construct some of the control                               *; 
* variables needed in our work                                              *;																			*;
*****************************************************************************;

**************************************
Part1 - Import mna data, crsp data
**************************************;

libname CKW "C:\\Users\\¤ı«FÒj\\Desktop\\RA\\Kim_Cha\\results"; 
data mna_media;
	set CKW.mna_media_saleGR;
run;

data crsp_data;
	infile "C:\\Users\\¤ı«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\crsp_data.csv"
		dsd firstobs=2 lrecl=32767 truncover;
	length permno 8 date 8 permco 8 prc 8 ret_char $10 shrout 8 vwretd 8;
	informat date yymmdd10.;
	format date yymmdd10.;
	input permno date permco prc ret_char shrout vwretd;
	ret = input(ret_char, best32.);
run;

*****************************************************
Part2 - define the windows and get the stock return
*****************************************************;

data events;
	set mna_media(keep=dealid a_permno t_permno d_ann);
	end_date = intnx('month', d_ann, -2, 'same');
	start_date = end_date - 364;
	format start_date end_date yymmdd10.;
run;

*get acquirer daily return;
proc sql;
	create table ac_ret as 
	select e.dealid, e.start_date, e.end_date, e.a_permno as permno, c.date, c.ret as ret_a
	from events as e left join crsp_data as c
	on c.permno = e.a_permno and c.date between e.start_date and e.end_date
	where not missing(e.a_permno);
quit;

*get target daily return;
proc sql;
  create table ta_ret as
  select e.dealid, e.start_date, e.end_date, e.t_permno as permno, c.date, c.ret as ret_t
  from events as e
  left join crsp_data as c
    on c.permno = e.t_permno
   and c.date between e.start_date and e.end_date
  where not missing(e.t_permno);
quit;

proc sort data=ac_ret; by dealid date; run;
proc sort data=ta_ret; by dealid date; run;

********************************************
Part3 - caculate the return correlation
********************************************;

proc sql;
	create table pair_ret as 
	select a.dealid, a.date, a.ret_a, b.ret_t 
	from ac_ret as a inner join ta_ret as b
	on a.dealid = b.dealid and a.date = b.date
	where a.ret_a is not null and b.ret_t is not null;
quit;

proc sort data=pair_ret; by dealid; run;

ods exclude all;
proc corr data=pair_ret noprint pearson outp=_corr; 
  by dealid;
  var ret_a ret_t;
run;
ods select all;

data retcorr;
	set _corr;
	where _TYPE_ = 'CORR' and _NAME_ = 'ret_a';
	retcorr = ret_t;
	keep dealid retcorr;
run;

********************************************
Part4 - merge retcorr back to mna_media
********************************************;

proc sort data=retcorr nodupkey; by dealid; run; 

proc sql;
	create table mna_media_retcorr as 
	select m.*, r.retcorr 
	from mna_media as m left join retcorr as r 
	on m.dealid = r.dealid;
quit;

***************************
Part5 - export the data
***************************;

data mna_media_recent;
    set mna_media_retcorr;           
    recent = 0;
    if nmiss(y_ann_num, CM_year)=0 
       and y_ann_num >= CM_year + 1 
       and y_ann_num <= CM_year + 5 then recent = 1;

    c_recent = Closure * recent;
    cm_recent  = Closure_Merge * recent;    
run;

libname outlib "C:\\Users\\¤ı«FÒj\\Desktop\\RA\\Kim_Cha\\results";

data outlib.mna_media_final;
    set mna_media_recent; 
run; 

proc export data=outlib.mna_media_final 
	outfile="C:\Users\¤ı«FÒj\Desktop\RA\Kim_Cha\results\mna_media_final.csv"
	dbms=csv 
	replace; 
	putnames=yes; 
run;

libname outlib clear;
libname CKW clear;
