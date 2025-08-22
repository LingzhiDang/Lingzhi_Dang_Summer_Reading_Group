* This do-file reproduces table D1 to D11 as well as Figures C3, C4 and C6

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

**************
* Figure C3
*************

hist resWcorr_pastWcorr if found_a_job==1 & inrange(resWcorr_pastWcorr,0,2) & ///
	resWcorr!=minW & pastWcorr!=past_minW, ///
	width(0.02) xline(1) frac ///
	xtitle("Reservation wage / Previous wage")
graph export ${OUTPUT}hist_resWcorr_pastWcorr_wominW.pdf, replace
graph export ${OUTPUT}hist_resWcorr_pastWcorr_wominW, as(svg) replace


hist postWcorr_resWcorr if found_a_job==1 &  inrange(postWcorr_resWcorr,0,3) ///
	& resWcorr!=minW & postWcorr!=post_minW, ///
	width(0.02) xline(1) frac ///
	xtitle("Reemployment wage / Reservation wage")
graph export ${OUTPUT}hist_postWcorr_resWcorr_wominW.pdf, replace
graph export ${OUTPUT}hist_postWcorr_resWcorr_wominW, as(svg)replace

	
*************
* Figure C4
*************


hist mobdist_km  if inrange(mobdist_km,0,120), frac  start(0) xlabel(0(20)120) width(5) ///
	xtitle("Maximum acceptable # of kilometers (one way)") title("Reservation commute") subtitle("when declared in kilometers")
graph export ${OUTPUT}hist_mobdist_km.pdf, replace
graph export ${OUTPUT}hist_mobdist_km, as(svg) replace

hist mobdist_tps if inrange(mobdist_tps,1,120),  frac  start(1) xlabel(0 15 30 45 60 90 120) width(5) ///
	xtitle("Maximum acceptable # of minutes (one way)") title("Reservation commute") subtitle("when declared in minutes")
graph export ${OUTPUT}hist_mobdist_tps.pdf, replace
graph export ${OUTPUT}hist_mobdist_tps, as(svg) replace

hist resWcorr ,  frac ///
	xtitle("Gross monthly FTE reservation wage (in euros)") title("Reservation wage") 
graph export ${OUTPUT}hist_resWcorr.pdf, replace
graph export ${OUTPUT}hist_resWcorr, as(svg) replace







*************
** Figure C6
**************
	
*************	
** Panel a and b
**************
use basedetravail_final_qje, clear


cap drop paris
gen paris_region=substr(depcom,1,2)=="75"|substr(depcom,1,2)=="92"|substr(depcom,1,2)=="93" |substr(depcom,1,2)=="95"  ///
|substr(depcom,1,2)=="94"|substr(depcom,1,2)=="77" |substr(depcom,1,2)=="78" |substr(depcom,1,2)=="91" 

capture drop female_paris female_rest
gen female_paris_region=female*paris_region
	gen female_rest_of_France=female*(paris_region==0)
	
