/*****************************************************************************************
* Program:	mainTab.do
* Purpose:  Estimate the baseline H1 regression and export the main regression table and
*           the corresponding regression samples (for summary statistics and PSM).
*
* Data input:
*	- "$proc/mna_media_ap": main analysis dataset constructed in the SAS.
*
* Main settings (defined in master.do):
*	- global depen	  : list of dependent variables (e.g., combined_car3 combined_car5)
*   - global controls : set of control variables used in the baseline regressions
*   - global winsor   : list of variables to be winsorized at the 1st and 99th percentiles
*   - $results        : folder to store regression output
* Steps:
*	(1) Import the M&A media dataset and clean indicator variables.
*   (2) Construct fixed-effect identifiers and cluster variables.
*   (3) Winsorize variables listed in $winsor at the 1% and 99% levels using winsor2.
*   (4) For each dependent variable in $depen, estimate the baseline regression:
*			dv = Closure + controls + FE
*		using reghdfe with industry-year fixed effects and clustered standard errors.
*   (5) For each regression, save the estimation sample, which will be used later.
*	(6) Export the combined regression table to "$results/main_table.csv".
*   
*****************************************************************************************/

import delimited using "$proc/mna_media_ap", ///
    varnames(1) encoding(utf8) case(preserve) clear
	
replace industrymerger = 0 if missing(industrymerger)
replace both_tech = 0 if missing(both_tech)
replace toehold = 0 if missing(toehold)
replace cashonly = 0 if missing(cashonly)
replace stockonly = 0 if missing(stockonly)
replace tender = 0 if missing(tender)
replace hostile = 0 if missing(hostile)
replace multibidder = 0 if missing(multibidder)

// Fixed effects & cluster -----------------------------------------------------
gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)
local fe a_sic2 t_sic2 y_ann_num
local clus a_gvkey t_gvkey

// Define variables ------------------------------------------------------------
local indep Closure                                           
local filename "$results/main_table" 

// Winsorization --------------------------------------------------------------- 
foreach i of global winsor {	  
	winsor2 `i', replace cuts(1 99)
}

// Bseline H1 regression -------------------------------------------------------
cap erase "`filename'.csv"  
eststo clear
local modellist ""
local mtitles   ""
local k = 0

foreach dv of global depen {
    reghdfe `dv' `indep' $controls, absorb($fe) vce(cluster $clus)

    local k = `k' + 1
    eststo m`k'

    local modellist "`modellist' m`k'"
    local mtitles   `"`mtitles' "`dv'""'
	
	preserve
		keep if e(sample) 
		export delimited using "$proc\reg_sample_`dv'.csv", replace
	restore
} 

// Output regression results ---------------------------------------------------
esttab `modellist' using "`filename'.csv", replace csv ///
    mtitles(`mtitles') ///
    cells( b(star fmt(3) label(""))  p(fmt(4) label("")) ) ///
    collabels(none) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    order(Closure) ///
    label ///
    stats(r2 r2_a N, labels("R-squared" "Adj R-squared" "N")) ///
    nobaselevels noomitted














