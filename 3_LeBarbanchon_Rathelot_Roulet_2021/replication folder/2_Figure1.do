/*
This dofile creates Figure 1


Input: Paneldads_pre2009 and Paneldads_post2009 from Convert_stata_paneldads2015.sas


*/




clear all 

set matsize 10000
set maxvar 10000
set max_memory 11g


global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"



set more off, permanently

**********************************
* preparing the data for the time series 
**********************************
use Paneldads_pre2009, clear
append using Paneldads_post2009

replace pcs4=upper(pcs4)
compress

order nninouv an sir   nbheur dp age annai sx cs1 cs2 cs1_anc cs2_anc pcs4 pcs_v2 ///
	ce  entpan entsir  sb sbr  comr comt depr dept regn regr regt ///
	domempl sirfict nic4 a38 ape40 apen apen2 apet apet2 nes5 nes36 nes36n st catjur
	
sort nninouv an sir
										
drop if missing(sir)
 
label var nninouv "Individual identifier"
label var an 	 "Year of employment"
label var sir    "Firm identifier"
label var a38	 "Industry of the firm (36 cells)" 
label var dp     "Nb of days worked within firm X year"
label var nbheur "Nb of hours worked within firm X year"
label var sb	 "Gross wage within firm X year"
label var sbr    "Real gross wage within firm X year"
*label var contrat_travail " Type of labor contract"
label var cs1	 "Occupation type (1 digit)"
label var cs2	 "Occupation type (2 digits)"
label var pcs_v2 "Occupation type (4 digits) missing"
label var pcs4   "Occupation type (4 digits)"
label var annai  "Birth year of worker"
label var sx     "Gender"
label var entpan "First year in the DADS panel"
label var entsir "Hiring year in the firm"

cap drop wage
gen wage=sbr/dp*30.5 if ce=="C"
replace wage=(sbr/nbheur)*35*4.5 if ce=="P" & inrange(an,1993,2010)
replace wage=sbr/dp*30.5 if ce=="P" & inrange(an,1976,1992)
label var wage "FTE montly wage (DADS)"

replace wage=10000 if wage>10000 & wage!=.
replace wage=100 if wage<100 & wage!=.

cap drop wage_hourly
gen wage_hourly=sbr/nbheur
label var wage_hourly "Hourly wage (DADS)"
replace wage_hourl=56.8 if wage_hourly>56.8 & wage_hourl!=.
replace wage_hourl= 5.8 if wage_hourly<5.8 & wage_hourl!=.
* lowest minimum wage over the period considered

*we drop oversea dept 
drop if inrange(substr(dept,1,2),"97","99")
drop if inrange(substr(depr,1,2),"97","99")
 drop if substr(depr,1,2)=="2A" |substr(depr,1,2)=="2B" |substr(dept,1,2)=="2A" |substr(dept,1,2)=="2B" 
  drop if substr(dept,1,2)=="9A" |substr(dept,1,2)=="9B" |substr(dept,1,2)=="9C" |substr(dept,1,2)=="9D" 
    drop if substr(depr,1,2)=="9A" |substr(depr,1,2)=="9B" |substr(depr,1,2)=="9C" |substr(depr,1,2)=="9D" 

sort nninouv an sir
drop sir entpan entsir  sb   

gen female=sx=="0"

drop if missing(age)
keep if inrange(age,18,58) 

egen nninouv_=group(nninouv)


set seed 987654
gen test=runiform()
cap drop insamp
bys nninouv_: gen insamp=inrange(test,0,0.2) if _n==1
cap drop test_ 
by nninouv_: egen test_=mean(insamp)
keep if test_==1
drop test_ test insamp sirfict


gen INSEE_COM=dept+ comt 
merge m:1 INSEE_COM using ${SOURCES}\GEOFLA_COMMUNE, keepusing(X_CENTROID Y_CENTROID SUPERFICIE)
drop if _m==2
drop _m
rename X_CENTROID xt
rename Y_CENTROID yt
rename SUPERFICIE St
label var xt "X-geographical coordinate of workplace (centroid of firm's municipality)"
label var yt "Y-geographical coordinate of workplace (centroid of firm's municipality)"
label var St "Superficie of firm's municipality (hectar)"
rename INSEE_COM codegeot
label var codegeot "Municipality code of workplace" 


