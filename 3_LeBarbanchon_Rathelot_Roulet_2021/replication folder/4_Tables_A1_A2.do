* This conducts the estimation of the commute valuation parameter by gender 
* under other interpretations than main interpretation 1
* They create Appendix Tables B1 and B2

* Interpretation 2 (table B1)
* resW corresponds to a job at distance==0
* max_commute correponds to a job at max wage

* Interpretation 2bis (table B2)
* resW corresponds to a job at the first quartile of distance distribution
* max_commute correponds to a job at third quartile of wage distribution


clear all
global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

set matsize 1000
set maxvar 10000
set maxvar 32000
set max_memory 11g



global occE0="fapE0"


*******************************************************************************
* Interpretation 2  (table A1)
*******************************************************************************


use indiff_curve_dataset.dta, clear
label var mobdist "Max accepted commute in KM"	
		
qreg postW female  c.age##c.age c.education##c.education ///
	c.exper##c.exper i.fap1U i.year if found_a_job==1, q(90) 
cap drop w_q90
predict w_q90

cap drop w_max 
gen w_max=w_q90

cap drop log_w_max
gen log_w_max=log(w_max)


* then we compute for every indiv. the slope of the indifference curve
cap drop indiff_slope
gen indiff_slope=(log_w_max-log_resWcorr)/mobdist 	


foreach var in indiff_slope  {
sum `var', d
sca p1=r(p1)
sca list p1
sca p99=r(p99)
sca list p99
cap drop `var'trunc
gen `var'trunc=`var'
replace `var'trunc=. if missing(`var')==0 & `var'<scalar(p1)
replace `var'trunc=. if missing(`var')==0 & `var'>scalar(p99)
replace `var'=scalar(p1)  if missing(`var')==0 & `var'<scalar(p1)
replace `var'=scalar(p99) if missing(`var')==0 & `var'>scalar(p99)
sum `var', d
}

drop if a38E0_==.

		
gen log_indiff_slope=log(indiff_slope)	

global NAME="tableA1"	
global VAR="log_indiff_slope"	
		
reg ${VAR} female mobunit_tps  if found_a_job==1, ///
	robust
outreg2 using ${OUTPUT}\${NAME}.tex, replace keep(female  )
outreg2 using ${OUTPUT}\${NAME}.dta, dta replace keep(female  )

reg ${VAR} female mobunit_tps log_w_max if found_a_job==1, ///
	robust
outreg2 using ${OUTPUT}\${NAME}.tex,  keep(female  )
outreg2 using ${OUTPUT}\${NAME}.dta, dta keep(female  )

reg ${VAR} female mobunit_tps log_w_max ///
	married child ///
	log_PBD prev_fulltime prev_cdi log_distanceE0 i.pastW_bins ///
	i.age i.exper i.education_  ///
	i.${occE0}_   i.cz i.a38E0_ i.period_quarter ///
	if found_a_job==1, robust
outreg2 using ${OUTPUT}\${NAME}.tex, keep(female )
outreg2 using ${OUTPUT}\${NAME}.dta, dta keep(female  )

reg ${VAR}  mobunit_tps log_w_max ///
	childless_single_female childless_married_female single_withchild_female married_withchild_female ///
	childless_single childless_married single_withchild married_withchild ///
	log_PBD prev_fulltime prev_cdi log_distanceE0 i.pastW_bins ///
	i.age i.exper i.education_  ///
	i.${occE0}_   i.cz i.a38E0_ i.period_quarter ///
	if found_a_job==1, robust
outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female)
outreg2 using ${OUTPUT}\${NAME}.dta, dta ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female)
		
		
	
	


*******************************************************************************
* Interpretation 2 bis (table A2)
*******************************************************************************

use indiff_curve_dataset.dta, clear
label var mobdist "Max accepted commute in KM"	
		
*qreg postW female i.agecut i.expercut i.educcut i.fap1U i.year, q(90)
qreg postW female  c.age##c.age c.education##c.education ///
	c.exper##c.exper i.fap1U i.year if found_a_job==1, q(75) 
	*i.depr_E0_
cap drop w_max 
predict  w_max
cap drop log_w_max
gen log_w_max=log(w_max)

qreg distanceE1 female c.age##c.age c.education##c.education ///
	c.exper##c.exper i.fap1U i.year if found_a_job==1, q(25) 
	*i.depr_E0_
cap drop d_min 
predict  d_min
cap drop log_d_min
gen log_d_min=log(d_min)


* then we compute for every indiv. the slope of the indifference curve
cap drop indiff_slope
gen indiff_slope=(log_w_max-log_resWcorr)/(mobdist-d_min) 	
	

foreach var in  indiff_slope  {
sum `var', d
*sca lb=r(p1)
sca lb=r(p5)
sca list lb
*sca ub=r(p99)
sca ub=r(p95)
sca list ub
cap drop `var'trunc
gen `var'trunc=`var'
replace `var'trunc=. if missing(`var')==0 & `var'<scalar(lb)
replace `var'trunc=. if missing(`var')==0 & `var'>scalar(ub)
replace `var'=scalar(lb)  if missing(`var')==0 & `var'<scalar(lb)
replace `var'=scalar(ub) if missing(`var')==0 & `var'>scalar(ub)
sum `var', d
}


drop if a38E0_==.

		
gen log_indiff_slope=log(indiff_slope)
		
global NAME="tableA2"	
global VAR="log_indiff_slope"	
		
reg ${VAR} female mobunit_tps  if found_a_job==1, ///
	robust
outreg2 using ${OUTPUT}\${NAME}.tex, replace keep(female  )
outreg2 using ${OUTPUT}\${NAME}.dta, dta replace keep(female  )

reg ${VAR} female mobunit_tps log_w_max if found_a_job==1, ///
	robust
outreg2 using ${OUTPUT}\${NAME}.tex,  keep(female  )
outreg2 using ${OUTPUT}\${NAME}.dta, dta keep(female  )

reg ${VAR} female mobunit_tps log_w_max ///
	married child ///
	log_PBD prev_fulltime prev_cdi log_distanceE0 i.pastW_bins ///
	i.age i.exper i.education_  ///
	i.${occE0}_   i.cz i.a38E0_ i.period_quarter ///
	if found_a_job==1, robust
outreg2 using ${OUTPUT}\${NAME}.tex, keep(female )
outreg2 using ${OUTPUT}\${NAME}.dta, dta keep(female  )

reg ${VAR}  mobunit_tps log_w_max ///
	childless_single_female childless_married_female single_withchild_female married_withchild_female ///
	childless_single childless_married single_withchild married_withchild ///
	log_PBD prev_fulltime prev_cdi log_distanceE0 i.pastW_bins ///
	i.age i.exper i.education_  ///
	i.${occE0}_   i.cz i.a38E0_ i.period_quarter ///
	if found_a_job==1, robust
outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female)
outreg2 using ${OUTPUT}\${NAME}.dta, dta ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female)
		

		
		
