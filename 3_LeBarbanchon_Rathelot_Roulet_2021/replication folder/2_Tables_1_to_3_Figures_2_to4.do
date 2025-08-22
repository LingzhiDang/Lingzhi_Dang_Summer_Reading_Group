* This do-file reproduces table 1, 2 and 3  as well as Figures 2, 3 , 4

* INPUT:  
* basedetravail_final_qje.dta from 1_construction_main_dataset
* edp_data from 0_prepare_edp 


clear all

global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

set matsize 1000
set maxvar 10000
set max_memory 11g


use basedetravail_final_qje, clear

global occE0="fapE0"

*********************************************
* Table 1 : Summary statistics, by gender
********************************************

	
mat M=(.,.,.,.,.,.,.)


foreach var in age  married child education exper ///
	pastW distanceE0 prev_fulltime prev_cdi resWcorr  ///
	 mobdist_km mobdist_tps full_time cdi fap_same_U_E0 postW distanceE1 /// 
	  fulltimeE1 cdiE1  fap_same_E1_E0    dur_NE jobfinding_2years {
sum `var' if male==1
sca avg1=r(mean)
sca sd1=r(sd)
sca N1=r(N)

sum `var' if male==0
sca avg0=r(mean)
sca sd0=r(sd)
sca N0=r(N)


mat M=  M \ (.,avg1,avg0,sd1,sd0,N1,N0)

}

mat list M

outtable using ${OUTPUT}\SS_by_gender, mat(M) replace center ///
	format(%9.0f %9.3f %9.3f %9.3f)
	



*******************************************************************************
* Figure 2
*******************************************************************************

*sum postWcorr_resWcorr, d
set scheme s2color	
hist resWcorr_pastWcorr if found_a_job==1 & inrange(resWcorr_pastWcorr,0,2), ///
	width(0.02) xline(1) frac ///
	xtitle("Reservation wage / Previous wage") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_resWcorr_pastWcorr.pdf, replace
graph export ${OUTPUT}hist_resWcorr_pastWcorr.svg, as(svg) replace
graph export ${OUTPUT}hist_resWcorr_pastWcorr.eps, as(eps) replace

set scheme s2mono
hist resWcorr_pastWcorr if found_a_job==1 & inrange(resWcorr_pastWcorr,0,2), ///
	width(0.02) xline(1) frac ///
	xtitle("Reservation wage / Previous wage") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_resWcorr_pastWcorr_bw.eps, as(eps) replace


cap drop resWcorr_above_pastWcorr
gen resWcorr_above_pastWcorr=resWcorr_pastWcorr>1

set scheme s2color
hist postWcorr_resWcorr if found_a_job==1 & inrange(postWcorr_resWcorr,0,3), ///
	width(0.02) xline(1) frac ///
	xtitle("Reemployment wage / Reservation wage") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_postWcorr_resWcorr.pdf, replace
graph export ${OUTPUT}hist_postWcorr_resWcorr.svg, as(svg) replace
graph export ${OUTPUT}hist_postWcorr_resWcorr.eps, as(eps) replace

set scheme s2mono
hist postWcorr_resWcorr if found_a_job==1 & inrange(postWcorr_resWcorr,0,3), ///
	width(0.02) xline(1) frac ///
	xtitle("Reemployment wage / Reservation wage") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_postWcorr_resWcorr_bw.eps, as(eps) replace


desc distance*
cap drop distanceE1_mobdist_km
gen distanceE1_mobdist_km=distanceE1/mobdist_km


desc distance*
cap drop mobdist_km_distanceE0
gen mobdist_km_distanceE0=mobdist_km/distanceE0

set scheme s2color
hist mobdist_km_distanceE0 if found_a_job==1 & inrange(mobdist_km_distanceE0,0,20) ///
	& inrange(distanceE0,0,120), ///
	width(0.2) xline(1) frac ///
	xtitle("Max accepted commute / Previous commute") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_mobdist_km_distanceE0.pdf, replace
graph export ${OUTPUT}hist_mobdist_km_distanceE0.svg, as(svg) replace
graph export ${OUTPUT}hist_mobdist_km_distanceE0.eps, as(eps) replace

set scheme s2mono
hist mobdist_km_distanceE0 if found_a_job==1 & inrange(mobdist_km_distanceE0,0,20) ///
	& inrange(distanceE0,0,120), ///
	width(0.2) xline(1) frac ///
	xtitle("Max accepted commute / Previous commute") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_mobdist_km_distanceE0_bw.eps, as(eps) replace

