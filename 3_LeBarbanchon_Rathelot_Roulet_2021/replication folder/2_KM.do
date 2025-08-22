*********************************************************************
*** 2_KM.do creates the results of Table IV using data from Krueger and Mueller (2016) 
* It is directly inscpired from the do-file ver4public_rw_tables_3_4_5_6.do 
* downloadable on the journal website of AEJ: Economic Policy
* https://www.aeaweb.org/articles?id=10.1257/pol.20140211 

*********************************************************************

clear
clear matrix
set more off

set matsize 1000

* !!! PLEASE SPECIFY !!! the directory where the data is stored:
local njdir="d:\datax\njpublic\"
local njdir="E:\Dropbox\ResW_followup\data\KM\AEJPol-2014-0211_DATA- 05212015\Stata codes and data\"
local njdir="D:\Dropbox\ResW_followup\data\KM\AEJPol-2014-0211_DATA- 05212015\Stata codes and data\"

* !!! PLEASE SPECIFY !!! the directory where to store results:
local resultsdir="c:\Users\am3747\Dropbox\RESULTS\reswage\"
local resultsdir="E:\Dropbox\ResW_followup\data\KM\AEJPol-2014-0211_DATA- 05212015\output\"
local resultsdir="D:\Dropbox\ResW_followup\data\KM\AEJPol-2014-0211_DATA- 05212015\output\"

* load file
use "`njdir'njsurvey.dta", clear

count
unique caseid week
xtset caseid week	

*br caseid week


* --- define additional variables used in regressions --- *

* generate dummies for the unit in which the reservation wage and offered wage is reported
tab q7a2, gen(q7a2_)

gen nchild=b5
replace sevpayamt=0 if missing(sevpayamt)==1
gen spouse_job=e41==1
gen lrescommute=log(rescommute)


global SAMP="week==1 & insample_wrkacc" 
*global SAMP="insample_wrkacc" 
cap erase `resultsdir'K_M.txt 
cap erase `resultsdir'K_M.tex 

reg lreswage_hrly female /// 		female_children female_married female_partner ///
	i.age_d i.school exper exper2 married partner i.nchild ///
	ethnic_hisp ethnic_na r_black r_asoth r_na ///
	i.b7 spouse_job saving i.e35 liq ///
	ftjob jten jtensq udur_self ///
	sevpay sevpayamt ///
	i.b2b patient ///
	q7a2_* [pw=curwkwgt] if ${SAMP}, robust

sum reswage_hrly [aw=curwkwgt] if ${SAMP} & female==0	
sca CM=r(mean)	
	
outreg2 using `resultsdir'K_M.tex, append label nocons ///
	keep(female) ///
	addstat("Male mean",scalar(CM))
	
reg lrescommute female /// 	female_children female_married female_partner ///
	i.age_d i.school exper exper2 married partner i.nchild ///
	ethnic_hisp ethnic_na r_black r_asoth r_na ///
	i.b7 spouse_job saving i.e35 liq ///
	ftjob jten jtensq udur_self ///
	sevpay sevpayamt ///
	i.b2b patient ///
	q7a2_* [pw=curwkwgt] if ${SAMP}, robust

sum rescommute [aw=curwkwgt] if ${SAMP} & female==0	
sca CM=r(mean)		
	
outreg2 using `resultsdir'K_M.tex, append label nocons ///
	keep(female) ///
	addstat("Male mean",scalar(CM))
	