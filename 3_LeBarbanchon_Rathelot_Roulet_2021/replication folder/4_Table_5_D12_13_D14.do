* This dofile produces Table 5 and Table D12, D13, D14

* It first produces the relevant dataset, with IPW for each observation 

* It then estimates the slope of the indifference curves separately for men and women
* It yields as output a vector of 6 columns, the first 3 use the minimisation criterion where the distance to the indifference curve
*  is not squared but taken in absolute value  (first column for men, second for women and third for the gender gap)
* while the last 3 are using our preferred criterion where the distance is squared (c4 for men, c5 for women and c6 for the gender gap)

* standard errors are obtained by running the bootrapped programs
* In order to get the estimates for the various columns just switch manually the filters line 160 to 195

* INPUT: 
* basedetravail_final_qje from 1_construction_main_dataset.do
* vac_occ_minW.dta from 0_prepare_m0

* OUTPUT :
* indiff_curve_dataset


clear all
global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

set matsize 1000
set maxvar 10000
set maxvar 32000
set max_memory 11g


use basedetravail_final_qje, clear


merge m:1 rome using vac_occ_minW
keep if _m==3
drop _m
label var occ_minW "Share of job ads at the minW within worker occupation"

*count if missing(occ_minW)
sum occ_minW, d
cap drop samp_occminW
gen samp_occminW=occ_minW>=r(mean) if missing(occ_minW)==0
label var samp_occminW "Worker searches occupation with high share of minèw_wage ads" 
tab samp_occminW

keep if found_a_job

cap drop paris
gen paris_region=substr(depcom,1,2)=="75"|substr(depcom,1,2)=="92"|substr(depcom,1,2)=="93" |substr(depcom,1,2)=="95"  ///
|substr(depcom,1,2)=="94"|substr(depcom,1,2)=="77" |substr(depcom,1,2)=="78" |substr(depcom,1,2)=="91" 
label var paris "Ile de France"

gen samp_resWminW=resWcorr>1.05*minW
* add another definition of minW workers 
encode rome, gen(rome_)
gen jobtitle=rome+"_"+romeapl
encode jobtitle, gen(jobtitle_)

cap drop test
bys jobtitle: egen test=mean(samp_resWminW)
bys jobtitle: egen test1=median(pastW_minW)
gen below_median=pastW_minW>test1

bys jobtitle below_median: egen test2=mean(samp_resWminW)

gen samp_romeminW=test2>0.5

drop  test test1 test2 below_median

save indiff_curve_dataset.dta, replace



********************************************************************************
* 1. compute propensity score
* p(X)/(1-p(X))

use indiff_curve_dataset.dta, clear

global occE0="fapE0"

sum education
cap drop education2
gen education2=education*education

logit female /// 
	married child ///
	age age2 exper exper2 education education2  ///
	log_PBD /// mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi ///
	i.${occE0}_ /// 	
	i.pastW_bins log_distanceE0 ///
	i.a38E0_ i.cz i.period_quarter 

cap drop p_X
predict p_X
count if missing(p_X)
sum p_X if female==0, d
replace p_X=0.879 if p_X>0.879 & female==0
label var p_X "Female probability weights"
	
cap drop pW	
gen 	pW=1 
replace pW=p_X/(1-p_X) if female==0
label var pW "Balancing weights" 	
*count if missing(W)
*gen W=p_X/(1-p_X) 
sum pW, d
sum pW if female==0
*replace pW=. if pW>7.26


logit female /// 
	married child ///
	age age2 exper exper2 education education2  /// log_PBD /// mobunit_tps i.salunit_ ///	prev_fulltime prev_cdi ///	i.${occE0}_ /// 		i.pastW_bins log_distanceE0 ///	i.a38E0_ ///
	i.cz i.period_quarter 

cap drop p_Xwo
predict p_Xwo
count if missing(p_Xwo)
sum p_Xwo if female==0, d
replace p_Xwo=0.71 if p_Xwo>0.71 & female==0
label var p_Xwo "Female probability weights (wo past work controls)"
	