foreach var in   log_mobdist log_resWcorr  {

reghdfe `var' i.salunit_ i.mobunit_tps    ///
	log_PBD married child  ///
	 female_paris  female_rest_of_France paris ///
	weekly_hoursE0 prev_cdi log_distanceE0 ///
	 , a(i.age i.exper i.education_  ///
	${occE0}_   i.a38E0_#i.cz#i.period_quarter i.pastW_bins) cluster(idfhda_)		
	  
capture drop _est_`var'_hetgeo
estimates store `var'_hetgeo

}


coefplot log_resWcorr_hetgeo, vertical  ///
	title("Gender gap in reservation wages")  ///	title("Gender gap in FTE monthly wages")  ///
	subtitle("By region of residence") /// ylabel(-150(50)150) xline(7)  xline(11) xline(18) xline(2) ///
	 yline(0) ylabel(-0.05(0.01)-0.02) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_paris_region female_rest_of_France) ///
	coeflabels(female_paris_region="Paris region"  female_rest_of_France="Rest of France")
	graph export ${OUTPUT}\FigureC6_resW.pdf, replace
	graph export ${OUTPUT}\FigureC6_resW, as(svg) replace

	

coefplot log_mobdist_hetgeo, vertical  ///
	title("Gender gap in" "maximum acceptable commute")  ///	title("Gender gap in FTE monthly wages")  ///
	subtitle("By region of residence") /// ylabel(-150(50)150) xline(7)  xline(11) xline(18) xline(2) ///
	 yline(0) ylabel(-0.2(0.05)-0.05) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_paris_region female_rest_of_France) ///
	coeflabels(female_paris_region="Paris region"  female_rest_of_France="Rest of France")
graph export ${OUTPUT}\FigureC6_modist.pdf, replace
graph export ${OUTPUT}\FigureC6_modist, as(svg) replace

******************	
*** panel b and D 
******************	
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


	capture drop paris
	gen paris_region=substr(codegeor,1,2)=="75"|substr(codegeor,1,2)=="92"| ///
	substr(codegeor,1,2)=="93"|substr(codegeor,1,2)=="91"|substr(codegeor,1,2)=="94" ///
	|substr(codegeor,1,2)=="95"|substr(codegeor,1,2)=="77"|substr(codegeor,1,2)=="78"


capture drop female_paris female_outside
gen female_paris_region=female*paris_region
	gen female_rest_of_France=female*(paris==0)

foreach var in     log_dist log_wage  {


reghdfe `var' ///
	agedummy2-agedummy39    ///
		atleast_1child married ///
	female_paris_region  female_rest_of_France paris_region ///
	c.exp c.exp2 i.dip_tot ///	
	fulltime   if inrange(age,20,58) & inrange(an,2003,2010), ///
	cluster(nninouv_) a(pcs3_ i.a38_#i.cz#i.an)

capture drop _est_`var'_hetgeo
estimates store `var'_hetgeo

}


coefplot log_dist_hetgeo, vertical  ///
	title("Gender gap in commute")  ///	
	subtitle("By region of residence") /// 
	 yline(0) ylabel(-0.22(0.02)-0.12) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_paris_region female_rest_of_France) ///
	coeflabels(female_paris_region="Paris region"  female_rest_of_France="Rest of France")
graph export ${OUTPUT}\FigureC6_dist.pdf, replace
graph export ${OUTPUT}\FigureC6_dist, as(svg) replace

coefplot log_wage_hetgeo, vertical  ///
	title("Gender gap in wages")  ///	
	subtitle("By region of residence") ///
	 yline(0) ylabel(-0.15 (0.01)-0.1) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_paris_region female_rest_of_France) ///
	coeflabels(female_paris_region="Paris region"  female_rest_of_France="Rest of France")
	graph export ${OUTPUT}\FigureC6_wage.pdf, replace
	graph export ${OUTPUT}\FigureC6_wage, as(svg) replace


***************
* Table D1 Sanctions 
***************
use basedetravail_final_qje, clear
global occE0="fapE0"

sort motann
capture drop sanction
gen sanction=(motann>="51"&motann<="86" & motann!="71" &  motann!="72" & motann!="73"& motann!="80" ///
&  motann!="59" & motann!="60")| motann=="C1" | motann=="C2" | motann=="CX" ///
| motann=="DX" | motann=="G2" | motann=="H2" 
tab sanction

gen resW_female=log_resWcorr*female 
gen mobdist_female=female*log_mobdist

reghdfe sanction log_resWcorr      ///
	female married  child  ///
	log_PBD  i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)
	outreg2 using ${OUTPUT}table_D1.tex, replace ///
keep(log_resWcorr  ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")

	
reghdfe sanction log_mobdist      ///
	female married  child  ///
	log_PBD mobunit_tps  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)
	outreg2 using ${OUTPUT}table_D1.tex, append ///
keep( log_mobdist ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")

	
reghdfe sanction log_resWcorr  log_mobdist    ///
	female married  child  ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)
	outreg2 using ${OUTPUT}table_D1.tex, append ///
