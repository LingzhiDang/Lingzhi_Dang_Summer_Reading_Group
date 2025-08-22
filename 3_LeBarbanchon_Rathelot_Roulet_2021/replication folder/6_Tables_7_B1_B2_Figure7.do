* This do-file reproduces table 7, B1 and B2 as well as Figure 7

* INPUT:  
* m0_de_vac_travail.dta from 1_construction_application_dataset

clear all
set matsize 1000
set maxvar 10000
set max_memory 11g


global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"


use m0_vac_de_travail.dta, clear


****************
* Table 7
****************

sutex hire female vac_wage distance_de_vac de_vac_rome ///
	de_vac_qlf if inrange(distance_de_vac,0,120)
sutex de_vac_educ if inrange(distance_de_vac,0,120) & vac_educ_req
sutex de_vac_exp  if inrange(distance_de_vac,0,120) & vac_any_exp 

sutex vac_hire vac_nb vac_fulltime vac_cdi   ///
	vac_educ_req vac_education vac_any_exp vac_durexpmonth ///
	if vac_rk==1 & inrange(distance_de_vac,0,120)

sutex de_hire de_nb female education exper foreign  ///
	if de_rk==1 & inrange(distance_de_vac,0,120)


****************************
*  Analysis of labor demand
****************************
**************
* Figure 7
*************

global VAR="hire"

set scheme s2color
binscatter ${VAR} distance_de_vac ///
	if inrange(distance_de_vac,0,120) & vac_diversity_gender, ///
	by(female) msymbols(0 circle_hollow) line(qfit) absorb(numofr) ///
	controls(c.education##c.education c.age##c.age c.exper##c.exper)	///
	xtitle("Distance btw worker residence and vacancy workplace (in km)") 
graph export ${OUTPUT}binscatter_${VAR}_distance_fe_control.pdf, replace
graph export ${OUTPUT}binscatter_${VAR}_distance_fe_control.svg, as(svg) replace
graph export ${OUTPUT}binscatter_${VAR}_distance_fe_control.eps, as(eps) replace
	*note("Note: restricted to job ads with both male and female applicants." ///
	*"Control for vacancy fixed effects and worker covariates (age, education, experience)")

*set scheme s2mono
binscatter ${VAR} distance_de_vac ///
	if inrange(distance_de_vac,0,120) & vac_diversity_gender, ///
	by(female) msymbols(0 circle_hollow) line(qfit) absorb(numofr) ///
	controls(c.education##c.education c.age##c.age c.exper##c.exper)	///
	xtitle("Distance btw worker residence and vacancy workplace (in km)") ///
	mcolors(black black)  lcolors(black black)
graph export ${OUTPUT}binscatter_${VAR}_distance_fe_control_bw.eps, as(eps) replace
	
	
**************************
* Table B2
****************************
use m0_vac_de_travail.dta, clear


global VAR="hire"
		
cap erase ${OUTPUT}table_B2.tex
cap erase ${OUTPUT}table_B2.txt

*reg ${VAR} c.distance_de_vac##c.distance_de_vac##c.female ///
*	if inrange(distance_de_vac,0,120), robust cluster(numofr_)
reghdfe ${VAR} c.distance_de_vac##c.distance_de_vac##c.female ///
	if inrange(distance_de_vac,0,120), absorb(i.datmer_monthly ) ///
	cluster(numofr_ idfhda_)

sum distance_de_vac if e(sample) & female==0
sum distance_de_vac if e(sample) & female==1
sum distance_de_vac if e(sample)
sca mean_d=r(mean)	
sca list mean_d
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=0)
mat test=r(table)
sca margin_dist0=test[1,1]
sca list margin_dist0
sca se_dist0=test[2,1]
sca list se_dist0
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=1)
mat test=r(table)
sca margin_dist1=test[1,1]
sca list margin_dist1
sca se_dist1=test[2,1]
sca list se_dist1	
sca margin_diff=margin_dist1-margin_dist0
sca list margin_diff
sca se_diff=sqrt(se_dist0^2+se_dist1^2)
sca list se_diff
sca ratio=margin_diff/se_diff
sca list ratio
	