set scheme s2color
hist distanceE1_mobdist_km if found_a_job==1 & inrange(distanceE1_mobdist_km,0,4) ///
	& inrange(distanceE1,0,120), ///
	width(0.05) xline(1) frac ///
	xtitle("Reemployment commute / max accepted commute") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_distanceE1_mobdist_km.pdf, replace
graph export ${OUTPUT}hist_distanceE1_mobdist_km.svg, as(svg) replace
graph export ${OUTPUT}hist_distanceE1_mobdist_km.eps, as(eps) replace

set scheme s2mono
hist distanceE1_mobdist_km if found_a_job==1 & inrange(distanceE1_mobdist_km,0,4) ///
	& inrange(distanceE1,0,120), ///
	width(0.05) xline(1) frac ///
	xtitle("Reemployment commute / max accepted commute") ///
	graphregion( color(white))
graph export ${OUTPUT}hist_distanceE1_mobdist_km_bw.eps, as(eps) replace



***************************
*******  Tables 2 and 3 
***************************


global NAME="table2"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt

foreach var in log_resWcorr log_mobdist  {
reghdfe `var' ///
	female married child ///
	log_PBD mobunit_tps i.salunit_ ///
	weekly_hoursE0 prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}

	foreach var in log_resWcorr log_mobdist  {

reghdfe `var' ///
	female married child ///
	log_PBD mobunit_tps i.salunit_ ///
	weekly_hoursE0 prev_cdi log_distanceE0 ///
	fulltime fap_same_U_E0 cdi ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X", "Other search criteria", "X" )
}

foreach var in log_resWcorr log_mobdist  {

reghdfe `var' ///
	female married child ///
	 mobunit_tps i.salunit_  ///
	, a(i.age  i.education_    i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","","Indiv. contr","X","Past occ.","","Year X Past Ind. X CZ FE","w\o industry", "Other search criteria", "" )
}





global NAME="table3"
keep if found_a_job
cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt



foreach var in log_postW log_distanceE1 {

reghdfe `var' ///
	female married child ///
	log_PBD  ///
	weekly_hoursE0 prev_cdi log_distanceE0 ///
	if found_a_job ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X","Other new job attributes","","Search criteria","")
}

foreach var in log_postW log_distanceE1 {

reghdfe `var' ///
	female married child ///
	fulltimeE1 fap_same_E1_U cdiE1 ///
	log_PBD  ///
	weekly_hoursE0 prev_cdi log_distanceE0 ///
	if found_a_job ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X","Other new job attributes","X","Search criteria",""   )
}


foreach var in log_postW log_distanceE1 {

reghdfe `var' ///
	female married child ///
	fulltimeE1 fap_same_E1_U cdiE1 ///
	log_PBD  ///
	i.mobunit_tps i.salunit_ log_mobdist ///
	full_time log_resWcorr cdi ///
	weekly_hoursE0 prev_cdi log_distanceE0 ///
	if found_a_job ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins i.fapU_ ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X","Other new job attributes","X","Search criteria","X"  )
}

