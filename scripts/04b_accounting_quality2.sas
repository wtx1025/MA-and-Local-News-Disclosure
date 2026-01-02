******************************************************************;
* Last Update: 2025/9										     *;
* This SAS code calculate constrcut Big4 as control variable,    *;
* following Ahmed 2023                                           *; 	
******************************************************************;

***********************************************************************
Part 1 - Import compustat data & mna_media_aq & audit analytics data
***********************************************************************;

data mna_media_aq;
	set PROC.mna_media_aq;
run;

proc import datafile="&data.\aq_compustat_data.csv" 
	dbms=csv 
	out=comp_data
	replace;
	guessingrows=1000; 
    getnames=yes;
run; 

proc import datafile="&data.\aa_data.csv" 
	dbms=csv 
	out=aa_data
	replace;
run; 

data comp_data;
	set comp_data (keep=gvkey cik fyear indfmt datadate);
	if indfmt = 'INDL';
	gvkey_char = put(gvkey, z6.); 
run;

*************************************************************
Part 2 - find acquirer cik and target cik for mna_media_aq
*************************************************************;

proc sql;
	create table mna_media_aq_acik as
	select m.*, c.cik as a_cik 
	from mna_media_aq as m left join comp_data as c 
	on m.a_gvkey = c.gvkey_char and m.y_ann_num = c.fyear;
quit;

*************************************************************
Part 3 - Prepare the big4 for each cik*year in aa_data
*************************************************************;

data aa_prep;
	set aa_data;
	company_fkey_char = put(company_fkey, z10.); 

	big4 = 0;
	if auditor_name in(
		'Deloitte & Touche L',
        'PricewaterhouseCoop',
        'Ernst & Young LLP',
        'KPMG LLP'
	) then big4 = 1; 

	keep company_fkey_char fiscal_year big4
run; 

proc sql;
	create table aa_big4_ciky as 
	select company_fkey_char, fiscal_year, max(big4) as big4 from aa_prep
	group by company_fkey_char, fiscal_year;
quit; 

*****************************************************
Part 4 - create list of auditors for each cik*year
*****************************************************;

data aa_names;
	set aa_data(keep=company_fkey fiscal_year auditor_name);
	company_fkey_char = put(company_fkey, z10.);
run;

proc sort data=aa_names nodupkey;
	by company_fkey_char fiscal_year auditor_name;
run; 

proc sort data=aa_names; by company_fkey_char fiscal_year; run;

data aa_list;
	set aa_names;
	by company_fkey_char fiscal_year;
	length auditor_list $2000;
	retain auditor_list;
	if first.fiscal_year then auditor_list = auditor_name;
	else auditor_list = catx(',', auditor_list, auditor_name);
	if last.fiscal_year then output;
	keep company_fkey_char fiscal_year auditor_list;
run;

*****************************************************************
Part 5 - merge big4 for acquirer and target back to mna_media_aq
*****************************************************************;

data mna_media_aa;
	set mna_media_aq_acik;
	a_cik_char = put(a_cik, z10.);

	length t_cik_char $10;
    _raw = compress(strip(t_cik), , 'kd'); 
    if not missing(_raw) then t_cik_char = put(input(_raw, best12.), z10.);
    drop _raw;
run;

proc sql;
	create table mna_with_abig4 as 
	select m.*, a.fiscal_year, a.company_fkey_char, a.big4 as ac_big4, l.auditor_list as ac_auditor_list
    from mna_media_aa as m left join aa_big4_ciky as a
	on m.a_cik_char = a.company_fkey_char and m.y_ann_num - 1 = a.fiscal_year
	left join aa_list as l 
	on m.a_cik_char = l.company_fkey_char and m.y_ann_num - 1 = l.fiscal_year;
quit;

proc sql;
	create table mna_with_tbig4 as 
	select m.*, a.fiscal_year, a.big4 as ta_big4, a.company_fkey_char, l.auditor_list as ta_auditor_list
    from mna_with_abig4 as m left join aa_big4_ciky as a
	on m.t_cik_char = a.company_fkey_char and m.y_ann_num - 1 = a.fiscal_year
	left join aa_list as l 
	on m.t_cik_char = l.company_fkey_char and m.y_ann_num - 1 = l.fiscal_year;
quit;

****************************************
Part 6 - Construct SharedAuditor
****************************************;

data mna_with_tbig4;
	set mna_with_tbig4;
	length SharedAuditor 8;           

    if missing(ac_auditor_list) or missing(ta_auditor_list) then SharedAuditor = .;
    else if ac_auditor_list = ta_auditor_list then SharedAuditor = 1;
    else SharedAuditor = 0;
run;

****************************************
Part 5 - Export mna_with_big4
****************************************;

data PROC.mna_media_big4;
    set mna_with_tbig4; 
run;
 