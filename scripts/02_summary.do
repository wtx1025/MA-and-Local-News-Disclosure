/********************************************************************************************
* Program:		summary.do
* Purpose:		(i) Produce descriptive statistics for the main regression sample, and
*               (ii) construct distribution tables by target industry (t_sic2) and deal year.
*
* Data input:
* 	- "$proc/reg_sample_combined_car3": regression sample for the baseline specification	
*     with combined_car3 as the dependent variable. The file is generated in the main
*     regression script.
*
* Main settings (defined in master.do):
*	- global depen		: list of main dependent variables (e.g., combined car3, combined_car5)
*   - global controls	: set of control variables used in the baseline regressions 
*   - $results          : folder to store the ooutput tables 
*
* Steps:
*	(1) Import the regression sample from "$proc/reg_sample_combined_car3".
*	(2) Construct descriptive statistics (count, mean, sd, p25, p50, and p75) for all variables
*       in $depen, Closure, $controls, and conservatism, and then export the summary statistics
*       to "$results/descriptive_table.csv".
*	(3) Build an industry-level distribution table:
*       - Group observations by target 2-digit SIC (t_sic2).
*       - For each t_sic2, compute the number of deals with Closure=1, Closure=0, and the total.
*       - Label this panel as "Year" and save it as a temporary dataset.
*   (4) Build a year-level distribution table:    
*       - Group observations by announcement year (y_ann_num).
*       - For each year, compute the number of deals with Closure=1, Closure=0, and the total.
*       - Label this panel as "Year" and save it as a temporary dataset.
*   (5) Append the industry and year panels into a single dataset and export the combined
*       distribution table to "$results/distribution_table.csv".
*
********************************************************************************************/

import delimited using "$proc/reg_sample_combined_car3", ///
    varnames(1) encoding(utf8) case(preserve) clear

// Make descriptive statistics -------------------------------------------------------------	
global sumvars $depen Closure $controls conservatism
eststo clear
estimates clear

estpost tabstat $sumvars, statistics(count mean sd p25 p50 p75) columns(statistics)
esttab using "$results/descriptive_table.csv", ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) p25(fmt(3)) p50(fmt(3)) p75(fmt(3))") ///
    collabels("N" "Mean" "SD" "P25" "P50" "P75") ///
    nomtitle nonumber noobs ///
    replace plain csv

// Make distribution table by industry -----------------------------------------------------
preserve
    keep t_sic2 Closure

    gen byte Closure0 = (Closure == 0) if !missing(Closure)
    gen byte Closure1 = (Closure == 1) if !missing(Closure)

    bysort t_sic2: egen N_Closure0 = total(Closure0)
    bysort t_sic2: egen N_Closure1 = total(Closure1)
    gen Total = N_Closure0 + N_Closure1

    keep t_sic2 N_Closure0 N_Closure1 Total
    duplicates drop
    sort t_sic2

    gen str10 panel = "Industry"
    rename t_sic2 group

    tempfile ind
    save `ind'
restore

// Make distribution table by industry -----------------------------------------------------
preserve
    keep y_ann_num Closure

    gen byte Closure0 = (Closure == 0) if !missing(Closure)
    gen byte Closure1 = (Closure == 1) if !missing(Closure)

    bysort y_ann_num: egen N_Closure0 = total(Closure0)
    bysort y_ann_num: egen N_Closure1 = total(Closure1)
    gen Total = N_Closure0 + N_Closure1

    keep y_ann_num N_Closure0 N_Closure1 Total
    duplicates drop
    sort y_ann_num

    gen str10 panel = "Year"
    rename y_ann_num group

    tempfile yr
    save `yr'
restore

// Export distribution table ---------------------------------------------------------------
use `ind', clear
append using `yr'

order panel group N_Closure0 N_Closure1 Total
sort panel group

export delimited using "$results\distribution_table.csv", replace