foreach var in log_postW log_distanceE1 {

reghdfe `var' ///
	female married child   ///
	if found_a_job ///
	, a(i.age  i.education_   ///
	i.cz#i.period_quarter) cluster(idfhda_)		
outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","","Indiv. contr","X","Past occ.","","Year X Past Ind. X CZ FE","w\o industry","Other new job attributes","","Search criteria",""  )
}




******************************
* Figure 3 and 4, panels a and c
******************************
	
*************
** Figure 3
**************

global NAME="Figure3_"

foreach var in log_resWcorr   {
reghdfe `var' ///
	childless_single_female childless_married_female single_withchild_female married_withchild_female /// i.child#i.married#c.female ///
	childless_single childless_married single_withchild married_withchild ///
	log_PBD  i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if inrange(age,18,59), a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  /// 
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

capture drop _est_`var'__
estimates store `var'__
estimates save ${OUTPUT}\${NAME}`var', replace		
}

foreach var in  log_mobdist  {
reghdfe `var' ///
	childless_single_female childless_married_female single_withchild_female married_withchild_female /// i.child#i.married#c.female ///
	childless_single childless_married single_withchild married_withchild ///
	log_PBD mobunit_tps ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if inrange(age,18,59), a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  /// 
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

capture drop _est_`var'__
estimates store `var'__
estimates save ${OUTPUT}\${NAME}`var', replace				
}

set scheme s2color
coefplot log_resWcorr__, vertical ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female) ///
	yline(0) ylabel(-0.08(0.02)0) ytitle("log-difference women-men") /// title("Gender gaps in reservation wages") /// subtitle("By family status") /// 
	coeflabels( childless_single_female = "Single, childless"  ///
	single_withchild_female= "Single with child"  ///
	childless_married_female = "Married, childless" ///
	married_withchild_female= "Married with child" ) ///
	graphregion( color(white))
graph export ${OUTPUT}\${NAME}log_resW.pdf, replace	
graph export ${OUTPUT}\${NAME}log_resW.svg, as(svg) replace	
graph export ${OUTPUT}\${NAME}log_resW.eps, as(eps) replace	

set scheme s2mono
coefplot log_resWcorr__, vertical ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female) ///
	yline(0) ylabel(-0.08(0.02)0) ytitle("log-difference women-men") /// title("Gender gaps in reservation wages") /// subtitle("By family status") /// 
	coeflabels( childless_single_female = "Single, childless"  ///
	single_withchild_female= "Single with child"  ///
	childless_married_female = "Married, childless" ///
	married_withchild_female= "Married with child" ) ///
	graphregion( color(white))
graph export ${OUTPUT}\${NAME}log_resW_bw.eps, as(eps) replace	


set scheme s2color
coefplot log_mobdist__, vertical ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female) ///
	yline(0) ylabel(-0.3(0.1)0) ytitle("log-difference women-men") /// title("Gender gaps in" "maximum acceptable commute") ///	subtitle("By family status") /// ytitle("gaps in log points") ///
	coeflabels( childless_single_female = "Single, childless"  ///
	single_withchild_female= "Single with child"  ///
	childless_married_female = "Married, childless" ///
	married_withchild_female= "Married with child" ) ///
	graphregion( color(white))
graph export ${OUTPUT}\${NAME}log_mobdist.pdf, replace	
graph export ${OUTPUT}\${NAME}log_mobdist.svg, as(svg) replace	
graph export ${OUTPUT}\${NAME}log_mobdist.eps, as(eps) replace	

set scheme s2mono
coefplot log_mobdist__, vertical ///
	keep(childless_single_female childless_married_female ///
	single_withchild_female married_withchild_female) ///
	yline(0) ylabel(-0.3(0.1)0) ytitle("log-difference women-men") /// title("Gender gaps in" "maximum acceptable commute") ///	subtitle("By family status") /// ytitle("gaps in log points") ///
	coeflabels( childless_single_female = "Single, childless"  ///
	single_withchild_female= "Single with child"  ///
	childless_married_female = "Married, childless" ///
	married_withchild_female= "Married with child" ) ///
	graphregion( color(white))
graph export ${OUTPUT}\${NAME}log_mobdist_bw.eps, as(eps) replace	


************
** Figure 4
**************

global NAME="Figure4"

keep if age>=18&age<=59
tab age, ge(agedummy)
forvalues j=1(1)42{
gen female_agedummy`j'=female*agedummy`j'
}

foreach var in log_resWcorr   {
reghdfe `var' ///
	agedummy2-agedummy41 female_agedummy1-female_agedummy41  ///
	childless_single childless_married single_withchild married_withchild ///
	log_PBD i.salunit_  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  /// 
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)	

	capture drop _est_`var'_age
	estimates store `var'_age
	estimates save ${OUTPUT}\${NAME}`var'_age, replace				
	
	}
	