cap drop pWwo	
gen 	pWwo=1 
replace pWwo=p_Xwo/(1-p_Xwo) if female==0
label var pWwo "Balancing weights (with past work controls)" 	
*count if missing(W)
*gen W=p_X/(1-p_X) 
sum pWwo, d
sum pWwo if female==0


save indiff_curve_dataset.dta, replace


**********************************************************************************************************************************************************************************************
* Table 5 and D13 and D14 (except column  6)

* we create the matrix where estimation results of table 5 are stored
mat Tab5=(.,.,.,.)
* column number, female elast, male elas, gap
mat colnames Tab5= colnumber elas_female elas_male elas_gap

* we create the matrix where column 1 of table D14 is stored
mat TabD14=(.,.,.,.)
* column number, female elast, male elas, gap
mat colnames TabD14= colnumber elas_female elas_male elas_gap


* This code produces both estimates of Table 5 as well as some robustness 
* you need to rerun from here for every estimate

local samp_resW=1
* This is switched to 1 except for column 2,3 and 4 of Table D13

local samp_occminW=0
* you have to switch this to 1 for column 2 of Table D13

local samp_resW_=0
* you have to switch this to 1 for column 3 of Table D13

local samp_woIPW=0
* you have to switch this to 1 for column 1 of Table D14

local samp_KM=0
* you have to switch this to 1 for column 2 of Table D14

local samp_dev_mobdist=0
* you have to switch this to 1 for column 3 of Table D14

local samp_FT=0
* you have to switch this to 1 for column 5 of Table D14


* For column 4 of table D13 all of the above are switched to 0

use indiff_curve_dataset.dta, clear

* To get columns 2 through 5 of Table 5 you need to turn on the relevant line below
local col="1"
*local col="2"
*keep if married==0&child==0
*local col="3"
*keep if married==1&child==0
*local col="4"
*keep if married==0&child==1
*local col="5"
*keep if married==1&child==1

global col="`col'"

if `samp_KM'==1 {
	keep if mobunit=="KM"
	}
if `samp_resW'==1 {
	keep if resWcorr>1.05*minW
	}
if `samp_resW_'==1 {
	keep if resWcorr>1.15*minW
	}
if `samp_FT'==1 {
	keep if prev_fulltime==1
	}
if `samp_dev_mobdist'==1 {
	gen dev=log_distanceE1-log_mobdist
	drop if dev<-1.5
	drop if dev>1.5
	}
if `samp_occminW'==1 {
	drop if samp_romeminW==0  
	}
if `samp_woIPW'==1 {
	replace pW=1
	}
*sum pW
	
drop if missing(distanceE1)
gen log_postWcorr=log(postWcorr)


foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0(0.001)0.2 {

sca slope=`slope'


capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)

cap drop hit
	gen hit=pW*(log_postWcorr>logW)

qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW


cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW


*sum proj, d
qui total proj
*return list
mat T=r(table)
*mat list T
sca proj=T[1,1]
*sca list proj

*sum proj, d
qui total proj2
*return list
mat T=r(table)
*mat list T
sca proj2=T[1,1]
*sca list proj

mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}

mat list M0
mat list M1

cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
sum slope if dist_women==mindist_women
sca slope_1=r(mean)

sca diff_slope=scalar(slope_1)-scalar(slope_2)

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)


mat slope_elas0_${col}=(slope_1,slope_2,diff_slope,slope2_1,slope2_2,diff_slope2)
mat list slope_elas0_${col}

if `samp_woIPW'==0 {
	mat Tab5=Tab5 \ (${col},slope2_1,slope2_2,diff_slope2)
	mat list Tab5
	matsave Tab5, replace saving path(${OUTPUT})
}

if `samp_woIPW'==1 {
	mat TabD14=TabD14 \ (${col},slope2_1,slope2_2,diff_slope2)
	mat list TabD14
	matsave TabD14, replace saving path(${OUTPUT})
}


capture program drop myboot
program define myboot, rclass 



local samp_resW=1
* This is switched to 1 except for column 2 and 4 of Table D13

