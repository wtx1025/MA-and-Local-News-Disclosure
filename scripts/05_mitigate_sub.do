/*******************************************************************************************
* Script   : mitigate_sub.do
* Purpose  : Run H2 regressions in subsamples to examine whether target characteristics
*            (e.g. high accrual quality / high conservatism) mitigate the negative effect
*            of local media closure on M&A outcomes under different information-friction
*            environments.
*
* Data:
*   - Input : "$proc/mna_media_ad" (merged analysis dataset for all H2 tests)
*   - Output: "$results/mitigate_sub.csv" (subsample H2 regression results)
*
* Subsample definitions:
*   1) diffState    : Indicator for acquirer and target being in different U.S. states
*                     - diffState = 1 if a_state ≠ t_state
*   2) longDist     : Indicator for geographically distant deals
*                     - longDist = 1 if dist_M > 250
*   3) highIVOL     : Indicator for high pre-announcement idiosyncratic volatility
*                     - highIVOL = 1 if ivol_pre is above the median (based on 100 percentiles)
*   4) lowCoverage  : Indicator for low analyst coverage
*                     - lowCoverage = 1 if NUMEST ≤ 6
*
* Main steps:
*   1. Initialize the output file name, clear stored estimates, and set up containers
*      (modellist, mtitles) for esttab.
*
*   2. For each subsample definition (diffState, longDist, highIVOL, lowCoverage):
*        a. Re-import "$proc/mna_media_ad" and clean basic deal indicators
*           (industrymerger, both_tech, toehold, cashonly, stockonly, tender,
*            hostile, multibidder), and construct 2-digit SIC codes for acquirer
*           and target (a_sic2, t_sic2).
*        b. Generate the subsample indicator (e.g. diffState, longDist, highIVOL,
*           lowCoverage) according to the definition above.
*
*        c. For each characteristic cvar in $charlist:
*             i.  Construct a median-split dummy highChar using 100-percentile ranks
*                 of cvar and the interaction term:
*                     Closure_highChar = Closure × highChar.
*             ii. Define the regression specification:
*                     indepen2  = Closure Closure_highChar highChar
*                 and build controls2 by starting from $controls and dropping cvar
*                 so that the interacted variable is not double-counted.
*
*             iii. For each subsample cell (indicator == 0 and indicator == 1):
*                    - Restrict the sample to the corresponding subsample.
*                    - Winsorize all variables in $winsor at the 1st and 99th
*                      percentiles using winsor2.
*                    - For each dependent variable in $depen2, estimate:
*                          reghdfe dv indepen2 controls2,
*                                  absorb($fe) vce(cluster $clus)
*                    - Store each regression with eststo and append its name to
*                      modellist and its title (dv, cvar, subsample) to mtitles.
*
*   3. After all subsamples and characteristics are processed, use esttab to export
*      all stored models in modellist to "$results/mitigate_sub.csv", reporting
*      coefficients and p-values (with significance stars) for Closure,
*      Closure_highChar, and highChar, along with R-squared, adjusted R-squared,
*      and the number of observations for each regression.
*
* This script complements mitigate_all.do by showing how the mitigating effect of
* target characteristics varies across deals with different degrees of geographic
* and information frictions.
*******************************************************************************************/

// Output file --------------------------------------------------------------------------
local filename "$results/mitigate_sub"
cap erase "`filename'.csv"

eststo clear
local modellist ""
local mtitles   ""
local k = 0


// H2 subsample: diffState --------------------------------------------------------------
import delimited using "$proc/mna_media_ap", ///
    varnames(1) encoding(utf8) case(preserve) clear

replace industrymerger = 0 if missing(industrymerger)
replace both_tech      = 0 if missing(both_tech)
replace toehold        = 0 if missing(toehold)
replace cashonly       = 0 if missing(cashonly)
replace stockonly      = 0 if missing(stockonly)
replace tender         = 0 if missing(tender)
replace hostile        = 0 if missing(hostile)
replace multibidder    = 0 if missing(multibidder)

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

gen diffState = (a_state != t_state) if !missing(a_state) & !missing(t_state)

foreach cvar of global charlist {

    cap drop p100_2 highChar Closure_highChar
    xtile p100_2 = `cvar' if !missing(`cvar'), n(100)
    gen highChar = (p100_2 > 50) if !missing(p100_2)
    replace highChar = . if missing(p100_2)
    gen Closure_highChar = Closure * highChar

    local indep2    Closure Closure_highChar highChar
    local controls2 ""
    foreach v of global controls {
        if "`v'" != "`cvar'" {
            local controls2 "`controls2' `v'"
        }
    }

    // Subsample: diffState = 0 
    preserve
        keep if diffState == 0
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore

    // Subsample: diffState = 1
    preserve
        keep if diffState == 1
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore
}

// H2 subsample: longDist ---------------------------------------------------------------
import delimited using "$proc/mna_media_ap", ///
    varnames(1) encoding(utf8) case(preserve) clear

