* This dofile creates Appendix figure C5

* INPUT: ${SOURCES}paneldadsedp2010



clear all 


set matsize 10000
set maxvar 10000
set max_memory 11g

global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"


set more off, permanently




use ${SOURCES}paneldadsedp2010, clear
drop ita* etud* poids* an0* an1* mn0* mn1* jn0* jn1* dip_0* dip_1* dip_9* dip9 dip_7 dip_8 det* deg*
drop aem3 aem3 mem3 mem4 jem3 jem4
*keep if an>=2003
drop if filtre=="0"
drop filtre ape40 nnihc nnifict cda


drop if  apet2=="7820Z"
drop if  apen2=="7820Z"

drop if  apet=="745B"
drop if  apen=="745B"

gen female=sx=="0"

drop if missing(age)
keep if inrange(age,20,58) 

egen nninouv_=group(nninouv)


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

gen wage_daily=sbr/dp
replace wage_daily=14 if wage_daily<14 & missing(wage_daily)==0
replace wage_daily=300 if wage_daily>300 & missing(wage_daily)==0



*we drop oversea dept 
drop if inrange(substr(dept,1,2),"97","99")
drop if inrange(substr(depr,1,2),"97","99")
drop if substr(depr,1,2)=="2A" |substr(depr,1,2)=="2B" |substr(dept,1,2)=="2A" |substr(dept,1,2)=="2B" 
drop if substr(dept,1,2)=="9A" |substr(dept,1,2)=="9B" |substr(dept,1,2)=="9C" |substr(dept,1,2)=="9D" 
drop if substr(depr,1,2)=="9A" |substr(depr,1,2)=="9B" |substr(depr,1,2)=="9C" |substr(depr,1,2)=="9D" 

sort nninouv an sir
drop sir entpan entsir  sb   

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

replace pcs4=upper(pcs4)

gen log_wage=log(wage)

gen log_wage_hourly=log(wage_hourly)

gen log_wage_daily=log(wage_daily)


gen CODGEO=codegeor
merge m:1 CODGEO using ${SOURCES}\ZE2010, keepusing(ZE2010) 
drop if _m==2
drop CODGEO
drop _m
rename ZE2010 czr 
label var czr "Commuting zone of the residence"

gen CODGEO=codegeot
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

gen pcs3=substr(pcs4,1,3)
encode pcs3, gen(pcs3_)
replace pcs3_=0 if missing(pcs3_)
count if missing(pcs3_)
drop pcs3 pcs4

gen fulltime=ce=="C"

sort nninouv_ an 
by nninouv_: gen exp=sum(dp)
replace exp=exp/360
gen exp2=exp*exp

egen cz=group(czt)
replace cz=0 if missing(cz)


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
forvalues j=1(1)39{
gen female_agedummy`j'=female*agedummy`j'
}


foreach var in pcs3_ a38_ cz dip_tot {
cap drop missing_`var'
gen missing_`var'=`var'==0
}



*******************************************************************************
* Figure D5 panel a

global NAME="edp9310_age"


foreach var in log_wage {

reghdfe `var' ///
	agedummy2-agedummy39 female_agedummy1-female_agedummy39  ///
	single_withchild married_nochild married_withchild   ///
	c.exp c.exp2 i.dip_tot ///	
	fulltime   if inrange(age,20,58) & inrange(an,1993,2010), ///
	cluster(nninouv_) a(pcs3_ i.a38_#i.cz#i.an)

capture drop _est_`var'_age
estimates store `var'_age
estimates save ${OUTPUT}${NAME}`var'_age, replace

}
	

coefplot log_wage_age, vertical  ///
	title("Gender gaps in wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.2(0.05)0) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_agedummy*) ///
	coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_wage.pdf, replace 


*******************************************************************************
* Figure D5 panel b

global NAME="edp7692_age_daily"

foreach var in log_wage_daily {

reghdfe `var' ///
	agedummy2-agedummy39 female_agedummy1-female_agedummy39  ///
	single_withchild married_nochild married_withchild   ///
	c.exp c.exp2 i.dip_tot ///	
	fulltime   if inrange(age,20,58) & inrange(an,1976,1992), ///
	cluster(nninouv_) a(i.cz#i.an)

capture drop _est_`var'_age
estimates store `var'_age
estimates save ${OUTPUT}${NAME}`var'_age, replace

}
	
coefplot log_wage_daily_age, vertical  ///
	title("Gender gaps in wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.3(0.1)0) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_agedummy*) ///
	coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_wage.pdf, replace 

*******************************************************************************
* Figure D5 panel c

global NAME="edp9301_age_daily"

foreach var in log_wage_daily {

reghdfe `var' ///
	agedummy2-agedummy39 female_agedummy1-female_agedummy39  ///
	single_withchild married_nochild married_withchild   ///
	c.exp c.exp2 i.dip_tot ///	
	fulltime   if inrange(age,20,58) & inrange(an,1993,2001), ///
	cluster(nninouv_) a(i.cz#i.an)

capture drop _est_`var'_age
estimates store `var'_age
estimates save ${OUTPUT}${NAME}`var'_age, replace

}
	
coefplot log_wage_daily_age, vertical  ///
	title("Gender gaps in wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.3(0.1)0) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_agedummy*) ///
	coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_wage.pdf, replace 


*******************************************************************************
* Figure D5 panel d

global NAME="edp0210_age_daily"

foreach var in log_wage_daily {

reghdfe `var' ///
	agedummy2-agedummy39 female_agedummy1-female_agedummy39  ///
	single_withchild married_nochild married_withchild   ///
	c.exp c.exp2 i.dip_tot ///	
	fulltime   if inrange(age,20,58) & inrange(an,2002,2010), ///
	cluster(nninouv_) a(i.cz#i.an)

capture drop _est_`var'_age
estimates store `var'_age
estimates save ${OUTPUT}${NAME}`var'_age, replace

}
	
coefplot log_wage_daily_age, vertical  ///
	title("Gender gaps in wages") subtitle("By age")  ///	title("Gender gap in FTE monthly wages")  ///
	xtitle("Age (in years)") yline(0) ylabel(-0.3(0.1)0) ///
	ytitle("Gender gap (log difference)") ///
	keep(female_agedummy*) ///
	coeflabels( female_agedummy1="20" female_agedummy2=" " female_agedummy3=" " female_agedummy4=" " female_agedummy5=" " female_agedummy6=" " female_agedummy7=" " ///
	female_agedummy8=" " female_agedummy9=" " female_agedummy10=" " female_agedummy11="30" female_agedummy12=" " female_agedummy13=" " female_agedummy14=" " ///
	female_agedummy15=" " female_agedummy16=" " female_agedummy17=" " female_agedummy18=" " female_agedummy19=" " female_agedummy20=" " female_agedummy21="40" ///
	female_agedummy22=" " female_agedummy23=" " female_agedummy24=" " female_agedummy25=" " female_agedummy26=" " female_agedummy27=" " female_agedummy28=" " ///
	female_agedummy29=" " female_agedummy30=" " female_agedummy31="50" female_agedummy32=" " female_agedummy33=" " female_agedummy34=" " female_agedummy35=" " ///
		female_agedummy36=" " female_agedummy37=" " female_agedummy38=" " female_agedummy39=" " )
graph export ${OUTPUT}\${NAME}_log_wage.pdf, replace 


	