local samp_occminW=0
* you have to switch this to 1 for column 2 of Table D13

local samp_resW_=0
* you have to switch this to 1 for column 3 of Table D13

local samp_woIPW=0
* you have to switch this to 1 for column 1 of Table D14

local samp_KM=0
* you have to switch this to 1 for column 2 of Table D14

local samp_dev_mobdist=0
* you have to switch this to 1 for column 3 of Table D14

local samp_FT=0
* you have to switch this to 1 for column 5 of Table D14


* For column 4 of table D13 all of the above are switched to 0

use indiff_curve_dataset.dta, clear

* To get columns 2 through 5 of Table 6 you need to turn on the relevant line below
*keep if married==0&child==0
*keep if married==1&child==0
*keep if married==0&child==1
*keep if married==1&child==1


if `samp_KM'==1 {
	keep if mobunit=="KM"
	}
if `samp_resW'==1 {
	keep if resWcorr>1.05*minW
	}
if `samp_resW_'==1 {
	keep if resWcorr>1.15*minW
	}
if `samp_FT'==1 {
	keep if prev_fulltime==1
	}
if `samp_dev_mobdist'==1 {
	gen dev=log_distanceE1-log_mobdist
	drop if dev<-1.5
	drop if dev>1.5
	}
if `samp_occminW'==1 {
	drop if samp_romeminW  
	}
if `samp_woIPW'==1 {
	replace pW=1
	}


drop if missing(distanceE1)
gen log_postWcorr=log(postWcorr)

bsample

foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'


forvalues slope=0(0.001)0.2 {
sca slope=`slope'

cap drop W
gen W=resWcorr+`slope'*(distanceE1-mobdist)
capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)

cap drop hit
gen hit=pW*(log_postWcorr>logW)
qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW

cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW



qui total proj

mat T=r(table)

sca proj=T[1,1]



qui total proj2

mat T=r(table)

sca proj2=T[1,1]


mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}


mat list M0
mat list M1
cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)

return scalar slope_2 =slope_2

sum slope if dist_women==mindist_women
sca slope_1=r(mean)
return scalar slope_1 =slope_1

sca diff_slope=scalar(slope_1)-scalar(slope_2)
return scalar diff_slope=diff_slope

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
return scalar slope2_2 =slope2_2

sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)
return scalar slope2_1 =slope2_1

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)
return scalar diff_slope2=diff_slope2


end

myboot

simulate slope_1=r(slope_1) slope_2=r(slope_2) diff_slope=r(diff_slope) ///
	slope2_1=r(slope2_1) slope2_2=r(slope2_2) diff_slope2=r(diff_slope2), ///
	reps(100) seed(5678) saving(slope_${col}, replace): myboot
	
bstat using slope_${col}, stat(slope_elas0_${col}) n(37550)


use ${OUTPUT}Tab5, clear
drop _row
drop if missing(col)
save ${OUTPUT}Tab5, replace

use ${OUTPUT}TabD14, clear
drop _row
drop if missing(col)
save ${OUTPUT}TabD14, replace

pause 
***********************************************************************************************************************************************************************************************************************
* Robustness 
* column 6 of table D14
************************


use indiff_curve_dataset.dta, clear

set seed 12345
gen norm_postW=rnormal(0,30)
gen postW_with_bruit=postWcorr+norm_postW

gen norm_dist=rnormal(0,1.5)
gen distE1_with_bruit=distanceE1+norm_dist


gen norm_resW=rnormal(0,30)
gen resW_with_bruit=resWcorr+norm_resW

gen norm_mobdist=rnormal(0,1.5)
gen mobdist_with_bruit=mobdist+norm_mobdist

save indif_with_bruit.dta, replace 

local samp_resW=1

use indif_with_bruit.dta, clear


drop distanceE1   log_distanceE1
drop postWcorr 

rename distE1_with_bruit distanceE1
gen log_distanceE1=log(distanceE1)

rename postW_with_bruit postWcorr
gen log_postWcorr=log(postWcorr)

drop mobdist   log_mobdist 
drop resWcorr log_resWcorr

rename mobdist_with_bruit mobdist
gen log_mobdist=log(mobdist)
rename resW_with_bruit resWcorr
gen log_resWcorr=log(resWcorr)


if `samp_resW'==1 {
	keep if resWcorr>1.05*minW
	}

		
