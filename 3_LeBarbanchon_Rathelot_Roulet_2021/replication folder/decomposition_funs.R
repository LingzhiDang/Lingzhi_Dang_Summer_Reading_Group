##
## decomposition_fun.R
## 
## Auxiliary functions for estimation and decomposition
## 
## 24 Sept 2020
## 
## Le Barbanchon, Roulet, Rathelot
## 

FG_cal_fun <- function(db){

	EVwh_fun <- function(db,sh_w,sc_w,sh_h,sc_h){
		int_wh <- function(w,h) {
			fw(w,sh_w,sc_w)*gh(h,sh_h,sc_h)}
		norm_h <- function(h) {
			integrate(Vectorize(function(w) int_wh(w,h)),
				max(wmin, db$phi0-db$alp*h),wmax)$value
		}
		norm <- integrate(Vectorize(norm_h), 0, hmax)$value
		exp_w <- function(h) {
			integrate(Vectorize(function(w) w*int_wh(w,h)),
				max(wmin, db$phi0-db$alp*h),wmax)$value
		}
		Ew <- integrate(Vectorize(exp_w), 0, hmax)$value/norm
		var_w <- function(h) {
			integrate(Vectorize(function(w) (w-Ew)^2*int_wh(w,h)),
				max(wmin, db$phi0-db$alp*h),wmax)$value
		}
		Vw <- integrate(Vectorize(var_w), 0, hmax)$value/norm	
		exp_h <- function(h) {
			integrate(Vectorize(function(w) h*int_wh(w,h)),
				max(wmin, db$phi0-db$alp*h),wmax)$value
		}
		Eh <- integrate(Vectorize(exp_h), 0, hmax)$value/norm
		var_h <- function(h) {
			integrate(Vectorize(function(w) (h-Eh)^2*int_wh(w,h)),
				max(wmin, db$phi0-db$alp*h),wmax)$value
		}
		Vh <- integrate(Vectorize(var_h), 0, hmax)$value/norm			
		c(Ew,Vw,Eh,Vh,norm)
	}

	loss_fun <- function(sh_w,sc_w,sh_h,sc_h){
		EVwh <- EVwh_fun(db,sh_w,sc_w,sh_h,sc_h)
		((EVwh[1]-db$wn_mean)^2)/(db$wn_var) + 
		((EVwh[2]-db$wn_var)^2)/(db$wn_kur) + 
		((EVwh[3]-db$hn_mean)^2)/(db$hn_var) + 
		((EVwh[4]-db$hn_var)^2)/(db$hn_kur)
	}

	resoptim <- optim(c(db$sh_w0,db$sc_w0,db$sh_h0,db$sc_h0),
	function(v){loss_fun(v[1],v[2],v[3],v[4])}, 
	lower = c(db$sh_w_lb,db$sc_w_lb,db$sh_h_lb,db$sc_h_lb), 
	upper = c(db$sh_w_ub,db$sc_w_ub,db$sh_h_ub,db$sc_h_ub),
	method = "L-BFGS-B")

	## Add sh_h and sc_h in data
	db %>% mutate(
		sh_w=resoptim$par[1], sc_w=resoptim$par[2], 
		sh_h=resoptim$par[3], sc_h=resoptim$par[4])

}

## Calibration: find lam
## Known: wmin, phi0, alp, hn, wn, sh_w, sc_w, delg, jfr
## Search: lam
lam_cal_fun <- function(db){
	intjfr_wh <- function(w,h) {
		fw(w,db$sh_w,db$sc_w)*gh(h, db$sh_h, db$sc_h)}
	intjfr_h <- function(h) {
		integrate(Vectorize(function(w) intjfr_wh(w,h)),
			max(wmin,db$phi0-db$alp*h),wmax, rel.tol=1e-7)$value
	}
	norm_h <- function(h) {
		integrate(Vectorize(function(w) intjfr_wh(w,h)),
			wmin,wmax, rel.tol=1e-7)$value
	}
	db %>% mutate(
		lam=db$jfr/integrate(Vectorize(intjfr_h), 0, hmax)$value*
		integrate(Vectorize(norm_h), 0, hmax)$value
	)
}