outreg2 using ${OUTPUT}table_B2.tex, append label nocons ///
	keep(female distance_de_vac c.distance_de_vac#c.distance_de_vac ///
	c.distance_de_vac#c.female c.distance_de_vac#c.distance_de_vac#c.female) ///
	addstat("Margin Men",scalar(margin_dist0),"se Men",scalar(se_dist0), ///
	"Margin Women",scalar(margin_dist1),"se Women",scalar(se_dist1), ///
	"Margin gap", scalar(margin_diff),"se gap",scalar(se_diff) )
	
reghdfe ${VAR} c.distance_de_vac##c.distance_de_vac##c.female ///
	if inrange(distance_de_vac,0,120), ///
	absorb(i.age i.education_ i.exper i.qualif i.foreign ///
	i.datmer_monthly ) cluster(numofr_ idfhda_)
	
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=0)
mat test=r(table)
sca margin_dist0=test[1,1]
sca list margin_dist0
sca se_dist0=test[2,1]
sca list se_dist0
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=1)
mat test=r(table)
sca margin_dist1=test[1,1]
sca list margin_dist1
sca se_dist1=test[2,1]
sca list se_dist1	
sca margin_diff=margin_dist1-margin_dist0
sca list margin_diff
sca se_diff=sqrt(se_dist0^2+se_dist1^2)
sca list se_diff
sca ratio=margin_diff/se_diff
sca list ratio

outreg2 using ${OUTPUT}table_B2.tex, append label nocons ///
	keep(female distance_de_vac c.distance_de_vac#c.distance_de_vac ///
	c.distance_de_vac#c.female c.distance_de_vac#c.distance_de_vac#c.female) ///
	addstat("Margin Men",scalar(margin_dist0),"se Men",scalar(se_dist0), ///
	"Margin Women",scalar(margin_dist1),"se Women",scalar(se_dist1), ///
	"Margin gap", scalar(margin_diff),"se gap",scalar(se_diff) ) ///
	addtext("Worker Control","Y")
	
	
reghdfe ${VAR} c.distance_de_vac##c.distance_de_vac##c.female ///
	if inrange(distance_de_vac,0,120), ///
	absorb(i.age i.education_ i.exper i.qualif i.foreign ///
	i.datmer_monthly  ///
	i.de_vac_rome i.de_vac_edu i.vac_any_exp#i.de_vac_exp) ///
	cluster(numofr_ idfhda_)
	
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=0)
mat test=r(table)
sca margin_dist0=test[1,1]
sca list margin_dist0
sca se_dist0=test[2,1]
sca list se_dist0
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=1)
mat test=r(table)
sca margin_dist1=test[1,1]
sca list margin_dist1
sca se_dist1=test[2,1]
sca list se_dist1	
sca margin_diff=margin_dist1-margin_dist0
sca list margin_diff
sca se_diff=sqrt(se_dist0^2+se_dist1^2)
sca list se_diff
sca ratio=margin_diff/se_diff
sca list ratio
	
outreg2 using ${OUTPUT}table_B2.tex, append label nocons ///
	keep(female distance_de_vac c.distance_de_vac#c.distance_de_vac ///
	c.distance_de_vac#c.female c.distance_de_vac#c.distance_de_vac#c.female) ///
	addstat("Margin Men",scalar(margin_dist0),"se Men",scalar(se_dist0), ///
	"Margin Women",scalar(margin_dist1),"se Women",scalar(se_dist1), ///
	"Margin gap", scalar(margin_diff),"se gap",scalar(se_diff) ) ///
	addtext("Worker Control","Y","Worker-vac. covariate dist", "Y")


reghdfe ${VAR} c.distance_de_vac##c.distance_de_vac##c.female ///
	if inrange(distance_de_vac,0,120) & vac_diversity_gender, ///
	absorb(i.age i.education_ i.exper i.qualif i.foreign ///
	i.datmer_monthly  ///
	i.de_vac_rome i.de_vac_edu i.vac_any_exp#i.de_vac_exp ///
	i.numofr_) ///
	cluster(numofr_ idfhda_)
	
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=0)
mat test=r(table)
sca margin_dist0=test[1,1]
sca list margin_dist0
sca se_dist0=test[2,1]
sca list se_dist0
margins , dydx(distance_de_vac)	at(distance_de_vac=18.85 female=1)
mat test=r(table)
sca margin_dist1=test[1,1]
sca list margin_dist1
sca se_dist1=test[2,1]
sca list se_dist1	
sca margin_diff=margin_dist1-margin_dist0
sca list margin_diff
sca se_diff=sqrt(se_dist0^2+se_dist1^2)
sca list se_diff
sca ratio=margin_diff/se_diff
sca list ratio