replace industrymerger = 0 if missing(industrymerger)
replace both_tech      = 0 if missing(both_tech)
replace toehold        = 0 if missing(toehold)
replace cashonly       = 0 if missing(cashonly)
replace stockonly      = 0 if missing(stockonly)
replace tender         = 0 if missing(tender)
replace hostile        = 0 if missing(hostile)
replace multibidder    = 0 if missing(multibidder)

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

gen longDist = (dist_M > 250) if !missing(dist_M)

foreach cvar of global charlist {

    cap drop p100_2 highChar Closure_highChar
    xtile p100_2 = `cvar' if !missing(`cvar'), n(100)
    gen highChar = (p100_2 > 50) if !missing(p100_2)
    replace highChar = . if missing(p100_2)
    gen Closure_highChar = Closure * highChar

    local indep2    Closure Closure_highChar highChar
    local controls2 ""
    foreach v of global controls {
        if "`v'" != "`cvar'" {
            local controls2 "`controls2' `v'"
        }
    }

    // Subsample: longDist = 0
    preserve
        keep if longDist == 0
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore

    // Subsample: longDist = 1
    preserve
        keep if longDist == 1
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore
}

// H2 subsample: highIVOL ----------------------------------------------------------
import delimited using "$proc/mna_media_ap", ///
    varnames(1) encoding(utf8) case(preserve) clear

replace industrymerger = 0 if missing(industrymerger)
replace both_tech      = 0 if missing(both_tech)
replace toehold        = 0 if missing(toehold)
replace cashonly       = 0 if missing(cashonly)
replace stockonly      = 0 if missing(stockonly)
replace tender         = 0 if missing(tender)
replace hostile        = 0 if missing(hostile)
replace multibidder    = 0 if missing(multibidder)

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

xtile p100 = ivol_pre if !missing(ivol_pre), n(100)
gen highIVOL = (p100 > 50)
replace highIVOL = . if missing(p100)

foreach cvar of global charlist {

    cap drop p100_2 highChar Closure_highChar
    xtile p100_2 = `cvar' if !missing(`cvar'), n(100)
    gen highChar = (p100_2 > 50) if !missing(p100_2)
    replace highChar = . if missing(p100_2)
    gen Closure_highChar = Closure * highChar

    local indep2    Closure Closure_highChar highChar
    local controls2 ""
    foreach v of global controls {
        if "`v'" != "`cvar'" {
            local controls2 "`controls2' `v'"
        }
    }

    // Subsample: highIVOL = 0
    preserve
        keep if highIVOL == 0
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore

    // Subsample: highIVOL = 1
    preserve
        keep if highIVOL == 1
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore
}


// H2 subsample: lowCoverage --------------------------------------------------------
import delimited using "$proc/mna_media_ap", ///
    varnames(1) encoding(utf8) case(preserve) clear

replace industrymerger = 0 if missing(industrymerger)
replace both_tech      = 0 if missing(both_tech)
replace toehold        = 0 if missing(toehold)
replace cashonly       = 0 if missing(cashonly)
replace stockonly      = 0 if missing(stockonly)
replace tender         = 0 if missing(tender)
replace hostile        = 0 if missing(hostile)
replace multibidder    = 0 if missing(multibidder)

gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

gen lowCoverage = (NUMEST <= 6) if !missing(NUMEST)

foreach cvar of global charlist {

    cap drop p100_2 highChar Closure_highChar
    xtile p100_2 = `cvar' if !missing(`cvar'), n(100)
    gen highChar = (p100_2 > 50) if !missing(p100_2)
    replace highChar = . if missing(p100_2)
    gen Closure_highChar = Closure * highChar

    local indep2    Closure Closure_highChar highChar
    local controls2 ""
    foreach v of global controls {
        if "`v'" != "`cvar'" {
            local controls2 "`controls2' `v'"
        }
    }

    // Subsample: lowCoverage = 0
    preserve
        keep if lowCoverage == 0
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore

    // Subsample: lowCoverage = 1
    preserve
        keep if lowCoverage == 1
        foreach i of global winsor {
            winsor2 `i', replace cuts(1 99)
        }

        foreach dv of global depen2 {
            reghdfe `dv' `indep2' `controls2', absorb($fe) vce(cluster $clus)

            local ++k
            eststo m`k'

            local modellist "`modellist' m`k'"
            local mtitles   `"`mtitles' `dv' (`cvar')"'
        }
    restore
}

// Esport all results ----------------------------------------------------------------
esttab `modellist' using "`filename'.csv", replace csv ///
    mtitles(`mtitles') ///
    cells( ///
        b(star fmt(3) label("Coef")) ///
        p(fmt(3)  label("p-value")) ///
    ) ///
    collabels(none) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    order( ///
        Closure ///
        Closure_highChar highChar ///
    ) ///
    label ///
    stats(r2 r2_a N, labels("R-squared" "Adj R-squared" "N")) ///
    nobaselevels noomitted