## Calibration: find b
## Known: wmin, phi0, alp, hn, wn, sh_w, sc_w, delg, lam
## Search: b
b_cal_fun <- function(db){		
	int_wh <- function(w,h) {
		fw(w,db$sh_w,db$sc_w)*gh(h, db$sh_h, db$sc_h)}
	int_h <- function(h) {
		integrate(Vectorize(function(w) 
			{max(0,w+db$alp*h-db$phi0)*int_wh(w,h)}),
			max(wmin,db$phi0-db$alp*h),wmax)$value
	}
	norm_h <- function(h) {
		integrate(Vectorize(function(w) int_wh(w,h)),
			wmin,wmax)$value
	}

	b <- db$phi0 - db$lam/(rho+db$q)*
	integrate(Vectorize(int_h), 0, hmax)$value/
	integrate(Vectorize(norm_h), 0, hmax)$value
	db %>% mutate(b=b)
}
## Quicker way: ONLY WHEN delf, delg are calibrated to wn, hn
b_cal_quick_fun <- function(db){
	db %>% mutate(b= db$phi0 - db$jfr/(rho+db$q)*
	(db$wn-db$phis+db$alp*(db$hn-db$hs)) )
}

## 2. Solving functions

## In this series of functions, we assume that we know
## q, wmin, sh_w, sc_w, delg, alp, lam, b
## And we search: 
## phi0, hs, phis, hn, phin

## Solve: Reservation utility as a function of lambda 
phi0_fun <- function(db){
	eqrVu_fun <- function(rVu){
		int_wh <- function(w,h) {
			fw(w,db$sh_w,db$sc_w)*gh(h, db$sh_h, db$sc_h)}
		int_h <- function(h) {
			integrate(Vectorize(function(w) 
				{max(0,w+db$alp*h-rVu)*int_wh(w,h)}),
				max(wmin,rVu-db$alp*h),wmax)$value
		}
		norm_h <- function(h) {
			integrate(Vectorize(function(w) int_wh(w,h)),
				wmin,wmax)$value
		}

		-rVu + db$b + db$lam/(rho+db$q)*
			integrate(Vectorize(int_h), 0, hmax)$value/
			integrate(Vectorize(norm_h), 0, hmax)$value
	}

	## Search between plausible values for the utility
	umax <- wmax*.99
	phi0_s <-uniroot(function(rVu){eqrVu_fun(rVu)},c(-1, umax))$root
	db %>% mutate(phi0_s=phi0_s)
}

## Declared h and phi as a function of indiff curve and job densities
hs_phis_fun <- function(db){
	int_h <- function(hh) {
		hh * fw(max(wmin, db$phi0_s-db$alp*hh),db$sh_w,db$sc_w)*
		gh(hh, db$sh_h, db$sc_h)
	}
	norm_h <- function(hh) {
		fw(max(wmin, db$phi0_s-db$alp*hh),db$sh_w,db$sc_w)*
		gh(hh, db$sh_h, db$sc_h)
	}
	hs <- integrate(Vectorize(int_h), 0, hmax)$value/
	integrate(Vectorize(norm_h), 0, hmax)$value

	## Take min wage into account
	hs_s <- ifelse(db$phi0_s-hs*db$alp<wmin, -(wmin-db$phi0_s)/db$alp,hs)
	## phis from hs
	phis_s <- db$phi0_s-hs_s*db$alp
	db %>% mutate(phis_s=phis_s, hs_s=hs_s)
}

## Next-job w and h as a function of indiff curve and job densities
wn_hn_fun <- function(db){
	int_wh <- function(w,h) {
		fw(w,db$sh_w,db$sc_w)*gh(h, db$sh_h, db$sc_h)}
	norm_h <- function(h) {
		integrate(Vectorize(function(w) int_wh(w,h)),
			max(wmin, db$phi0_s-db$alp*h),wmax)$value
	}
	norm <- integrate(Vectorize(norm_h), 0, hmax)$value
	exp_h <- function(h) {
		integrate(Vectorize(function(w) h*int_wh(w,h)),
			max(wmin, db$phi0_s-db$alp*h),wmax)$value
	}
	exp_w <- function(h) {
		integrate(Vectorize(function(w) w*int_wh(w,h)),
			max(wmin, db$phi0_s-db$alp*h),wmax)$value
	}

	hn_s <- integrate(Vectorize(exp_h), 0, hmax)$value/norm
	wn_s <- integrate(Vectorize(exp_w), 0, hmax)$value/norm	
	db %>% mutate(wn_s=wn_s, hn_s=hn_s)
}

