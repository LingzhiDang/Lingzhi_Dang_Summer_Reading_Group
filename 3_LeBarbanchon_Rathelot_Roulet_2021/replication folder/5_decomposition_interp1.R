##
## decomposition_interp1.R
## 
## Estimates the parameters of the model under interpretation 1
## Performs the decomposition and returns the results
## Produces material for Tables VI, D15, D16, D17
## 
## 24 Sept 2020
## 
## Le Barbanchon, Roulet, Rathelot
## 

library(tidyverse)
library(here)

rm(list=ls())
source(here("decomposition_funs.R"))

## 0. Set-up

## These parameters are fixed
rho <- 1-(1-.12)^(1/12)
hmax <- 1 ## The distribution of offered commutes is between 0 and 1 (i.e., 100km)
wmin <- 0 # Minimum log-wage. Wages are expressed in minW units: 
wmax <- 6 

## Import data for commute valuation
alpha <-  here("output","TabD14.dta") %>% 
  haven::read_dta() %>% bind_rows(here("output","Tab5.dta") %>% 
  haven::read_dta()) %>% 
  mutate(lessX = c(1,rep(0,nrow(.)-1)), 
    all = c(1,1,rep(0,nrow(.)-2)))
  
dalp <- alpha %>% filter(all==1) %>% 
  mutate(dalp_alp_1 = (elas_female/elas_male - 1), 
         dalp_alp_0 = (elas_male/elas_female - 1)) %>% 
  select(dalp_alp_1,dalp_alp_0,lessX) %>% 
  pivot_longer(cols = starts_with("dalp_alp"),
               names_to = "men",
               names_prefix = "dalp_alp_",
               values_to = "dalp_alp") %>% 
  mutate(men=as.numeric(men))

alpdb <- alpha %>% 
  select(elas_female,elas_male,lessX,all) %>% 
  pivot_longer(cols = starts_with("elas_"),
               names_to = "men",
               names_prefix = "elas_",
               values_to = "alpha_elas") %>% 
  mutate(men = ifelse(men=="male",1,0), 
         children = rep(c(rep(NA,2),0,0,1,1),each=2), 
         married = rep(c(rep(NA,2),0,1,0,1),each=2)) %>% 
  left_join(dalp, by=c("men","lessX"))

## Import other moments and gather the dataset
dat <- here("output","calibration_distance_distribution.dta") %>% 
  haven::read_dta() %>% 
  select(sample=sample_, hn_var=var_exp_resid_gp, hn_kur=W4_exp_resid_gp) %>% 
  mutate(hn_var = hn_var/(100^2),hn_kur = hn_kur/(100^4)) %>% 
  left_join(
    here("output","calibration_wage_distribution.dta") %>% 
      haven::read_dta() %>% 
      select(sample=sample_,wn_var=var_resid_gp, wn_kur=W4_resid_gp), 
    by="sample") %>% left_join(
    here("output","calibration_sum_stat.dta") %>% 
      haven::read_dta(), by="sample") %>% 
  rename(
    phis_logdiff = gaplog_resWcorr,
    hs_logdiff = gaplog_mobdist, 
    wn_logdiff = gaplog_postW, 
    hn_logdiff = gaplog_distanceE1) %>% 
  mutate(
    all = sample > 24, 
    lessX = sample > 26,
    q = 365/dur_lastjob/12,
    jfr = 365/dur_U/12, 
    phis = log(resWcorr_minW), # Declared res wage (log)
    hs = mobdist_km/100, # Declared max commute
    wn_mean = log(postW_minW), # Next-job wage (log)
    hn_mean = distanceE1/100, # Next-job commute
    jfr_logdiff = gaplog_dur_U) %>% 
  ## alpha block
  left_join(alpdb, by=c("all","lessX","men","children","married")) %>% 
  mutate(
    alp = -alpha_elas*100/distanceE0, #*pastW_minW
    phi0 = phis + alp*hs, #resW for 0 distance 
    ) %>% 
  ## Construct guess for F, G parameters
  mutate(sh_w0=2.2297, sc_w0=.1219, sh_h0=3.5748, sc_h0=.01983,
         sh_w_lb=1.7, sc_w_lb=.08, sh_h_lb=3, sc_h_lb=.01,
         sh_w_ub=4, sc_w_ub=.2, sh_h_ub=4, sc_h_ub=.025) %>% 
  ## Keep women only
  filter(men == 0)

## F function
fw <- function(w,sh_w,sc_w){dgamma(w,shape=sh_w,scale=sc_w)}
## G function
gh <- function(h, sh_h, sc_h){
	a0 <- 1/(2*pgamma(hmax,shape=sh_h,scale=sc_h))
	a0*dgamma(h,shape=sh_h,scale=sc_h)+h}


## 1. Calibration + decomposition

dbcal <- dat %>% 
  split(.$sample) %>% 
  map_dfr(~ FG_cal_fun(.) %>% #Adds delf
            lam_cal_fun() %>% #Adds lam
            b_cal_fun() ) # Adds b
dbdecomp_daa <- decomp_fun(dbcal, daa=dat$dalp_alp) %>% mutate(DL_alp = (alp_f-alp)/alp)
dbdecompFfam_daa <- dbdecomp_daa %>% filter(sample < 25) %>% arrange(children,married) 
dbdecompFall_daa <- dbdecomp_daa %>% filter(sample > 24) 

