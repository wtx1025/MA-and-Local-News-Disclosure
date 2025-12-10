***************************************************************************************;
* Last Update: 2025/11													              *;
* This SAS code computes the IVOL, using CRSP data and Fama French 3 factor model     *;                                                                                                          																			*;
***************************************************************************************;

***************************************************
Part 1 - Import mna data, CRSP data, and FF3 data
***************************************************;

data mna_media; 
	set PROC.mna_media_ibes; 
run;

proc import datafile="&data.\FF3.csv" 
	dbms=csv 
	out=ff3_data
	replace;
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

*****************************************************
Part 2 - Select the estimation window for each deal
*****************************************************;

proc sql;
	create table crsp_ff3 as 
	select a.*, b.mktrf, b.smb, b.hml, b.rf, b.umd 
	from crsp_data as a left join ff3_data as b 
	on a.date = b.date;
quit;

data crsp_ff3;
	set crsp_ff3;
	rp = ret - rf;
run;

proc sql;
	create table deal_window as 
	select a.dealid, a.t_permno, a.d_ann, b.date, b.rp, b.mktrf, b.smb, b.hml, b.umd 
	from mna_media as a left join crsp_ff3 as b 
	on a.t_permno = b.permno and b.date between intnx('day', a.d_ann, -370) and intnx('day', a.d_ann, -60)
	order by dealid, date;
quit; 

/* Winsorization
%winsor(
    dsetin  = deal_window,
    byvar   = dealid,
    vars    = rp,
    type    = winsor,
    pctl    = 1 99                                                                                                                                                                  
);
*/  

*********************************************
Part 3 - Estimate regression for each deal
*********************************************;

proc sort data=deal_window;
	by dealid date;
run; 

proc reg data=deal_window noprint outest=ff3_beta;
	by dealid;
	where not missing(rp) and not missing(mktrf) and not missing(smb) and not missing(hml);
	model rp = mktrf smb hml;
	output out=deal_resid residual=resid;
run;

*************************************
Part 4 - Compute IVOL for each deal
*************************************;

proc means data=deal_resid noprint;
	by dealid;
	where not missing(resid);
	var resid;
	output out=ivol_deal std=ivol_pre n=n_days; 
run;

data ivol_deal;
	set ivol_deal;
	if n_days < 150 then ivol_pre = .;
run;

****************************************
Part 5 - Merge IVOL back to mna_media
****************************************;

proc sql;
	create table mna_media_ivol as 
	select a.*, b.ivol_pre, b.n_days as ivol_days 
	from mna_media as a left join ivol_deal as b 
	on a.dealid = b.dealid;
quit;

*****************************
Part 6 - Export the results
*****************************;

data PROC.mna_media_ivol;
    set mna_media_ivol;
run;

proc export data=PROC.mna_media_ivol
    outfile="&proc.\mna_media_ivol.csv" 
    dbms=csv
    replace;
    putnames=yes;
run;