## Job-finding rate function
jfr_fun <- function(db){
  intjfr_wh <- function(w,h) {
    fw(w,db$sh_w,db$sc_w)*gh(h, db$sh_h, db$sc_h)}
  intjfr_h <- function(h) {
    integrate(Vectorize(function(w) intjfr_wh(w,h)),
              max(wmin,db$phi0_s-db$alp*h),wmax, rel.tol=1e-7)$value
  }
  norm_h <- function(h) {
    integrate(Vectorize(function(w) intjfr_wh(w,h)),
              wmin,wmax, rel.tol=1e-7)$value
  }
  db %>% mutate(
    jfr_s = lam*integrate(Vectorize(intjfr_h), 0, hmax)$value/
      integrate(Vectorize(norm_h), 0, hmax)$value
  )
}


## Solving wrapper
solve_fun <- function(db){
	db %>% select(sample,q,alp,lam,b,
		sh_w,sc_w,sh_h,sc_h) %>% 
	phi0_fun() %>% hs_phis_fun() %>% wn_hn_fun() %>% jfr_fun() %>% 
	select(sample, phi0_s, phis_s, hs_s, wn_s, hn_s, jfr_s)
}

## 3. Decomposition functions

## Finds alpha that makes hs_s equal to its target hs_f
alp_solve_hs_fun <- function(db,hdn,hup){
	# If female or target wage < min w: stop
	if (db$phis_f < wmin){return(db %>% mutate(alp_f = NA))}
	# Function to be put to zero
	rootf <- function(aalp) {
		dbm <- db %>% mutate(alp = aalp) %>% solve_fun()
		(dbm$hs_s - db$hs_f) %>% as.numeric()
	}
	db %>% mutate(alp_f = uniroot(rootf,c(hdn,hup))$root)
}

## Finds alpha that makes hs_s equal to its target hs_f
alp_solve_hn_fun <- function(db,hdn,hup){
	# If female or target wage < min w: stop
	if (db$wn_f < wmin){return(db %>% mutate(alp_f = NA))}
	# Function to be put to zero
	rootf <- function(aalp) {
		dbm <- db %>% mutate(alp = aalp) %>% solve_fun()
		(dbm$hn_s - db$hn_f) %>% as.numeric()
	}
	db %>% mutate(alp_f = uniroot(rootf,c(hdn,hup))$root)
}

