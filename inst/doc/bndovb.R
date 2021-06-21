## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE---------------------------------------------------------------
#  install.packages("bndovb")

## ----gh-installation, eval = FALSE--------------------------------------------
#  # install.packages("devtools")
#  devtools::install_github("yujunghwang/bndovb")

## -----------------------------------------------------------------------------
library(bndovb)
library(MASS)

# sample size
Nm <- 5000 # main data
Na <- 5000 # auxiliary data

# use same DGP in maindat and auxdat
maindat <- mvrnorm(Nm,mu=c(2,3,1),Sigma=rbind(c(2,1,1),c(1,2,1),c(1,1,2)))
auxdat  <- mvrnorm(Na,mu=c(2,3,1),Sigma=rbind(c(2,1,1),c(1,2,1),c(1,1,2)))

maindat <- as.data.frame(maindat)
auxdat <- as.data.frame(auxdat)

colnames(maindat) <- c("x1","x2","x3")
colnames(auxdat) <- c("x1","x2","x3")

# this is a true parameter which we try to get bounds on
truebeta <- matrix(c(2,1,3,2),ncol=1)

# generate a dependent variable
maindat$y <- as.matrix(cbind(rep(1,Nm),maindat[,c("x1","x2","x3")]))%*%truebeta

# main data misses one omitted variable "x1"
maindat <- maindat[,c("x2","x3","y")]

# use "bndovb" function assuming parametric "normal" distribution for the CDF and quantile function (set method=1)
# see Hwang(2021) for further details
oout <- bndovb(maindat=maindat,auxdat=auxdat,depvar="y",ovar="x1",comvar=c("x2","x3"),method=1)
print(oout)

# use "bndovb" function using nonparametric estimation of the CDF and quantile function (set method=2)
# for nonparametric density estimator, the R package "np" was used. See Hayfield and Racine (2008), Li and Racine (2008), Li, Lin and Racine (2013)
#### The next line takes very long because of large sample size. You can try using a smaller sample and run the next line.
#oout <- bndovb(maindat=maindat,auxdat=auxdat,depvar="y",ovar="x1",comvar=c("x2","x3"),method=2)
#print(oout)