drop if missing(distanceE1)

 

foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0(0.001)0.2 {


sca slope=`slope'


capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)


cap drop hit
gen hit=pW*(log_postWcorr>logW)



qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW


cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW


qui total proj

mat T=r(table)

sca proj=T[1,1]



qui total proj2

mat T=r(table)

sca proj2=T[1,1]


mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}

mat list M0
mat list M1

cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
sum slope if dist_women==mindist_women
sca slope_1=r(mean)

sca diff_slope=scalar(slope_1)-scalar(slope_2)

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)


mat slope_elas0_${col}=(slope_1,slope_2,diff_slope,slope2_1,slope2_2,diff_slope2)
mat list slope_elas0_${col}


capture program drop myboot
program define myboot, rclass 

local samp_resW=1

use indif_with_bruit.dta, clear


drop distanceE1   log_distanceE1
drop postWcorr 

rename distE1_with_bruit distanceE1
gen log_distanceE1=log(distanceE1)

rename postW_with_bruit postWcorr
gen log_postWcorr=log(postWcorr)

drop mobdist   log_mobdist 
drop resWcorr log_resWcorr

rename mobdist_with_bruit mobdist
gen log_mobdist=log(mobdist)
rename resW_with_bruit resWcorr
gen log_resWcorr=log(resWcorr)

if `samp_resW'==1 {
	keep if resWcorr>1.05*minW
	}

drop if missing(distanceE1)

bsample

foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0(0.001)0.2 {
sca slope=`slope'

cap drop W
gen W=resWcorr+`slope'*(distanceE1-mobdist)
capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)

cap drop hit
gen hit=pW*(log_postWcorr>logW)
qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW

cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW



qui total proj

mat T=r(table)
sca proj=T[1,1]


qui total proj2

mat T=r(table)

sca proj2=T[1,1]


mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}


mat list M0
mat list M1
cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
return scalar slope_2 =slope_2

sum slope if dist_women==mindist_women
sca slope_1=r(mean)
return scalar slope_1 =slope_1

sca diff_slope=scalar(slope_1)-scalar(slope_2)
return scalar diff_slope=diff_slope

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
return scalar slope2_2 =slope2_2

sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)
return scalar slope2_1 =slope2_1

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)
return scalar diff_slope2=diff_slope2


end

*myboot

simulate slope_1=r(slope_1) slope_2=r(slope_2) diff_slope=r(diff_slope) ///
	slope2_1=r(slope2_1) slope2_2=r(slope2_2) diff_slope2=r(diff_slope2), ///
	reps(50) seed(5678) saving(slope_with_bruit_${col}, replace): myboot
	
bstat using slope_with_bruit_${col}, stat(slope_elas0_${col}) n(37550)




***********************
* Table D12
* Paris

global col="p"

local samp_resW=1

use indiff_curve_dataset.dta, clear

keep if paris==1


if `samp_resW'==1 {
	keep if resWcorr>1.05*minW
	}
		
drop if missing(distanceE1)
gen log_postWcorr=log(postWcorr)


foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0.1(0.001)0.35 {

sca slope=`slope'


capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)


cap drop hit
gen hit=pW*(log_postWcorr>logW)


qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW


cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW

qui total proj
mat T=r(table)
sca proj=T[1,1]

qui total proj2
mat T=r(table)
sca proj2=T[1,1]

mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}

mat list M0
mat list M1

cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
sum slope if dist_women==mindist_women
sca slope_1=r(mean)

sca diff_slope=scalar(slope_1)-scalar(slope_2)

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)


mat slope_elas0_${col}=(slope_1,slope_2,diff_slope,slope2_1,slope2_2,diff_slope2)
mat colnames slope_elas0_${col} = slopeWomenAbsDist slopeMenAbsDist GenderSlopeGapAbsDist slopeWomenSqDist slopeMenSqDist GenderSlopeGapSqDist 
mat list slope_elas0_${col}