decomp_fun <- function(dbcal, daa = NULL, target="hn"){
	## Solve for declared outcomes and next-job outcomes
	dbsol0 <- dbcal %>% split(.$sample) %>% map_dfr(solve_fun)

	# Compute counterfactual alp, for each sample
	# Case 1: We fix \Delta alp/alp
	if (!is.null(daa)&length(daa)==1){
		
		dbcal1 <- dbcal %>% 
		left_join(dbsol0 %>% 
			select(sample, phis_f=phis_s, hs_f=hs_s, 
				wn_f=wn_s, hn_f=hn_s, jfr_f=jfr_s), by = "sample") %>% 
		mutate(phis_f=phis_f-phis_logdiff, hs_f = hs_f*(1-hs_logdiff),
			wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff),
			jfr_f=jfr_f*(1-jfr_logdiff)) %>% 
		filter(wn_f > wmin) %>% 
		mutate(alp_f = alp*ifelse(men==1, 1+daa, 1-daa))
	}

	# Case 1bis: We fix \Delta alp/alp to a vector value
	if (!is.null(daa)&length(daa)>1){
		
		dbcal1 <- dbcal %>% 
		left_join(dbsol0 %>% 
			select(sample, phis_f=phis_s, hs_f=hs_s, 
				wn_f=wn_s, hn_f=hn_s, jfr_f=jfr_s), by = "sample") %>% 
		mutate(phis_f=phis_f-phis_logdiff, hs_f = hs_f*(1-hs_logdiff),
			wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff),
			jfr_f=jfr_f*(1-jfr_logdiff), 
			alp_f = alp*(1+daa)) %>% 
		filter(wn_f > wmin) 
	}

	# Case 2: We use the gap in new commute as target 
	# to get \Delta alp
	if (is.null(daa) & target == "hn"){
	dbcal1 <- dbcal %>% 
	left_join(dbsol0 %>% 
		select(sample, phis_f=phis_s, hs_f=hs_s, 
			wn_f=wn_s, hn_f=hn_s, jfr_f=jfr_s), by = "sample") %>% 
	mutate(phis_f=phis_f-phis_logdiff, hs_f = hs_f*(1-hs_logdiff),
		wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff),
		jfr_f=jfr_f*(1-jfr_logdiff)) %>% 
	filter(wn_f > wmin) %>% 
	split(.$sample) %>% 
	map_dfr(~ alp_solve_hn_fun(.,-5,-.5))
	}

	# Case 3: We use the gap in max acc commute as target 
	# to get \Delta alp
	if (is.null(daa) & target == "hs"){
	dbcal1 <- dbcal %>% 
	left_join(dbsol0 %>% 
		select(sample, phis_f=phis_s, hs_f=hs_s, 
			wn_f=wn_s, hn_f=hn_s, jfr_f=jfr_s), by = "sample") %>% 
	mutate(phis_f=phis_f-phis_logdiff, hs_f = hs_f*(1-hs_logdiff),
		wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff),
		jfr_f=jfr_f*(1-jfr_logdiff)) %>% 
	filter(wn_f > wmin) %>% 
	split(.$sample) %>% 
	map_dfr(~ alp_solve_hs_fun(.,-5,-.5))
	}


	## Simulate for each alp_f
	dbsol1 <- dbcal1 %>% 
	rename(alp_m=alp, alp=alp_f) %>% 
	split(.$sample) %>% map_dfr(solve_fun) %>% 
	rename(phi0_sf=phi0_s,phis_sf=phis_s, hs_sf=hs_s, 
	       wn_sf=wn_s, hn_sf=hn_s, jfr_sf=jfr_s)

	## Decomposition
	dbsol0 %>% 
	right_join(dbsol1, by="sample") %>% right_join(dbcal1, by="sample") %>% 
	mutate(expl_phis = (phis_s-phis_sf)/(phis_s-phis_f),
		expl_wn = (wn_s-wn_sf)/(wn_s-wn_f),
		expl_hn = (hn_s-hn_sf)/(hn_s-hn_f),
		expl_jfr = (jfr_s-jfr_sf)/(jfr_s-jfr_f)) 
}

## Bonus: 
## Next-job distribution of commute as a function of parameters
hn_pdf_fun <- function(db){
	int_wh <- function(w,h) {
		fw(w,db$sh_w,db$sc_w)*gh(h, db$sh_h, db$sc_h)}
	h_pdf <- function(h) {
		integrate(Vectorize(function(w) int_wh(w,h)),
			max(wmin, db$phi0_s-db$alp*h),wmax)$value
	}
	norm <- integrate(Vectorize(h_pdf), 0, hmax)$value
	Vectorize(h_pdf)
}

## 4. Functions specific to the alternative definitions of declared values

