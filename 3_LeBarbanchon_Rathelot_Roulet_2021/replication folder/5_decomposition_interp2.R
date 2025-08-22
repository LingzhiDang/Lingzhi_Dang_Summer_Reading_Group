##
## decomposition_interp2.R
## 
## Estimates the parameters of the model under interpretation 2 (and 2bis)
## Performs the decomposition and returns the results
## Produces material for Table A3  
## 
## 24 Sept 2020
## 
## Le Barbanchon, Roulet, Rathelot
## 

library(tidyverse)
library(here)

rm(list=ls())
source(here("decomposition_funs.R"))

## These parameters are fixed
rho <- 1-(1-.12)^(1/12)
hmax <- 1 ## This is not a real parameter (should be as high as possible)
wmin <- 0 # Normalised to one
wmax <- 6 # expressed in minW units

# Import dalp/alp
daa2 <- haven::read_dta(
  here("output","tableA1_dta.dta")) %>% 
  filter(v1=="female") %>% pull(v4) %>% 
  str_remove_all("\\*") %>% as.numeric()

daa2b <- haven::read_dta(
  here("output","tableA2_dta.dta")) %>% 
  filter(v1=="female") %>% pull(v4) %>% 
  str_remove_all("\\*") %>% as.numeric()

# Import calibration data
dat <- haven::read_dta(
  here("output","calibration_sum_stat.dta")) %>% 
  rename(
    phi0_logdiff = gaplog_resWcorr,
    barh_logdiff = gaplog_mobdist, 
    wn_logdiff = gaplog_postW, 
    hn_logdiff = gaplog_distanceE1) %>% 
  mutate(
    q = 365/dur_lastjob/12, 
    jfr = 365/dur_U/12,
    phi0 = log(resWcorr_minW), # Declared res wage (log)
    barh = mobdist_km/100, # Declared max commute
    wn_mean = log(postW_minW), # Next-job wage (log)
    hn_mean = distanceE1/100, # Next-job commute
  ) %>% 
  left_join(
    here("output","calibration_wage_distribution.dta") %>% 
      haven::read_dta() %>% 
      select(sample=sample_,wn_var=var_resid_gp, wn_kur=W4_resid_gp), 
    by="sample") %>% 
  left_join(
    here("output","calibration_distance_distribution.dta") %>% 
      haven::read_dta() %>% 
      select(sample=sample_, hn_var=var_exp_resid_gp, hn_kur=W4_exp_resid_gp) %>% 
      mutate(hn_var = hn_var/(100^2),hn_kur = hn_kur/(100^4)), 
    by = "sample") %>% 
  filter(sample %in% 25:26) %>% 
  ## Construct guess for F, G parameters
  mutate(sh_w0=2.2297, sc_w0=.1219, sh_h0=3.5748, sc_h0=.01983) %>% 
  ## Construct dalp/alp
  mutate(
    dalp_alp_2    = c(daa2 ,-daa2 ),
    dalp_alp_2bis = c(daa2b,-daa2b)) %>% 
  ## Keep women only
  filter(men==0)

## F function
fw <- function(w,sh_w,sc_w){dgamma(w,shape=sh_w,scale=sc_w)}
## G function
gh <- function(h, sh_h, sc_h){
  a0 <- 1/(2*pgamma(hmax,shape=sh_h,scale=sc_h))
  a0*dgamma(h,shape=sh_h,scale=sc_h)+h}


Gh <- function(h, sh_h, sc_h) {
  integrate(Vectorize(function(hh) gh(hh, sh_h, sc_h)),
            0,h)$value
}
qh <- function(q, sh_h, sc_h){
  uniroot(function(hh){Gh(hh, sh_h, sc_h)-q}, c(0,1))$root
}
## alp function
alp_fun <- function(whigh,hlow,phi0,barh){-(whigh - phi0)/(barh - hlow)}


## Estimate and decompose for interpretation 2 and 2bis
dbcal_2 <- dat %>% split(.$sample) %>% 
  map_dfr(~ FG_cal_alt_fun(.,.9,0) %>% lam_cal_fun() %>% b_cal_fun() )
dbdecomp_2 <- decomp_alt_fun(dbcal_2, daa=dat$dalp_alp_2) %>% mutate(DL_alp = (alp_f-alp)/alp)

dbcal_2b <- dat %>% split(.$sample) %>% 
  map_dfr(~ FG_cal_alt_fun(.,.75,.25) %>% lam_cal_fun() %>% b_cal_fun() )
dbdecomp_2b <- decomp_alt_fun(dbcal_2b, daa=dat$dalp_alp_2bis) %>% mutate(DL_alp = (alp_f-alp)/alp)

## Output the results
paste(c("Interpretation 2","Interpretation 2 bis"), 
      str_c(round(1000*c(dbdecomp_2$expl_wn,dbdecomp_2b$expl_wn))/10, "\\%"), 
      str_c(round(1000*c(dbdecomp_2$expl_hn,dbdecomp_2b$expl_hn))/10, "\\%"), 
      str_c(round(1000*c(dbdecomp_2$DL_alp,dbdecomp_2b$DL_alp))/10, "\\%"), 
      sep = " & ") %>% 
  paste(collapse = "\\\\ \n") %>% 
  cat(file=here("output","decomposition","Table_A3.tex"))