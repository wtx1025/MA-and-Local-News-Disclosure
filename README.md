## **Overview**

This repository contains code to reproduce results for an M&A research project led by Professors Kim and Cha. The data are accessed via [WRDS](https://wrds-www.wharton.upenn.edu/) — including Compustat, CRSP, and Audit Analytics.

The core premise is that local newspaper closures reduce publicly available firm information and heighten information asymmetry between prospective acquirers and targets. We examine how these closures affect M&A outcomes and whether certain firm characteristics can mitigate the adverse effects of increased information asymmetry.

## **Description**

We construct firm characteristics and control variables in SAS (following established literature). and conduct the empirical analysis in Stata. The sequence for running the .sas and .do files is as follows:  

1. Run `1_control_variables_compustat.sas`:  
   i. This code construct control variables using Compustat, including size, leverage, free cash flow, tobin's Q, ROA, and MTB.  
  ii. Using `compustat_data.csv` and `mna_03_18_media_ctr.7bdat` as inputs; the code generates `mna_media_comp.7bdat` as the output dataset.  
2. Run `2_control_variables_crsp.sas`:  
    i. This code construct control variables using CRSP, including runup and relative deal size.   
   ii. Using `crsp_data.csv` and `mna_media_comp.7bdat` as inputs, the code generates `mna_media_comp_crsp.7bdat` as the output dataset.  
3. Run `3_combined_car.sas`:    
    i. This code construct combined_car3 and combined_car5.  
   ii. Using `crsp_data.csv` and `mna_comp_crsp.7bdat` as inputs, the code generates `mna_media_ccar.7bdat` as the output dataset.  
4. Run `4a_accounting_quality1.sas`:  
    i. This code construct accounting quality measure as one of the control variables, following [McNichols (2002)](https://www.jstor.org/stable/pdf/3203325.pdf?casa_token=yRIMG-ENK5IAAAAA:M-9xUsX0rZAYi0y6k6NCa1VJQo-iBBQffRzBbhO-704SPhn2VBPCqUfoySqFtDiJsh3-zro8xAR7lW8PVuikkLeY7IUs1W03X0FGhLqo2f1mcv9YpXToHg).  
   ii. Using `aq_compustat_data2` and `mna_media_ccar.7bdat` as inputs, the code generates `mna_media_aq.7bdat` as the output dataset.  
5. Run `4b_accounting_quality2.sas`:  
    i. This code construct Big4 and SharedAuditor as control variables.  
   ii. Using `aq_cmopustat_data.csv`, `aa_data.csv`, and `mna_media_aq.7bdat` as inputs, the code generates `mna_media_big4.7bdat` as the output dataset.
6. Run `5a_additional_controls.sas`:  
    i. This code construct liquidity and sale growth as further control variables.  
   ii. Using `additional_compustat_data.csv` and `mna_media_big4.7bdat` as inputs, the code generates `mna_media_SaleGR.7bdat` as the output dataset.
7. Run `5b_additional_controls2.sas`:  
    i. This code construct retcorr as further control variable.  
   ii. Using `crsp_data.csv` and `mna_media_SaleGR.7bdat` as inputs, the code generates `mna_media_final.csv` and `mna_media_final.7bdat`.  
   