## Estimate F and G (and alpha, in this case)
FG_cal_alt_fun <- function(db,wq=.9,hq=0){

	EVwh_fun <- function(db,sh_w,sc_w,sh_h,sc_h){
		alp <- alp_fun(qgamma(wq,shape=sh_w,scale=sc_w),
			qh(hq,sh_h,sc_h),
			db$phi0,db$barh)
		int_wh <- function(w,h) {
			fw(w,sh_w,sc_w)*gh(h,sh_h,sc_h)}
		norm_h <- function(h) {
			integrate(Vectorize(function(w) int_wh(w,h)),
				max(wmin, db$phi0-alp*h),wmax)$value
		}
		norm <- integrate(Vectorize(norm_h), 0, hmax)$value
		exp_w <- function(h) {
			integrate(Vectorize(function(w) w*int_wh(w,h)),
				max(wmin, db$phi0-alp*h),wmax)$value
		}
		Ew <- integrate(Vectorize(exp_w), 0, hmax)$value/norm
		var_w <- function(h) {
			integrate(Vectorize(function(w) (w-Ew)^2*int_wh(w,h)),
				max(wmin, db$phi0-alp*h),wmax)$value
		}
		Vw <- integrate(Vectorize(var_w), 0, hmax)$value/norm	
		exp_h <- function(h) {
			integrate(Vectorize(function(w) h*int_wh(w,h)),
				max(wmin, db$phi0-alp*h),wmax)$value
		}
		Eh <- integrate(Vectorize(exp_h), 0, hmax)$value/norm
		var_h <- function(h) {
			integrate(Vectorize(function(w) (h-Eh)^2*int_wh(w,h)),
				max(wmin, db$phi0-alp*h),wmax)$value
		}
		Vh <- integrate(Vectorize(var_h), 0, hmax)$value/norm			
		c(Ew,Vw,Eh,Vh,norm)
	}

	loss_fun <- function(sh_w,sc_w,sh_h,sc_h){
		EVwh <- EVwh_fun(db,sh_w,sc_w,sh_h,sc_h)
		((EVwh[1]-db$wn_mean)^2)/(db$wn_var) + 
		((EVwh[2]-db$wn_var)^2)/(db$wn_kur) + 
		((EVwh[3]-db$hn_mean)^2)/(db$hn_var) + 
		((EVwh[4]-db$hn_var)^2)/(db$hn_kur)
	}

	resoptim <- optim(c(db$sh_w0,db$sc_w0,db$sh_h0,db$sc_h0),
	function(v){loss_fun(v[1],v[2],v[3],v[4])}, 
	lower = c(2,.03,1.5,.005), upper = c(10,.1,8,.04),
	method = "L-BFGS-B")

	## Add sh_h and sc_h in data
	db %>% mutate(
		sh_w=resoptim$par[1], sc_w=resoptim$par[2], 
		sh_h=resoptim$par[3], sc_h=resoptim$par[4], 
		alp=alp_fun(qgamma(wq,shape=sh_w,scale=sc_w),
			qh(hq,sh_h,sc_h),
			phi0,barh))
}

## Declared h and phi as a function of indiff curve and job densities
barh_alt_fun <- function(db){
	w90 <- qgamma(.95,shape=db$sh_w,scale=db$sc_w)
	barh_s = -(w90 - db$phi0_s)/db$alp
	db %>% mutate(barh_s=barh_s)
}

## Solving wrapper
solve_alt_fun <- function(db){
	db %>% select(sample,q,alp,lam,b,sh_w,sc_w,sh_h,sc_h) %>% 
	phi0_fun() %>% barh_alt_fun() %>% wn_hn_fun() %>% 
	select(sample, phi0_s, barh_s, wn_s, hn_s)
}

## Finds alpha that makes hs_s equal to its target hs_f
alp_solve_alt_fun <- function(db,hdn,hup){
	# If female or target wage < min w: stop
	#if (db$phis_f < 1){return(db %>% mutate(alp_f = NA))}
	# Function to be put to zero
	rootf <- function(aalp) {
		dbm <- db %>% mutate(alp = aalp) %>% solve_alt_fun()
		(dbm$barh_s - db$barh_f) %>% as.numeric()
	}
	db %>% mutate(alp_f = uniroot(rootf,c(hdn,hup))$root)
}

## Decomposition function
decomp_alt_legacy_fun <- function(dbcal){
	## Solve for declared outcomes and next-job outcomes
	dbsol0 <- dbcal %>% split(.$sample) %>% map_dfr(solve_alt_fun)

	## Compute counterfactual alp, for each sample
	dbcal1 <- dbcal %>% 
	left_join(dbsol0 %>% 
		select(sample, phi0_f=phi0_s, barh_f=barh_s, 
			wn_f=wn_s, hn_f=hn_s), by = "sample") %>% 
	mutate(phi0_f=phi0_f*(1-phi0_logdiff), barh_f = barh_f*(1-barh_logdiff),
		wn_f=wn_f*(1-wn_logdiff), hn_f = hn_f*(1-hn_logdiff)) %>% 
	#filter(phi0_f >= 1) %>% 
	split(.$sample) %>% 
	map_dfr(~ alp_solve_alt_fun(.,-5,-.5))

	## Simulate for each alp_f
	dbsol1 <- dbcal1 %>% 
	rename(alp_m=alp, alp=alp_f) %>% split(.$sample) %>% 
	map_dfr(solve_alt_fun) %>% 
	rename(phi0_sf=phi0_s,barh_sf=barh_s, wn_sf=wn_s, hn_sf=hn_s)

	## Decomposition
	dbsol0 %>% 
	right_join(dbsol1, by="sample") %>% right_join(dbcal1, by="sample") %>% 
	mutate(expl_phi0 = (phi0_s-phi0_sf)/(phi0_s-phi0_f),
		expl_wn = (wn_s-wn_sf)/(wn_s-wn_f),
		expl_hn = (hn_s-hn_sf)/(hn_s-hn_f)) 
}