gen INSEE_COM=depr+ comr 
merge m:1 INSEE_COM using ${SOURCES}\GEOFLA_COMMUNE, keepusing(X_CENTROID Y_CENTROID SUPERFICIE)
drop if _m==2
drop _m
rename X_CENTROID xr
rename Y_CENTROID yr
rename SUPERFICIE Sr
label var xr "X-geo coord of residence (centroid of municip)"
label var yr "Y-geo coord of residence (centroid of municip)"
label var Sr "Superficie of residence municipality (hectar)"
rename INSEE_COM codegeor
label var codegeor "Municipality code of residence" 



gen dist=sqrt((yt-yr)*(yt-yr)+(xt-xr)*(xt-xr))/1000
label var dist "Commuting distance (in km)"
replace dist=(2/3)*sqrt((Sr*0.01)/3.14) if codegeor==codegeot & missing(codegeor)==0
replace dist=120 if dist>120 &dist!=.
gen log_dist=log(dist)

gen log_wage=log(wage)

gen log_wage_hourly=log(wage_hourly)

forvalues j=1986(1)1989 {
sum sbr if an==`j', d
sca p99_`j'=r(p99)
replace sbr=p99_`j' if sbr>p99_`j' &sbr!=. &an==`j'
sca drop p99_`j'

sum sbr if an==`j', d
sca p1_`j'=r(p1)
replace sbr=p1_`j' if sbr<p1_`j' &sbr!=. &an==`j'
sca drop p1_`j'
}

forvalues j=1991(1)2015 {
sum sbr if an==`j', d
sca p99_`j'=r(p99)
replace sbr=p99_`j' if sbr>p99_`j' &sbr!=. &an==`j'
sca drop p99_`j'

sum sbr if an==`j', d
sca p1_`j'=r(p1)
replace sbr=p1_`j' if sbr<p1_`j' &sbr!=. &an==`j'
sca drop p1_`j'
}

gen log_sbr=log(sbr)


drop if  apet2=="7820Z"
drop if  apen2=="7820Z"

drop if  apet=="745B"
drop if  apen=="745B"
save timeseries, replace 


****************************************************
* Aggregate raw time series graphs 
****************************************************

use timeseries, clear


gen sbr0=sbr if female==1
gen sbr1=sbr if female==0
gen wage_hourly0=wage_hourly if female==1
gen wage_hourly1=wage_hourly if female==0
gen dist0=dist if female==1
gen dist1=dist if female==0
gen C=1
gen F=female==1
gen H=female==0
collapse (sum) C H F  (mean) sbr* 	wage_hourly* dist* female age, by(an)

tsset an

label var C "Total nb of employment spells"
label var H "# male employment spells"
label var F "# female employment spells"

tsline H F

gen annual_earnings_gap=log(sbr0)-log(sbr1)

gen gap_wage_hourly=log(wage_hourly0)-log(wage_hourly1)

label var dist1 "Average male commute"
label var dist0 "Average female commute"

gen gap_dist=log(dist0)-log(dist1)


label var annual_earnings_gap "Annual earnings gap"
label var gap_wage_hourly "Hourly wage gap"
label var gap_dist "Commute gap"
label var an "Year"

replace gap_dist=. if an==1993|an==1994
replace gap_wage_hourly=. if an==1993|an==1994
tsline gap_dist gap_wage_hourly annual_earnings_gap if tin(1985,2015), /// 
	lcolor(navy red green) ///
	lpattern(dash solid longdash_dot) ///
	lwidth(medthick medthick medthick) ///
	title("Unconditional gender gaps""in commute and wage") ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	ylabel(-0.5(0.1)0) xlabel(1985(5)2015) 
graph export ${OUTPUT}\ts_gap_dist${NAME}.pdf, replace 
graph export ${OUTPUT}\ts_gap_dist${NAME}.svg, as(svg) replace 
graph export ${OUTPUT}\ts_gap_dist${NAME}.eps, as(eps) replace 

set scheme s2mono
tsline gap_dist gap_wage_hourly annual_earnings_gap if tin(1985,2015), /// 	lcolor(navy red green) ///
	lpattern(dash solid longdash_dot) ///
	lwidth(medthick medthick medthick) ///
	title("Unconditional gender gaps""in commute and wage") ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	ylabel(-0.5(0.1)0) xlabel(1985(5)2015) 