keep(log_resWcorr log_mobdist ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")



	
***************************************************************************
* Table D2: Summary statistics, by gender, for job finders only (Table D2)
***************************************************************************
	
mat M=(.,.,.,.,.,.,.)


foreach var in age  married child education exper ///
	pastW distanceE0 prev_fulltime prev_cdi resWcorr  ///
	 mobdist_km mobdist_tps full_time cdi fap_same_U_E0 postW distanceE1 /// 
	  fulltimeE1 cdiE1  fap_same_E1_E0    dur_NE jobfinding_2years {
sum `var' if male==1&found_a_job==1
sca avg1=r(mean)
sca sd1=r(sd)
sca N1=r(N)

sum `var' if male==0&found_a_job==1
sca avg0=r(mean)
sca sd0=r(sd)
sca N0=r(N)

mat M=  M \ (.,avg1,avg0,sd1,sd0,N1,N0)

}

mat list M

outtable using ${OUTPUT}\SS_by_gender, mat(M) replace center ///
	format(%9.0f %9.3f %9.3f %9.3f)

	
******************
**** Table D3 
*******************
global NAME="tableD3_panelA"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt

foreach var in log_resWcorr log_mobdist fulltime fap_same_U_E0   {
reghdfe `var' ///
	female married child ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}

global NAME="tableD3_panelB"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt

foreach var in log_resWcorr log_mobdist fulltime fap_same_U_E0   {
reghdfe `var' ///
	female married child ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if resWcorr_minW>1.05, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
	
	
}


global NAME="tableD3_panelC"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt

foreach var in log_resWcorr log_mobdist fulltime fap_same_U_E0 cdi  {
reghdfe `var' ///
	female married child ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if prev_fulltime==1, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
	
}

global NAME="tableD3_panelD"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt


foreach var in log_resWcorr  log_mobdist fulltime fap_same_U_E0 cdi {
reghdfe `var' ///
	female married child ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job==1, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
	
}




******************************
* Table D4 job finding 
******************************

global NAME="tableD4"

reghdfe found_a_job ///
	female married i.nchild ///
	log_PBD  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) vce(robust)	
outreg2 using ${OUTPUT}\${NAME}.tex, ///
	replace  keep(female ) ///
	cttop("")


reghdfe found_a_job ///
	female married i.nchild ///
	log_resWcorr i.salunit_ ///
	log_mobdist i.mobunit_tps ///
	fulltime cdi ///
	log_PBD  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.fapU_ ///
	i.a38E0_#i.cz#i.period_quarter) vce(robust)	
outreg2 using ${OUTPUT}\${NAME}.tex, ///
	append  keep(female log_resWcorr log_mobdist) ///
	cttop("Adding all ResW" "type controls") ///
	addtext("Desired Occ.","X","ResW","X","Max commute","X","Desired Hours, Contract","X")
	
	

preserve 

drop if year(datins)>=2011

reghdfe found_a_job ///
	female married i.nchild ///
	log_PBD  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) vce(robust)	
outreg2 using ${OUTPUT}\${NAME}.tex, ///
	append  keep(female ) ///
	cttop("")

reghdfe found_a_job ///
	female married i.nchild ///
	log_resWcorr i.salunit_ ///
	log_mobdist i.mobunit_tps ///
	fulltime cdi ///
	log_PBD  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.fapU_ ///
	i.a38E0_#i.cz#i.period_quarter) vce(robust)	
outreg2 using ${OUTPUT}\${NAME}.tex, ///
	append  keep(female log_resWcorr log_mobdist) ///
	cttop("Adding all ResW" "type controls") ///
	addtext("Desired Occ.","X","ResW","X","Max commute","X","Desired Hours, Contract","X")

restore



**********************
**** Table D5
**********************

