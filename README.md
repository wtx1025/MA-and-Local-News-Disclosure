## **Overview**

This repository contains code to reproduce results for an M&A research project led by Professors Kim and Cha. The data are accessed via [WRDS](https://wrds-www.wharton.upenn.edu/) — including Compustat, CRSP, and Audit Analytics.

The core premise is that local newspaper closures reduce publicly available firm information and heighten information asymmetry between prospective acquirers and targets. We examine how these closures affect M&A outcomes and whether certain firm characteristics can mitigate the adverse effects of increased information asymmetry.

## **Description**

We construct firm characteristics and control variables in SAS (following established literature). and conduct the empirical analysis in Stata. The sequence for running the .sas and .do files is as follows:  

1. Run 1_control_variables_compustat:  
     i. This code construct control variables using Compustat, including size, leverage, free cash flow, tobin's Q, ROA, and MTB.  
    ii. Use compustat_data.csv and mna_03_18_media_ctr.7bdat as inputs; the code generates mna_media_comp.7bdat as the output dataset.  
   iii.