graph export ${OUTPUT}\ts_gap_dist${NAME}_bw.eps, as(eps) replace 


****************************************************
* Evolution of conditional gender gaps 
****************************************************

use timeseries, clear

gen CODGEO=codegeor
*sort depcom
merge m:1 CODGEO using ${SOURCES}\ZE2010, keepusing(ZE2010) 
drop if _m==2
drop CODGEO
drop _m
rename ZE2010 czr 
label var czr "Commuting zone of the residence"

gen CODGEO=codegeot
*sort depcom
merge m:1 CODGEO using ${SOURCES}\ZE2010, keepusing(ZE2010) 
drop if _m==2
drop CODGEO
drop _m
rename ZE2010 czt 
label var czt "Commuting zone of the workplace"


drop  depr dept  regn regr regt

count if missing(a38)
encode a38, gen(a38_)
replace a38_=0 if missing(a38_)
count if missing(a38_)


encode pcs4, gen(pcs4_)
replace pcs4_=0 if missing(pcs4_)
count if missing(pcs4_)

gen fulltime=ce=="C"

sort nninouv_ an 
by nninouv_: gen exp=sum(dp)
replace exp=exp/360
gen exp2=exp*exp

egen cz=group(czt)
replace cz=0 if missing(cz)


save timeseries_conditional, replace 

use timeseries_conditional, clear

forvalues j=1995(2)2015 {
capture drop female`j'
gen female`j'=female 

areg log_wage_hourly female`j' i.age exp exp2 fulltime i.a38_ i.cz  if an==`j', cluster(nninouv_) robust a(pcs4_)
capture drop _est_hourly_wage_gap`j'
estimates store hourly_wage_gap`j'
estimates save ${OUTPUT}hourly_wage_gap`j', replace

areg log_dist female`j' i.age exp exp2 fulltime i.a38_ i.cz  if an==`j', cluster(nninouv_) robust a(pcs4_)
capture drop _est_commute_gap`j'
estimates store commute_gap`j'
estimates save ${OUTPUT}commute_gap`j', replace

drop female`j'
}

/*
forvalues j=1995(2)2015 {
estimates restore ${OUTPUT}hourly_wage_gap`j'
estimates restore ${OUTPUT}commute_gap`j'
}
*/

coefplot (commute_gap*, mcolor(navy) ciopts(lc(navy)) msymbol(circle_hollow) ///
	keep(female*) label("Commute gap")) ///
	(hourly_wage_gap*, mcolor(red) ciopts(lc(red)) msymbol(circle) ///
	keep(female*) label("Hourly wage gap")), vertical  ylabel(-0.3(0.1)0) ///
	title("Conditional gender gaps" "in commute and hourly wage") ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	order( female1995 female1997 female1999  female2001  female2003  ///
	female2005  female2007  female2009 female2011  female2013  female2015) ///
	coeflabels( female1995="1995"  female1997="1997" female1999="1999"  female2001="2001"  female2003="2003"  ///
	female2005="2005"  female2007="2007"  female2009="2009" female2011="2011"  female2013="2013"  female2015="2015")
graph export ${OUTPUT}ts_conditional_gaps.pdf, replace 
graph export ${OUTPUT}ts_conditional_gaps.svg, as(svg) replace 
graph export ${OUTPUT}ts_conditional_gaps.eps, as(eps) replace 

set scheme s2mono
coefplot (commute_gap*, msymbol(circle_hollow) ///
	keep(female*) label("Commute gap")) ///
	(hourly_wage_gap*, msymbol(circle) ///
	keep(female*) label("Hourly wage gap")), vertical  ylabel(-0.3(0.1)0) ///
	title("Conditional gender gaps" "in commute and hourly wage") ///
	ytitle("log-difference women-men") ///
	graphregion( color(white)) ///
	order( female1995 female1997 female1999  female2001  female2003  ///
	female2005  female2007  female2009 female2011  female2013  female2015) ///
	coeflabels( female1995="1995"  female1997="1997" female1999="1999"  female2001="2001"  female2003="2003"  ///
	female2005="2005"  female2007="2007"  female2009="2009" female2011="2011"  female2013="2013"  female2015="2015")
*graph export ${OUTPUT}ts_conditional_gaps.pdf, replace 
graph export ${OUTPUT}ts_conditional_gaps_bw.eps, as(eps) replace 
	 