outreg2 using ${OUTPUT}table_B2.tex, append label nocons ///
	keep(female distance_de_vac c.distance_de_vac#c.distance_de_vac ///
	c.distance_de_vac#c.female c.distance_de_vac#c.distance_de_vac#c.female) 	///
	addstat("Margin Men",scalar(margin_dist0),"se Men",scalar(se_dist0), ///
	"Margin Women",scalar(margin_dist1),"se Women",scalar(se_dist1), ///
	"Margin gap", scalar(margin_diff),"se gap",scalar(se_diff) ) ///
	addtext("Worker Control","Y","Worker-vac. covariate dist", "Y", "Vacancy FE", "Y")
	
	
	
****************************************
*  Elasticity of wage w.r.t. distance 
****************************************
******************	
* Table B1
******************
use m0_vac_de_travail.dta, clear

global TAB="B1"


cap erase ${OUTPUT}table_${TAB}.tex
cap erase ${OUTPUT}table_${TAB}.txt


reghdfe log_vac_wage c.log_distance_de_vac##c.female ///
	if inrange(distance_de_vac,0,120) , ///
	absorb(i.vac_dtecrepof_monthly i.de_cz) ///
	cluster(idfhda_ numofr_)

outreg2 using ${OUTPUT}table_${TAB}.tex, append label nocons ///
	keep(female log_distance_de_vac c.log_distance_de_vac#c.female)

reghdfe log_vac_wage c.log_distance_de_vac##c.female ///
	c.dur_U_mer ///
	if inrange(distance_de_vac,0,120) , ///
	absorb(	i.idfhda_ /// i.age i.education_ i.exper i.qualif i.foreign i.de_rome ///
	i.vac_dtecrepof_monthly) ///
	cluster(idfhda_ numofr_)
	
outreg2 using ${OUTPUT}table_${TAB}.tex, append label nocons ///
	keep(female log_distance_de_vac c.log_distance_de_vac#c.female) ///
	addtext("Worker Control","Y","Worker FE", "Y")
	
	
reghdfe log_vac_wage c.log_distance_de_vac##c.female ///
	c.dur_U_mer ///
	if inrange(distance_de_vac,0,120)  ///
	& samp_occminW==0, ///
	absorb(	i.idfhda_ /// i.age i.education_ i.exper i.qualif i.foreign i.de_rome ///
	i.vac_dtecrepof_monthly) ///
	cluster(idfhda_ numofr_)
	
outreg2 using ${OUTPUT}table_${TAB}.tex, append label nocons ///
	keep(female log_distance_de_vac c.log_distance_de_vac#c.female) ///
	addtext("Worker Control","Y","Worker FE", "Y", ///
	"Sample",">minW")	

reghdfe log_vac_wage c.log_distance_de_vac##c.female ///
	c.dur_U_mer ///
	if inrange(distance_de_vac,0,120)  ///
	& samp_occminW==0, ///
	absorb(	i.idfhda_ /// i.age i.education_ i.exper i.qualif i.foreign i.de_rome ///
	i.vac_dtecrepof_monthly /// i.de_cz ///
	i.vac_occupation i.vac_typoff i.vac_durheb_hours i.vac_qlf ///
	i.vac_educ_req i.vac_any_exp) ///
	cluster(idfhda_ numofr_)
	
outreg2 using ${OUTPUT}table_${TAB}.tex, append label nocons ///
	keep(female log_distance_de_vac c.log_distance_de_vac#c.female) ///
	addtext("Worker Control","Y","Worker FE", "Y", ///
	"Vacancy Controls", "Y", "Sample",">minW")	
	

	
	
	
