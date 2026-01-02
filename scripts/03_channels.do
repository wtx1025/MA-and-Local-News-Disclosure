/*************************************************************************************************
* Program:	channels.do
* Purpose:	Estimate channel regressions for the M&A midea project and export all results into
*           a single table ("channels.csv").
*
* Data inputs: 
* 	- "$proc/mna_media_ap"      : Main analysis sample (used for diffState and highIVOL).
*	- "$proc/mna_media_distance": Sample with acquirer–target distance (used for longDist).
*	- "$proc/mna_media_ibes"    : Sample with analyst coverage (NUMEST; used for lowCoverage).
*
* Main settings (defined in master.do):
*	- globel depen2		: list of dependent variables for the channel analysis.
*	- global controls	: set of control variables used in the baseline regressions.
*	- $results			: folder to store regression output.
*
* Channels:
*	(1) diffState (different-state deals)
*		- diffState = 1 if acquirer and target are located in different U.S. states.
*		- Key regressors: Closure, diffState, Closure x diffState 
*
*	(2) longDist (geographic distance)
*		- longDist = 1 if acquirer-target distance (dist_M) > 250 miles.
*		- Key regressors: Closure, longDist, Closure x longDist.
*
*	(3) highIVOL (pre-deal idiosyncratic volatility)
*		- highIVOL = 1 if ivol_pre is above the median based on 100 percentiles.
*		- Key regressions: Closure, highIVOL, Closure x highIVOL.
*	(4) lowCoverage (analyst coverage)
*		- lowCoverage = 1 if the number of analyst (NUMEST) is less than or equal to 6.
*		- Key regressors: Closure, lowCoverage, Closure x lowCoverage.
*
* Procedure:
*	(i) Initialize eststo and containers (modellist, mtitles).
*	(ii) For each channel:
*		- Import the corresponding dataset.
*		- Clean indicator variables.
*		- Construct 2-digit SIC codes (a_sic2, t_sic2) for fixed effects
*		- Define the channel specific variables and interactions with Closure.
*		- Within a preserve/restore block:
*			* Winsorize variables in $winsor at the 1st and 99th percentiles.
*			* For each dependent variable in $depen2, run:
*				reghdfe dv channel_regressors $controls, absorb($fe) vce(cluster $clus)
*			* Store each specification with eststo and append to modellist and mtitles.
*	(iii) After all four channels are estimated, export a single combined regression table to
*		  "$results/channels.csv", which emphasizing the four interaction terms.
*
*************************************************************************************************/

// Files to output -------------------------------------------------------------------------------
local filename "$results/channels" 
cap erase "`filename'.csv"

eststo clear
local modellist ""
local mtitles   ""
local k = 0

// Channel 1 (diffState) -------------------------------------------------------------------------
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

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

gen diffState = (a_state != t_state) if !missing(a_state) & !missing(t_state)
gen Closure_diffState = Closure * diffState 

local indep1 Closure Closure_diffState diffState                                             

preserve
	foreach i of global winsor {	  
		winsor2 `i', replace cuts(1 99)
	}
	foreach dv of global depen2 {
		reghdfe `dv' `indep1' $controls, absorb($fe) vce(cluster $clus)

		local k = `k' + 1
		eststo m`k'

		local modellist "`modellist' m`k'"
		local mtitles   `"`mtitles' "`dv' (diffState)""'
	}
restore 	

// Channel 2 (longDist) --------------------------------------------------------------------------
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

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

gen longDist = (dist_M > 200) if !missing(dist_M)
gen Closure_longDist = Closure * longDist 

local indep2 Closure Closure_longDist longDist 

preserve
	foreach i of global winsor {	  
		winsor2 `i', replace cuts(1 99)
	}
	foreach dv of global depen2 {
		reghdfe `dv' `indep2' $controls, absorb($fe) vce(cluster $clus)

		local k = `k' + 1
		eststo m`k'

		local modellist "`modellist' m`k'"
		local mtitles   `"`mtitles' "`dv' (longDist)""'
	}
restore 	

// Channel 3 (highIVOL) --------------------------------------------------------------------------
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

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

xtile p100 = ivol_pre if !missing(ivol_pre), n(100)
gen highIVOL = (p100 > 50)
replace highIVOL = . if missing(p100)
gen Closure_highIVOL = Closure * highIVOL

local indep3 Closure Closure_highIVOL highIVOL                                               

preserve
	foreach i of global winsor {	  
		winsor2 `i', replace cuts(1 99)
	}
	foreach dv of global depen2 {
		reghdfe `dv' `indep3' $controls, absorb($fe) vce(cluster $clus)

		local k = `k' + 1
		eststo m`k'

		local modellist "`modellist' m`k'"
		local mtitles   `"`mtitles' "`dv' (highIVOL)""'
	}
restore 	

// Channel 4 (lowCoverage) --------------------------------------------------------------------------
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

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

replace NUMEST = . if NUMEST > 16 
gen lowCoverage = (NUMEST <= 3) if !missing(NUMEST)
gen Closure_lowCoverage = Closure * lowCoverage

local indep4 Closure Closure_lowCoverage lowCoverage                                               

preserve
	foreach i of global winsor {	  
		winsor2 `i', replace cuts(1 99)
	}
	foreach dv of global depen2 {
		reghdfe `dv' `indep4' $controls, absorb($fe) vce(cluster $clus)

		local k = `k' + 1
		eststo m`k'

		local modellist "`modellist' m`k'"
		local mtitles   `"`mtitles' "`dv' (lowCov)""'
	}
restore 

// Export the channel analysis --------------------------------------------------------------------------
esttab `modellist' using "`filename'.csv", replace csv ///
    mtitles(`mtitles') ///
    cells( b(star fmt(3) label(""))  p(fmt(4) label("")) ) ///
    collabels(none) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    order( ///
        Closure ///
        Closure_diffState diffState ///
        Closure_longDist  longDist  ///
        Closure_highIVOL  highIVOL  ///
        Closure_lowCoverage lowCoverage ///
    ) ///
    label ///
    stats(r2 r2_a N, labels("R-squared" "Adj R-squared" "N")) ///
    nobaselevels noomitted






