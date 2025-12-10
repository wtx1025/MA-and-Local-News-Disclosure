********************************************************;
* Last Update: 2025/11								   *;
* This script runs all the data processing scripts     *;                                                                                                          																			*;
********************************************************;

************************
Part 1 - Some settings
************************;
options mprint mlogic symbolgen;
options nocenter nodate nonumber;

%let main = C:\\Users\\¤ý«FÒj\\Desktop\\Replication Package\; 
%let data = &main.\data;
%let results = &main.\results;
%let scripts = &main.\scripts;
%let proc = &main.\proc;

libname DAT "&data";
libname PROC "&proc"; 

***************************
Part 2 - Run all scripts 
***************************;

%let compustat_controls = 1;
%let crsp_controls = 1;
%let crsp_combinedCAR = 1;
%let accounting_quality1 = 1;
%let accounting_quality2 = 1; 
%let SaleGR = 1;
%let conservatism1 = 1;
%let conservatism2 = 1;
%let zipcode_distance = 1;
%let IBES_analyst = 1;
%let crsp_ivol = 1;
%let accounting_performance = 1;
%let additional = 1;

%if &compustat_controls=1 %then %do;
	%include "&scripts.\\01_compustat_controls.sas";
%end;  

%if &crsp_controls=1 %then %do;
	%include "&scripts.\\02_crsp_controls.sas"; 
%end; 

%if &crsp_combinedCAR=1 %then %do;
	%include "&scripts.\\03_crsp_combinedCAR.sas"; 
%end;

%if &accounting_quality1=1 %then %do;
	%include "&scripts.\\04a_accounting_quality1.sas";
%end; 

%if &accounting_quality2=1 %then %do;
	%include "&scripts.\\04b_accounting_quality2.sas";
%end; 

%if &SaleGR=1 %then %do;
	%include "&scripts.\\05_SaleGR.sas";
%end; 

%if &conservatism1=1 %then %do;
	%include "&scripts.\\06a_conservatism1.sas";
%end; 

%if &conservatism2=1 %then %do;
	%include "&scripts.\\06b_conservatism2.sas";
%end; 

%if &zipcode_distance=1 %then %do;
	%include "&scripts.\\07_zipcode_distance.sas";
%end; 

%if &IBES_analyst=1 %then %do;
	%include "&scripts.\\08_IBES_analyst.sas";
%end; 

%if &crsp_ivol=1 %then %do;
	%include "&scripts.\\09_crsp_ivol.sas";
%end; 

%if &accounting_performance=1 %then %do;
	%include "&scripts.\\10_accounting_performance.sas";
%end; 

%if &additional=1 %then %do;
	%include "&scripts.\\11_additional.sas";
%end; 