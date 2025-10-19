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
8. Run `6a_conservatism1` and `6b_conservatism2`:  
    i. This two codes construct conservatism measure following [Ahmed et al. (2023)](https://onlinelibrary.wiley.com/doi/pdf/10.1111/1911-3846.12814?casa_token=lCFp8U_1_G0AAAAA%3A9VPgcgwuKMI1_c9bn2C5zRuD-rQz9QcCo9K2wxiY2vOE9mOaTH29jpbzhqau08cG_BlX5zIjUhF4b9joJA).  
   ii. `6a_conservatism1` uses `conservatism_compustat_data.csv` and `mna_media_final.7bdat` as inputs, generates `mna_media_conservatism1`; `6b_conservatism2` uses `conservatism_comp_data.csv`, `crsp_monthly_data.csv`, and `mna_media_conservatism1` as inputs, generates `mna_media_conservatism2.7bdat` and `mna_media_conservatism.csv`.
9. Run `7_comparability`:  
    i. This code construct accounting comparability measure, following [Chen et al. (2017)](https://onlinelibrary.wiley.com/doi/pdfdirect/10.1111/1911-3846.12380?casa_token=GNeW26xEAfsAAAAA:4cgKU6L9YDuZWcFZ4zeyXwCGsEmpUNCBwH9isjxQ3H9VSUTyCfsJSUpNkTzEHGUwi75Aj185c_-6UtURCQ).  
   ii. Using `compustat_quarterly_data.csv`, `crsp_data.csv`, and `mna_media_final.7bdat`, the code generates `mna_media_comparability.7bdat` and `mna_media_comparability.csv`.
10. Run `00_regression_template.do`:  
    i. This code do all the regression analysis in this research.  
   ii. Users can modify **depen** and **indep** to analyze variables of interest, or edit the **Cut data into subsample** section to run subsample analyses.  
   
