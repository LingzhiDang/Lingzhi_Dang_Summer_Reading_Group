* This dofile creates the edp data used for panel b and d of Figure 3, 4 and C6

* INPUT:  ${SOURCES}paneldadsedp2010

* OUTPUT : edp_data

clear all

set matsize 1000
set maxvar 10000
set max_memory 11g


global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

********************
* Data preparation
*******************


use ${SOURCES}paneldadsedp2010, clear
drop ita* etud* poids* an0* an1* mn0* mn1* jn0* jn1* dip_0* dip_1* dip_9* dip9 dip_7 dip_8 det* deg*
drop aem3 aem3 mem3 mem4 jem3 jem4
keep if an>=2003
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


save edp_data, replace 