set scheme s2color
coefplot log_resWcorr_age, vertical  ///	title("Gender gaps in reservation wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.1(0.05)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	keep(female_agedummy3 female_agedummy4 female_agedummy5 female_agedummy6 female_agedummy7 ///
	female_agedummy8 female_agedummy9 female_agedummy10 female_agedummy11 female_agedummy12 female_agedummy13 female_agedummy14 ///
	female_agedummy15 female_agedummy16 female_agedummy17 female_agedummy18 female_agedummy19 female_agedummy20 female_agedummy21 ///
	female_agedummy22 female_agedummy23 female_agedummy24 female_agedummy25 female_agedummy26 female_agedummy27 female_agedummy28 ///
	female_agedummy29 female_agedummy30 female_agedummy31 female_agedummy32 female_agedummy33 female_agedummy34 female_agedummy35 ///
		female_agedummy36 female_agedummy37 female_agedummy38 female_agedummy39 female_agedummy40 female_agedummy41 female_agedummy42 ) ///
	coeflabels( female_agedummy3="20" female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11=" " female_agedummy12=" " female_agedummy13="30" female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21=" " ///
	female_agedummy22=" " female_agedummy23="40" female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31=" " female_agedummy32=" " female_agedummy33="50" female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " female_agedummy40=" " female_agedummy41=" " female_agedummy42=" ")
graph export ${OUTPUT}\${NAME}_log_resW.pdf, replace 
graph export ${OUTPUT}\${NAME}_log_resW.svg, as(svg) replace 
graph export ${OUTPUT}\${NAME}_log_resW.eps, as(eps) replace 

set scheme s2mono
coefplot log_resWcorr_age, vertical  ///	title("Gender gaps in reservation wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.1(0.05)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	keep(female_agedummy3 female_agedummy4 female_agedummy5 female_agedummy6 female_agedummy7 ///
	female_agedummy8 female_agedummy9 female_agedummy10 female_agedummy11 female_agedummy12 female_agedummy13 female_agedummy14 ///
	female_agedummy15 female_agedummy16 female_agedummy17 female_agedummy18 female_agedummy19 female_agedummy20 female_agedummy21 ///
	female_agedummy22 female_agedummy23 female_agedummy24 female_agedummy25 female_agedummy26 female_agedummy27 female_agedummy28 ///
	female_agedummy29 female_agedummy30 female_agedummy31 female_agedummy32 female_agedummy33 female_agedummy34 female_agedummy35 ///
		female_agedummy36 female_agedummy37 female_agedummy38 female_agedummy39 female_agedummy40 female_agedummy41 female_agedummy42 ) ///
	coeflabels( female_agedummy3="20" female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11=" " female_agedummy12=" " female_agedummy13="30" female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21=" " ///
	female_agedummy22=" " female_agedummy23="40" female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31=" " female_agedummy32=" " female_agedummy33="50" female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " female_agedummy40=" " female_agedummy41=" " female_agedummy42=" ")
graph export ${OUTPUT}\${NAME}_log_resW_bw.eps, as(eps) replace 


foreach var in log_mobdist   {
reghdfe `var' ///
	agedummy2-agedummy42 female_agedummy1-female_agedummy42 ///
	childless_single childless_married single_withchild married_withchild ///
	log_PBD mobunit_tps  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a( i.exper i.education_  ///
	${occE0}_ i.pastW_bins   ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)	

	capture drop _est_`var'_age
	estimates store `var'_age
	estimates save ${OUTPUT}\${NAME}`var'_age, replace				

	}
	

set scheme s2color
coefplot log_mobdist_age, vertical  ///	title("Gender gaps in""maximum acceptable commute") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.3(0.1)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	keep(female_agedummy3 female_agedummy4 female_agedummy5 female_agedummy6 female_agedummy7 ///
	female_agedummy8 female_agedummy9 female_agedummy10 female_agedummy11 female_agedummy12 female_agedummy13 female_agedummy14 ///
	female_agedummy15 female_agedummy16 female_agedummy17 female_agedummy18 female_agedummy19 female_agedummy20 female_agedummy21 ///
	female_agedummy22 female_agedummy23 female_agedummy24 female_agedummy25 female_agedummy26 female_agedummy27 female_agedummy28 ///
	female_agedummy29 female_agedummy30 female_agedummy31 female_agedummy32 female_agedummy33 female_agedummy34 female_agedummy35 ///
		female_agedummy36 female_agedummy37 female_agedummy38 female_agedummy39 female_agedummy40 female_agedummy41 female_agedummy42 ) ///
	coeflabels( female_agedummy3="20" female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11=" " female_agedummy12=" " female_agedummy13="30" female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21=" " ///
	female_agedummy22=" " female_agedummy23="40" female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31=" " female_agedummy32=" " female_agedummy33="50" female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " female_agedummy40=" " female_agedummy41=" " female_agedummy42=" ")
graph export ${OUTPUT}\${NAME}_log_mobdist.pdf, replace 
graph export ${OUTPUT}\${NAME}_log_mobdist.svg, as(svg) replace 
graph export ${OUTPUT}\${NAME}_log_mobdist.eps, as(eps) replace 

set scheme s2mono
coefplot log_mobdist_age, vertical  ///	title("Gender gaps in""maximum acceptable commute") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.3(0.1)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	keep(female_agedummy3 female_agedummy4 female_agedummy5 female_agedummy6 female_agedummy7 ///
	female_agedummy8 female_agedummy9 female_agedummy10 female_agedummy11 female_agedummy12 female_agedummy13 female_agedummy14 ///
	female_agedummy15 female_agedummy16 female_agedummy17 female_agedummy18 female_agedummy19 female_agedummy20 female_agedummy21 ///
	female_agedummy22 female_agedummy23 female_agedummy24 female_agedummy25 female_agedummy26 female_agedummy27 female_agedummy28 ///
	female_agedummy29 female_agedummy30 female_agedummy31 female_agedummy32 female_agedummy33 female_agedummy34 female_agedummy35 ///
		female_agedummy36 female_agedummy37 female_agedummy38 female_agedummy39 female_agedummy40 female_agedummy41 female_agedummy42 ) ///
	coeflabels( female_agedummy3="20" female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11=" " female_agedummy12=" " female_agedummy13="30" female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21=" " ///
	female_agedummy22=" " female_agedummy23="40" female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31=" " female_agedummy32=" " female_agedummy33="50" female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " female_agedummy40=" " female_agedummy41=" " female_agedummy42=" ")
graph export ${OUTPUT}\${NAME}_log_mobdist_bw.eps, as(eps) replace 




***************************************
* Figure 3 and 4, panels b and d
***************************************

use edp_data, clear

	
destring aem*, replace 

gen never_married=aem1==.
gen before_marriage=aem1!=.&aem1>an
gen after_marriage=aem1!=.&aem1<=an
gen married=after_marriage==1
gen female_married=female*married

destring aen1 aen2 aen3, replace

gen never_had_child=aen1==.
gen before_1stchild=aen1!=.&aen1>an
gen after_1stchild=aen1!=.&aen1<=an
gen atleast_1child=after_1stchild==1

gen single_nochild=(married==0)*(atleast_1child==0)
gen single_withchild=(married==0)*(atleast_1child==1)
gen married_nochild=(married==1)*(atleast_1child==0)
gen married_withchild=(married==1)*(atleast_1child==1)

capture drop age_child*
gen age_child1=(an-aen1) if aen1!=.&aen1<=an
gen age_child2=(an-aen2) if aen2!=.&aen2<=an
gen age_child3=(an-aen3) if aen3!=.&aen3<=an

capture drop nber_kids
gen nber_kids=(age_child1!=.)+(age_child2!=.)+(age_child3!=.)

gen education=.
replace education=5 if dip_tot=="2"
replace education=9 if dip_tot=="3"
replace education=11 if dip_tot=="4"
replace education=12 if dip_tot=="5"|dip_tot=="6"
replace education=14 if dip_tot=="7"
replace education=17 if dip_tot=="8"
label var education "Years of education"

replace dip_tot="0" if missing(dip_tot)
destring dip_tot, replace
	
tab age, ge(agedummy)



gen female_atleast1child=female*atleast_1child
gen female_single_nochild=female*(married==0)*(atleast_1child==0)
gen female_single_withchild=female*(married==0)*(atleast_1child==1)
gen female_married_nochild=female*(married==1)*(atleast_1child==0)
gen female_married_withchild=female*(married==1)*(atleast_1child==1)

***************
* Figure 3
****************

global NAME="Figure3_"

foreach var in log_wage log_dist {

reghdfe `var' ///
	agedummy2-agedummy39    ///
	single_withchild married_nochild married_withchild   ///
	female_single_nochild female_single_withchild female_married_nochild female_married_withchild ///
	c.exp c.exp2 i.dip_tot ///	
	fulltime   if inrange(age,20,58) & inrange(an,2003,2010), ///
	cluster(nninouv_) a(pcs3_ i.a38_#i.cz#i.an)

capture drop _est_`var'_fam
estimates store `var'_fam
estimates save ${OUTPUT}\${NAME}`var'_fam, replace
}

set scheme s2color
coefplot log_wage_fam, vertical ///
	keep(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
			order(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
	yline(0) ylabel(-0.2(0.05)0)  	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)")  /// title("Gender gaps in wages") subtitle("By family status") ///
	coeflabels( female_single_nochild="Single, childless" female_married_nochild = "Married, childless" ///
		female_single_withchild= "Single with child"  ///
	female_married_withchild= "Married with child" ) 
graph export ${OUTPUT}\${NAME}log_wage.pdf, replace	
graph export ${OUTPUT}\${NAME}log_wage.svg, as(svg) replace	
graph export ${OUTPUT}\${NAME}log_wage.eps, as(eps) replace	

set scheme s2mono 
coefplot log_wage_fam, vertical ///
	keep(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
			order(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
	yline(0) ylabel(-0.2(0.05)0)  	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)")  /// title("Gender gaps in wages") subtitle("By family status") ///
	coeflabels( female_single_nochild="Single, childless" female_married_nochild = "Married, childless" ///
		female_single_withchild= "Single with child"  ///
	female_married_withchild= "Married with child" ) 
graph export ${OUTPUT}\${NAME}log_wage_bw.eps, as(eps) replace	


set scheme s2color
coefplot log_dist_fam, vertical ///
	keep(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
			order(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
	yline(0) ylabel(-0.3(0.1)0)  	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)")  ///	title("Gender gaps in commute") subtitle("By family status") ///
	coeflabels( female_single_nochild="Single, childless" female_married_nochild = "Married, childless" ///
		female_single_withchild= "Single with child"  ///
	female_married_withchild= "Married with child" )
graph export ${OUTPUT}\${NAME}log_dist.pdf, replace
graph export ${OUTPUT}\${NAME}log_dist.svg, as(svg) replace	
graph export ${OUTPUT}\${NAME}log_dist.eps, as(eps) replace	


set scheme s2mono
coefplot log_dist_fam, vertical ///
	keep(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
			order(female_single_nochild  female_married_nochild female_single_withchild female_married_withchild) ///
	yline(0) ylabel(-0.3(0.1)0)  	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)")  ///	title("Gender gaps in commute") subtitle("By family status") ///
	coeflabels( female_single_nochild="Single, childless" female_married_nochild = "Married, childless" ///
		female_single_withchild= "Single with child"  ///
	female_married_withchild= "Married with child" )
graph export ${OUTPUT}\${NAME}log_dist_bw.eps, as(eps) replace	



*************
** Figure 4
**************

global NAME="Figure4"

keep if age>=18&age<=59
forvalues j=1(1)39{
gen female_agedummy`j'=female*agedummy`j'
}


foreach var in log_wage log_dist {

reghdfe `var' ///
	agedummy2-agedummy39 female_agedummy1-female_agedummy39  ///
	single_withchild married_nochild married_withchild   ///
	c.exp c.exp2 i.dip_tot ///	
	fulltime   if inrange(age,20,58) & inrange(an,2003,2010), ///
	cluster(nninouv_) a(pcs3_ i.a38_#i.cz#i.an)

capture drop _est_`var'_age
estimates store `var'_age
estimates save ${OUTPUT}\${NAME}`var'_age, replace

}
	
	
set scheme s2color
coefplot log_wage_age, vertical  ///	title("Gender gaps in wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.2(0.05)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)") ///
	keep(female_agedummy*) ///
	coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_wage.pdf, replace 
graph export ${OUTPUT}\${NAME}_log_wage.svg, as(svg) replace 
graph export ${OUTPUT}\${NAME}_log_wage.eps, as(eps) replace 

set scheme s2mono
coefplot log_wage_age, vertical  ///	title("Gender gaps in wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.2(0.05)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)") ///
	keep(female_agedummy*) ///
	coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_wage_bw.eps, as(eps) replace 


set scheme s2color	
coefplot log_dist_age, vertical  ///	title("Gender gaps in commute") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.3(0.1)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)") ///
		keep(female_agedummy*) ///
		coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_dist.pdf, replace 
graph export ${OUTPUT}\${NAME}_log_dist.svg, as(svg) replace 
graph export ${OUTPUT}\${NAME}_log_dist.eps, as(eps) replace 

set scheme s2mono
coefplot log_dist_age, vertical  ///	title("Gender gaps in commute") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.3(0.1)0) ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) /// ytitle("Gender gap (log difference)") ///
		keep(female_agedummy*) ///
		coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_dist_bw.eps, as(eps) replace 



	
 
