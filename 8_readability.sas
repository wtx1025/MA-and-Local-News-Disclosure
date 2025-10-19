************************************************************************************;
* Last Update: 2025/9													           *;
* This SAS code constrcuts target reaction measure using flesch_reading_ease       *; 
* in SEC readability and sentiment data.                                           *;																			*;
************************************************************************************;

***************************************************
Part1 - Import mna data, readability data
***************************************************;

libname CKW "C:\\Users\\¤ı«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data";
data readability;
	set CKW.sec_readability_80jan_23july;
run;

proc import datafile="C:\\Users\\¤ı«FÒj\\Desktop\\RA\\Kim_Cha\\results\\mna_media_final.csv"
	dbms=csv
	out=mna_media
	replace;
	guessingrows=1000;
	getnames=yes;
run;

***************************************************
Part2 - Merge M&A and readability data using cik
***************************************************;

data mna_media;
	set mna_media (drop=t_cik_char);
	t_cik_char = put(t_cik, z10.);
run;

data readability;
	set readability;
	cik_char = put(cik, z10.);
	fyear = year(fdate);
	where form = '10-K' or form = '10-K/A'; 
run;

proc sort data=readability; by fyear; run;
proc rank data=readability out=readability ties=mean groups=100;
	by fyear;
	var flesch_reading_ease;
	ranks flesch_reading_ease_pct;
run; 

proc sql;
  create table dups_ciky as
  select cik_char, fyear, count(*) as n_in_group
  from readability
  group by cik_char, fyear
  having calculated n_in_group > 1
  order by cik_char, fyear;
quit;

proc sql;
    create table mna_media_readability as
    select  m.*, r.fdate, r.fyear, r.flesch_reading_ease, r.cik_char, r.word_count
    from mna_media as m
    left join readability as r
    on m.t_cik_char = r.cik_char and m.y_ann_num-1 = r.fyear
    ;
quit;

proc sort data=mna_media_readability;
    by dealid descending fdate;
run;

data mna_media_readability;          
    set mna_media_readability;
    by dealid;
    if first.dealid then output;
run;

data mna_media_readability;
	set mna_media_readability;
	log_wc = log(word_count);
	c_read = Closure * flesch_reading_ease;
	cm_read = Closure_Merge * flesch_reading_ease;
run;

***************************************************
Part3 - Export mna_media_readability 
***************************************************;

libname outlib "C:\Users\¤ı«FÒj\Desktop\RA\Kim_Cha\results\";

data outlib.mna_media_readability;
    set mna_media_readability; 
run; 

proc export data=outlib.mna_media_readability 
	outfile="C:\Users\¤ı«FÒj\Desktop\RA\Kim_Cha\results\mna_media_readability.csv"
	dbms=csv 
	replace; 
	putnames=yes; 
run;

libname outlib clear;
libname CKW clear; 