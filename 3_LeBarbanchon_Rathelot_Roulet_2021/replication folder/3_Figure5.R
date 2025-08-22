#install.packages("tidyverse",dependencies=TRUE)
#install.packages("here")

library(tidyverse)
library(here)
library(foreign)


dat <- read.dta("C:/Users/Public/Documents/resW/data/jointdensity.dta")
dat <- dat %>% mutate(z=1)

# to switch if we restrict to workers declaring in KMs
# dat <- dat %>% filter(mobunit_tps==0)


dat %>% summary



###########################################################
## Load and plot data for male 

# Point plot
dat %>% filter(female==0) %>%
  ggplot(aes(x=t_D,y=log_postW_resW)) +
  geom_point(alpha=.01) +
  geom_hline(yintercept=0,linetype=2,colour="red") +
  geom_vline(xintercept=0,linetype=2,colour="red") +
  theme_light() +
  labs(x="log(reemployment commute / max. acceptable commute)",
       y= "log(reemployment wage / reservation wage)") +
  xlim(-5,5) + ylim(-.6,.6)
ggsave(here("2wdens_NewRes_point_male_1.png"))
ggsave(here("2wdens_NewRes_point_male_1.svg"))
ggsave(here("2wdens_NewRes_point_male_1.eps"),device=cairo_ps,fallback_resolution=300)

dat %>% filter(female==0) %>%
  ggplot(aes(x=t_D,y=log_postW_resW)) +
  geom_point(alpha=.01) +
  geom_hline(yintercept=0,linetype=2) +
  geom_vline(xintercept=0,linetype=2) +
  theme_light() +
  labs(x="log(reemployment commute / max. acceptable commute)",
       y= "log(reemployment wage / reservation wage)") +
  xlim(-5,5) + ylim(-.6,.6)
ggsave(here("2wdens_NewRes_point_male_1_bw.eps"),device=cairo_ps,fallback_resolution=300)



###########################################################
## plot data for women 

# Point plot

dat %>% filter(female==1) %>%
  ggplot(aes(x=t_D,y=log_postW_resW)) +
  geom_point(alpha=.01) +
  geom_hline(yintercept=0,linetype=2,colour="red") +
  geom_vline(xintercept=0,linetype=2,colour="red") +
  theme_light() +
  labs(x="log(reemployment commute / max. acceptable commute)",
       y= "log(reemployment wage / reservation wage)") +
  xlim(-5,5) + ylim(-.6,.6)
ggsave(here("2wdens_NewRes_point_female_1.png"))
ggsave(here("2wdens_NewRes_point_female_1.svg"))
ggsave(here("2wdens_NewRes_point_female_1.eps"),device=cairo_ps,fallback_resolution=300)

dat %>% filter(female==1) %>%
  ggplot(aes(x=t_D,y=log_postW_resW)) +
  geom_point(alpha=.01) +
  geom_hline(yintercept=0,linetype=2) +
  geom_vline(xintercept=0,linetype=2) +
  theme_light() +
  labs(x="log(reemployment commute / max. acceptable commute)",
       y= "log(reemployment wage / reservation wage)") +
  xlim(-5,5) + ylim(-.6,.6)
ggsave(here("2wdens_NewRes_point_female_1_bw.eps"),device=cairo_ps,fallback_resolution=300)