decomp_alt_fun <- function(dbcal, daa = NULL, target="hn"){
	## Solve for declared outcomes and next-job outcomes
	dbsol0 <- dbcal %>% split(.$sample) %>% map_dfr(solve_alt_fun)

	# Compute counterfactual alp, for each sample
	# Case 1: We fix \Delta alp/alp
	if (!is.null(daa)&length(daa)==1){
	dbcal1 <- dbcal %>% 
	left_join(dbsol0 %>% 
		select(sample, phi0_f=phi0_s, barh_f=barh_s, 
			wn_f=wn_s, hn_f=hn_s), by = "sample") %>% 
	mutate(phi0_f=phi0_f-phi0_logdiff, barh_f = barh_f*(1-barh_logdiff),
		wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff)) %>% 
	filter(wn_f > wmin) %>% 
	mutate(alp_f = alp*ifelse(men==1, 1+daa, 1-daa))
	}

	# Case 1bis: We fix \Delta alp/alp (and it is a vector)
	if (!is.null(daa)&length(daa)>1){
	dbcal1 <- dbcal %>% 
	left_join(dbsol0 %>% 
		select(sample, phi0_f=phi0_s, barh_f=barh_s, 
			wn_f=wn_s, hn_f=hn_s), by = "sample") %>% 
	mutate(phi0_f=phi0_f-phi0_logdiff, barh_f = barh_f*(1-barh_logdiff),
		wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff)) %>% 
	filter(wn_f > wmin) %>% 
	mutate(alp_f = alp*(1+daa))
	}

	# Case 2: We use the gap in new commute as target 
	# to get \Delta alp
	if (is.null(daa) & target == "hn"){
	dbcal1 <- dbcal %>% 
	left_join(dbsol0 %>% 
		select(sample, phi0_f=phi0_s, barh_f=barh_s, 
			wn_f=wn_s, hn_f=hn_s), by = "sample") %>% 
	mutate(phi0_f=phi0_f-phi0_logdiff, barh_f = barh_f*(1-barh_logdiff),
		wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff)) %>% 
	filter(wn_f > wmin) %>% 
	split(.$sample) %>% 
	map_dfr(~ alp_solve_hn_fun(.,-5,-.2))
	}

	# Case 3: We use the gap in max acc commute as target 
	# to get \Delta alp
	if (is.null(daa) & target == "hs"){
	dbcal1 <- dbcal %>% 
	left_join(dbsol0 %>% 
		select(sample, phi0_f=phi0_s, barh_f=barh_s, 
			wn_f=wn_s, hn_f=hn_s), by = "sample") %>% 
	mutate(phi0_f=phi0_f-phi0_logdiff, barh_f = barh_f*(1-barh_logdiff),
		wn_f=wn_f-wn_logdiff, hn_f = hn_f*(1-hn_logdiff)) %>% 
	filter(wn_f > wmin) %>% 
	split(.$sample) %>% 
	map_dfr(~ alp_solve_alt_fun(.,-5,-.2))
	}

	## Simulate for each alp_f
	dbsol1 <- dbcal1 %>% 
	rename(alp_m=alp, alp=alp_f) %>% split(.$sample) %>% 
	map_dfr(solve_alt_fun) %>% 
	rename(phi0_sf=phi0_s,barh_sf=barh_s, wn_sf=wn_s, hn_sf=hn_s)

	## Decomposition
	dbsol0 %>% 
	right_join(dbsol1, by="sample") %>% right_join(dbcal1, by="sample") %>% 
	mutate(expl_phi0 = (phi0_s-phi0_sf)/(phi0_s-phi0_f),
		expl_wn = (wn_s-wn_sf)/(wn_s-wn_f),
		expl_hn = (hn_s-hn_sf)/(hn_s-hn_f)) 
}