dbdecomp_hn <- decomp_fun(dbcal, target = "hn") %>% mutate(DL_alp = (alp_f-alp)/alp)
dbdecompFfam_hn <- dbdecomp_hn %>% filter(sample < 25) %>% arrange(children,married) 
dbdecompFall_hn <- dbdecomp_hn %>% filter(sample > 24) 

rownam <- c("Single, no kids", "Married, no kids", 
	"Single, with kids", "Married, with kids")
paste(rownam, 
	str_c(round(1000*dbdecompFfam_daa$expl_wn)/10, "\\%"), 
	str_c(round(1000*dbdecompFfam_daa$expl_hn)/10, "\\%"), 
	str_c(round(1000*dbdecompFfam_daa$DL_alp)/10, "\\%"), 
	sep = " & ") %>% 
paste(collapse = "\\\\ \n") %>% 
cat(file=here("output","Table_VI_subsamples.tex"))

paste(rownam, 
      dbdecompFfam_hn$wn_logdiff %>% formatC(digits=2), 
	str_c(round(1000*dbdecompFfam_hn$expl_wn)/10, "\\%"), 
	str_c(round(1000*dbdecompFfam_hn$DL_alp)/10, "\\%"), 
	sep = " & ") %>% 
paste(collapse = "\\\\ \n") %>% 
cat(file=here("output","Table_D17_subsamples.tex"))

rownam <- c("With all controls", "Removing previous job controls")
paste(rownam, 
      str_c(round(1000*dbdecompFall_daa$expl_wn)/10, "\\%"), 
      str_c(round(1000*dbdecompFall_daa$expl_hn)/10, "\\%"), 
      str_c(round(1000*dbdecompFall_daa$DL_alp)/10, "\\%"), 
      sep = " & ") %>% 
  paste(collapse = "\\\\ \n") %>% 
  cat(file=here("output","Table_VI_fullsample.tex"))

paste(rownam, 
      dbdecompFall_hn$wn_logdiff %>% formatC(digits=2), 
      str_c(round(1000*dbdecompFall_hn$expl_wn)/10, "\\%"), 
      str_c(round(1000*dbdecompFall_hn$DL_alp)/10, "\\%"), 
      sep = " & ") %>% 
  paste(collapse = "\\\\ \n") %>% 
  cat(file=here("output","Table_D17_fullsample.tex"))


## 2. Tables of parameters (FULL SAMPLE)

## One column for one sample
moment_value <- 
  dbcal %>% filter(sample==26) %>% 
  select(phis, hs, wn_mean, hn_mean, wn_var, hn_var, jfr) %>% 
  as.numeric %>% formatC(digits = 2)

moment_name <- c(
  "$\\phi^*$", "$\\tau^*$", 
  "$E(w^n)$","$E(\\tau^n)$",
  "$V(w^n)$","$V(\\tau^n)$",
  "$jfr$")

moment_comment <- c(
  "Log reservation wage, from data (ratio to min wage)", 
  "Maximum acceptable commute, from data (in x00 km)", 
  "Expected log wage in new job, from data (ratio to min. wage)", 
  "Expected commute in new job, from data (in x00 km)", 
  "Variance log wage in new job, from data (ratio to min. wage)", 
  "Variance commute in new job, from data (in x00 km)", 
  "Job-finding rate, from data")

param_value <- c(rho, 
                 dbcal %>% filter(sample==26) %>% 
                   select(q, alp, sh_w, sc_w, sh_h, sc_h, lam, b) %>% 
                   as.numeric) %>% 
  formatC(digits = 2)

param_name <- c(  
  "$r$", "$q$", "$\\alpha$", 
  "$F$: $k_F$ ", "$F$: $\\theta_F$ ", 
  "$G$: $k_G$ ", "$G$: $\\theta_G$ ",
  "$\\lambda$", "$b$")

param_comment <- c("Annual discount rate 12\\%",
                   "Inverse of job spell duration, from data",
                   "Estimation of $\\alpha$, see supra", 
                   "Matches the first two moments of next wage $w^n$ ", 
                   "(id.) ", 
                   "Matches the first two moments of next commute $\\tau^n$ ", 
                   "(id.) ", 
                   "Matches the job-finding rate",
                   "Solution of Equation (1)")

paste(" ", moment_name, moment_comment, moment_value, sep = " & ") %>% 
  paste(collapse = "\\\\ \n") %>% 
  cat(file=here("output","Table_D15_moment.tex"))

paste(" ",param_name, param_comment, param_value, sep = " & ") %>% 
  paste(collapse = "\\\\ \n") %>% 
  cat(file=here("output","Table_D15_param.tex"))


## 3. Tables of parameters (SUBSAMPLES)

param_name <- c(  
  "$r$", "$q$", "$\\alpha$", "$\\phi_0$",
  "$F$: $k_F$ ", "$F$: $\\theta_F$ ", 
  "$G$: $k_G$ ", "$G$: $\\theta_G$ ",
  "$\\lambda$", "$b$")

## As many columns as samples, only names no comments
cbind(c("Married", "Children", param_name) %>% setdiff("$r$"), c(
  dbcal %>% 
    filter(men==0, sample < 25) %>% 
    select(married, children, 
           q, alp, phi0, sh_w, sc_w, sh_h, sc_h, lam, b) %>% 
    map_chr(function(vv) vv %>% as.numeric %>% 
              formatC(digits = 2) %>% paste(collapse = " & ")))) %>% 
  t() %>% 
  as_tibble() %>% map_chr(~paste(., collapse=" & ")) %>% 
  paste(collapse = "\\\\ \n") %>% 
  cat(file=here("output","Table_D16.tex"))