capture program drop myboot
program define myboot, rclass 


use indiff_curve_dataset.dta, clear

keep if resWcorr>1.05*minW

keep if paris==1

drop if missing(distanceE1)
gen log_postWcorr=log(postWcorr)

bsample

foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0.1(0.001)0.35 {
sca slope=`slope'

cap drop W
gen W=resWcorr+`slope'*(distanceE1-mobdist)
capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)

cap drop hit
gen hit=pW*(log_postWcorr>logW)
qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW

cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW


qui total proj
mat T=r(table)
sca proj=T[1,1]

qui total proj2
mat T=r(table)
sca proj2=T[1,1]

mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}


mat list M0
mat list M1
cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
return scalar slope_2 =slope_2

sum slope if dist_women==mindist_women
sca slope_1=r(mean)
return scalar slope_1 =slope_1

sca diff_slope=scalar(slope_1)-scalar(slope_2)
return scalar diff_slope=diff_slope

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
return scalar slope2_2 =slope2_2

sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)
return scalar slope2_1 =slope2_1

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)
return scalar diff_slope2=diff_slope2


end

*myboot

simulate slope_1=r(slope_1) slope_2=r(slope_2) diff_slope=r(diff_slope) ///
	slope2_1=r(slope2_1) slope2_2=r(slope2_2) diff_slope2=r(diff_slope2), ///
	reps(100) seed(5678) saving(slope_elas_${col}, replace): myboot
	
bstat using slope_elas_${col}, stat(slope_elas0_${col}) n(45601)



**************************************
* Table D12 column 3
* france excluding paris

global col="np"

local samp_resW=1

use indiff_curve_dataset.dta, clear

keep if paris==0

if `samp_resW'==1 {
	keep if resWcorr>1.05*minW
	}

		
drop if missing(distanceE1)
gen log_postWcorr=log(postWcorr)

tab female if resWcorr>1.05*minW

foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0(0.001)0.2 {

sca slope=`slope'

capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)


cap drop hit
gen hit=pW*(log_postWcorr>logW)


qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW


cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW


qui total proj
mat T=r(table)
sca proj=T[1,1]

qui total proj2
mat T=r(table)
sca proj2=T[1,1]

mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}

mat list M0
mat list M1

cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
sum slope if dist_women==mindist_women
sca slope_1=r(mean)

sca diff_slope=scalar(slope_1)-scalar(slope_2)

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)


mat slope_elas0_${col}=(slope_1,slope_2,diff_slope,slope2_1,slope2_2,diff_slope2)
mat colnames slope_elas0_${col} = slopeWomenAbsDist slopeMenAbsDist GenderSlopeGapAbsDist slopeWomenSqDist slopeMenSqDist GenderSlopeGapSqDist 
mat list slope_elas0_${col}



capture program drop myboot
program define myboot, rclass 


use indiff_curve_dataset.dta, clear

keep if resWcorr>1.05*minW

keep if paris==0

drop if missing(distanceE1)
gen log_postWcorr=log(postWcorr)

bsample

foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0(0.001)0.2 {
sca slope=`slope'

cap drop W
gen W=resWcorr+`slope'*(distanceE1-mobdist)
capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)

cap drop hit
gen hit=pW*(log_postWcorr>logW)
qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pW*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW

cap drop proj2
gen proj2=.
replace proj2=pW*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW


qui total proj
mat T=r(table)
sca proj=T[1,1]

qui total proj2
mat T=r(table)
sca proj2=T[1,1]

mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}


mat list M0
mat list M1
cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
return scalar slope_2 =slope_2

sum slope if dist_women==mindist_women
sca slope_1=r(mean)
return scalar slope_1 =slope_1

sca diff_slope=scalar(slope_1)-scalar(slope_2)
return scalar diff_slope=diff_slope

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
return scalar slope2_2 =slope2_2

sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)
return scalar slope2_1 =slope2_1

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)
return scalar diff_slope2=diff_slope2


