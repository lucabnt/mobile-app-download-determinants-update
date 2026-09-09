#Determinants of Download on Mobile App Stores - An Empirical Analysis
#Author: Luca Bontempi
#Master Thesis, Chair of Marketing, Eberhard Karl University of Tübingen, 14/02/2023


#Import libraries
library(tidyverse)
library(caret)



#ANOVA
#Load the data
data1 <- read.csv("M ANOVA_RM.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)

ANOVA.aov <- aov(y_i  ~ i_name*x_i_name*n_name + Error(lfdn), data = data1)
summary(ANOVA.aov)

regression.aov <- lm(y_i  ~ i_name*x_i_name*n_name, data = data1)
summary(regression.aov)



#Regressions

#Model 1
#M1_rep

#Load the data
data1 <- read.csv("M1_rep.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M1_rep <- lm(y_rep_1 ~ x_rep+ x_rep*inv_app_mc +x_rep*inv_dl_mc + x_rep*inv_cat_mc, data=data1)
summary(M1_rep)


#M1_pop
#Load the data
data1 <- read.csv("M1_pop.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M1_pop <- lm(y_pop_1  ~ x_pop  + x_pop *inv_app_mc + x_pop *inv_dl_mc + x_pop *inv_cat_mc, data=data1)
summary(M1_pop)


#M1_brand
data1 <- read.csv("M1_brand.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M1_brand <- lm(y_brand_1 ~ x_brand + x_brand*inv_app_mc + x_brand*inv_dl_mc + x_brand*inv_cat_mc, data=data1)
summary(M1_brand)


#Model 2
#M2_rep
#Load the data
data1 <- read.csv("M2_rep.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M2_rep <- lm(y_rep_3 ~ x_rep + x_rep*x_brand +x_rep*x_pop + x_rep*inv_app_mc + x_rep*inv_dl_mc + x_rep*inv_cat_mc, data=data1)
summary(M4_rep)


#M2_pop
#Load the data
data1 <- read.csv("M2_pop.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M2_pop <- lm(y_pop_3 ~ x_pop + x_pop*x_brand +x_pop*x_rep + x_pop*inv_app_mc + x_pop*inv_dl_mc + x_pop*inv_cat_mc, data=data1)
summary(M4_pop)


#M2_brand
#Load the data
data1 <- read.csv("M2_brand.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M2_brand <- lm(y_brand_3 ~ x_brand + x_brand*x_rep +  x_brand*x_pop +  x_brand*inv_app_mc + x_brand*inv_dl_mc + x_brand*inv_cat_mc, data=data1)
summary(M2_brand)


#Model 3
#M3_rep
#Load the data
data1 <- read.csv("M3_rep.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M3_rep <- lm(y_rep ~ x_rep + x_rep*inv_app_mc + x_rep*inv_dl_mc + x_rep*inv_cat_mc +x_rep*comp_rep , data=data1)
summary(M3_rep)


#M3_pop
#Load the data
data1 <- read.csv("M3_pop.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M3_pop <- lm(y_pop ~ x_pop+ x_pop*inv_app_mc + x_pop*inv_dl_mc + x_pop*inv_cat_mc + x_pop*comp_pop, data=data1)
summary(M3_pop)


#M3_brand
#Load the data
data1 <- read.csv("M3_brand.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Regression
M3_brand <- lm(y_brand ~ x_brand + x_brand*inv_app_mc + x_brand*inv_dl_mc + x_brand*inv_cat_mc + x_brand*comp_brand , data=data1)
summary(M3_brand)


#Figures
#Load the data
data1 <- read.csv("M plots.csv", header=TRUE, stringsAsFactors=FALSE)
head(data1)
#Plots
par(cex=.6)

with(data1, interaction.plot(x_i[n==1], i_name[n==1], y_i_mc[n==1], 
                             ylim = c(-0.9, 0.9), lty = c(1, 2, 3),     
                             ylab = "mean-centered ITD", xlab = "x", trace.label = "Variable"))
title("n = 1")


with(data1, interaction.plot(x_i[n==2], i_name[n==2], y_i_mc[n==2], 
                             ylim = c(-0.9, 0.9), lty = c(1, 2, 3),     
                             ylab = "mean-centered ITD", xlab = "x", trace.label = "Variable"))
title("n = 2")


with(data1, interaction.plot(x_i[n==3], i_name[n==3], y_i_mc[n==3], 
                             ylim = c(-0.9, 0.9), lty = c(1, 2, 3),     
                             ylab = "mean-centered ITD", xlab = "x", trace.label = "Variable"))
title("n = 3")


with(data1, interaction.plot(x_i, i_name, y_i_mc, 
                             ylim = c(-0.9, 0.9), lty = c(1, 2, 3),     
                             ylab = "mean-centered ITD", xlab = "x", trace.label = "Variable"))