global NAME="tableD5_panelA"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt
	
	
foreach var in log_postW log_distanceE1 fulltimeE1 fap_same_E1_U  {

reghdfe `var' ///
	female married nchild ///
	log_PBD  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}




global NAME="tableD5_panelB"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt
	

	
foreach var in log_postW log_distanceE1 fulltimeE1 fap_same_E1_U  {


reghdfe `var' ///
	female married child ///
	log_PBD  ///
	i.mobunit_tps i.salunit_ ///
	full_time log_resWcorr cdi log_mobdist ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job ///
	, a(i.age i.exper i.education_  i.fapU_ ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}





global NAME="tableD5_panelC"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt
	
	
foreach var in log_postW log_distanceE1 fulltimeE1 fap_same_E1_U  {


reghdfe `var' ///
	female married child ///
	log_PBD  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job &resWcorr_minW>1.05 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}



global NAME="tableD5_panelD"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt
	
	
foreach  var in log_postW log_distanceE1 fulltimeE1 fap_same_E1_U  {


reghdfe `var' ///
	female married child ///
	log_PBD  ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job & depcomr_E1==depcom ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(female ) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}


******************
**** Table D6
*******************

encode depcom, ge(depcom_)
global municip="depcom"

global NAME="tableD6"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt

foreach var in log_resWcorr log_mobdist log_postW log_distanceE1   {
reghdfe `var' ///
	female married child ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter ${municip}_) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
keep(female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}

**********************
**** Table D7
**********************

global NAME="tableD7"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt

foreach var in log_resWcorr log_mobdist fulltime fap_same_U_E0   {

reghdfe `var' ///
	childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female ///
	log_PBD i.salunit_ mobunit_tps ///
	prev_fulltime prev_cdi log_distanceE0 /// if found_a_job ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  /// 	i.fapU_ ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}


	




**********************
**** Table D8 
**********************

global NAME="tableD8_panelA"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt


foreach var in log_postW log_distanceE1 fulltimeE1 fap_same_E1_U  {
reghdfe `var' ///
	childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female ///
	log_PBD   	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///	
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(	childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female ///
	) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}



global NAME="tableD8_panelB"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt


foreach var in log_postW log_distanceE1 fulltimeE1 fap_same_E1_U  {
reghdfe `var' ///
	childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female ///
	log_PBD  ///
	log_mobdist i.mobunit_tps i.salunit_ ///
	full_time log_resWcorr cdi ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.fapU_ ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(	childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female ///
	) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}


**********************
**** Table D9 
**********************

global NAME="tableD9"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt

foreach var in log_postW log_distanceE1 fulltimeE1 fap_same_E1_U  {

reghdfe `var' ///
	childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female ///
	log_PBD  ///	
	prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job & resWcorr_minW>1.05 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///	i.fapU_ ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		

outreg2 using ${OUTPUT}\${NAME}.tex, ///
	keep(	childless_single_female /// base is childless_single_male
	childless_married_male childless_married_female ///
	single_withchild_male single_withchild_female ///
	married_withchild_male married_withchild_female ///
	) ///
	addtext("Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
}


 ***************************
*******  Table D11
**************************
use job2job_2004_2012.dta, clear

encode ze, gen(ze_)
egen idfhda_=group(idfhda)
encode a38, gen(a38_E0_)

foreach var in wage dist {
	cap drop difL_`var'
	gen difL_`var'=log(`var'+1)-log(`var'E0+1)
	cap drop `var'_ratio
	gen `var'_ratio=(`var'+1)/(`var'E0+1)
	cap drop difR_`var'
	gen difR_`var'=(`var'-`var'E0)/(`var'E0+1)
}

keep if E1==1 

capture drop wageE0_bins
egen wageE0_bins=cut(wageE0), group(20)


global SAMP  ="E1==1 & U_spell==0 & inrange(durNE,0,190)"

global TRIM="inrange(wage,1112,8920) & inrange(wageE0,1112,8920)"
global TRIM="1"

gen weekly_hoursE0=(nbheurE0/dpE0)*7
gen weekly_hours=(nbheur/dp)*7


global NAME="D11"

cap erase ${OUTPUT}\${NAME}.tex
cap erase ${OUTPUT}\${NAME}.txt


foreach var in log_wage  log_dist   {


	reghdfe `var' female weekly_hoursE0 CDIE0 log_distE0 /// 
		if ${SAMP} & ${TRIM}, a(i.an#i.a38_E0#ze_ i.wageE0_bins i.an#c.expeE0 i.cs2E0_ ///
		i.age i.dip_tot_) cluster(idfhda_)
		
	outreg2 using ${OUTPUT}\${NAME}.tex, keep(female) ///
		addtext("Past Outcome","X","Past wage bins","X","Indiv. contr","X","Past occ.","X","Year X Past Ind. X CZ FE","X")
	
	reghdfe `var' female   ///
		if ${SAMP} & ${TRIM}, a(i.an#ze_    ///
		i.age i.dip_tot_) cluster(idfhda_)
		
	outreg2 using ${OUTPUT}\${NAME}.tex, keep(female) ///
		addtext("Past Outcome","","Past wage bins","","Indiv. contr","X","Past occ.","","Year X Past Ind. X CZ FE","w/o industry")

	}