end

*myboot

simulate slope_1=r(slope_1) slope_2=r(slope_2) diff_slope=r(diff_slope) ///
	slope2_1=r(slope2_1) slope2_2=r(slope2_2) diff_slope2=r(diff_slope2), ///
	reps(100) seed(5678) saving(slope_elas_${col}, replace): myboot
	
bstat using slope_elas_${col}, stat(slope_elas0_${col}) n(45601)








*****************************************************************************
* creates the estimates of alpha when IPW is done without including the characteristics of the previous job 



mat Tabwo=(.,.,.,.)
* column number, female elast, male elas, gap
mat colnames Tabwo= colnumber elas_female elas_male elas_gap



local samp_resW=1


use indiff_curve_dataset.dta, clear

local col="1"
global col="`col'"

if `samp_KM'==1 {
	keep if mobunit=="KM"
	}
if `samp_resW'==1 {
	keep if resWcorr>1.05*minW
	}
if `samp_resW_'==1 {
	keep if resWcorr>1.15*minW
	}
if `samp_FT'==1 {
	keep if prev_fulltime==1
	}
if `samp_dev_mobdist'==1 {
	gen dev=log_distanceE1-log_mobdist
	drop if dev<-1.5
	drop if dev>1.5
	}
if `samp_occminW'==1 {
	drop if samp_romeminW==0  
	}

	
drop if missing(distanceE1)
gen log_postWcorr=log(postWcorr)


foreach female in 0 1 {
mat M`female'=(.,.,.,.)
preserve
keep if female==`female'

forvalues slope=0(0.001)0.2 {

sca slope=`slope'


capture drop logW
gen logW=log_resWcorr+`slope'*(log_distanceE1-log_mobdist)

cap drop hit
	gen hit=pWwo*(log_postWcorr>logW)

qui sum hit
sca hit=r(mean)

cap drop proj
gen proj=.
replace proj=pWwo*abs(log_postWcorr-logW)/sqrt(1+slope^2) if log_postWcorr<logW


cap drop proj2
gen proj2=.
replace proj2=pWwo*((log_postWcorr-logW)/sqrt(1+slope^2))^2 if log_postWcorr<logW


*sum proj, d
qui total proj
*return list
mat T=r(table)
*mat list T
sca proj=T[1,1]
*sca list proj

*sum proj, d
qui total proj2
*return list
mat T=r(table)
*mat list T
sca proj2=T[1,1]
*sca list proj

mat M`female'= M`female' \ (scalar(slope),scalar(hit),scalar(proj),scalar(proj2))
}
restore
}

mat list M0
mat list M1

cap drop M0*
cap drop M1*
svmat M0 
svmat M1
cap drop slope slope_
cap drop share_ofhit_men share_ofhit_women
rename M01 slope
rename M02 share_ofhit_men
rename M03 dist_men
rename M04 dist2_men
rename M11 slope_
rename M12 share_ofhit_women
rename M13 dist_women
rename M14 dist2_women

cap drop mindist_men mindist_women
egen mindist_women=min(dist_women)
egen mindist_men  =min(dist_men)
sum slope if dist_men  ==mindist_men
sca slope_2=r(mean)
sum slope if dist_women==mindist_women
sca slope_1=r(mean)

sca diff_slope=scalar(slope_1)-scalar(slope_2)

cap drop mindist2_men mindist2_women
egen mindist2_women=min(dist2_women)
egen mindist2_men  =min(dist2_men)
sum slope if dist2_men  ==mindist2_men
sca slope2_2=r(mean)
sum slope if dist2_women==mindist2_women
sca slope2_1=r(mean)

sca diff_slope2=scalar(slope2_1)-scalar(slope2_2)


mat slope_elas0_${col}=(slope_1,slope_2,diff_slope,slope2_1,slope2_2,diff_slope2)
mat list slope_elas0_${col}

mat Tabwo=Tabwo \ (${col},slope2_1,slope2_2,diff_slope2)
mat list Tabwo
matsave Tabwo, replace saving path(${OUTPUT})




