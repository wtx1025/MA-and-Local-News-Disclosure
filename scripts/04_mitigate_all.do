/*******************************************************************************************
* Script	: mitigate_all.do
* Purpose	: Run H2 regressions on the full sample to examine whether target characteristics
*			  (e.g. high accrual quality / high conservatism) mitigate the negative effect of
*			  local media closure on M&A outcomes.
*
* Data:		
* 	- Input : "$proc/mna_media_ad" (already merged analysis dataset)
*	- Output: "$results/mitigate_all.csv"
*
* Main steps:
*	1. Import mna_media_ad and clean basic deal characteristics.
*   2. Winsorize all variables in $winsor at the 1st and 99th percentiles. 
*   3. For each characteristics cvar in $charlist:
*      		- Construct highChar as an indicator for being in the top 50% of cvar
*			- Construct interaction term: Closure_highChar = Closure * highChar
*  			- Define regression specification: indepen2 = Closure Closure_highChar highChar
*
*	4. Estimate the regression for each dependent variable in $depen2.
*	5. Export all H2 regressions to "$results/mitigate_all.csv". 
*
********************************************************************************************/

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
local filename "$results/mitigate_all" 

// Winsorization --------------------------------------------------------------- 
foreach i of global winsor {	  
	winsor2 `i', replace cuts(1 99)
}

// Initialize eststo / model list ---------------------------------------------------
cap erase "`filename'.csv"
eststo clear
local modellist ""
local mtitles   ""
local k = 0

// Baseline H2 regression ------------------------------------------------------
foreach cvar of global charlist {

    cap drop p100_2 highChar Closure_highChar
    xtile p100_2 = `cvar' if !missing(`cvar'), n(100)
    gen highChar = (p100_2 > 50) if !missing(p100_2)
    replace highChar = . if missing(p100_2)
    gen Closure_highChar = Closure * highChar

    local indep2 Closure Closure_highChar highChar
	local controls2 "" 
	foreach v of global controls { 
		if "`v'" != "`cvar'" { 
			local controls2 "`controls2' `v'" 
		}  
	}

    foreach dv of global depen2 {
        reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

        local k = `k' + 1
        eststo m`k'

        local modellist "`modellist' m`k'"
        local mtitles   `"`mtitles' "`dv'""'
    }
}

// Output regression results ---------------------------------------------------
esttab `modellist' using "`filename'.csv", replace csv ///
    mtitles(`mtitles') ///
    cells( b(star fmt(3) label(""))  p(fmt(4) label("")) ) ///
	collabels(none) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    order(Closure Closure_highChar highChar) ///
    label ///
    stats(r2 r2_a N, labels("R-squared" "Adj R-squared" "N")) ///
    nobaselevels noomitted


