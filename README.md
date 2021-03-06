bndovb
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

## Citation

Please cite the following paper if you use this package.

  - [Hwang, Yujung, Bounding Omitted Variable Bias Using Auxiliary Data.
    Available at SSRN.](https://www.ssrn.com/abstract=3866876)

## Introduction

The R package **bndovb** implements a Hwang(2021) estimator to bound
omitted variable bias using auxiliary data. The basic assumption is that
the main data includes a dependent variable and every regressor but one
omitted variable. So there is an omitted variable bias in the OLS result
from the main data. However, if there is auxiliary data that includes
every right-hand side regressor (or its noisy proxies), it can bound the
omitted variable bias. Hwang(2021) provides a more general estimator for
when there is more than one omitted variable and when the auxiliary data
does not contain every right-hand side regressor (or its noisy proxies).

This package implements a simple estimator when the number of omitted
variables is just one, and the auxiliary data contains every right-hand
side regressor but the only omitted variable. This package provides two
different functions.

The function ‘bndovb’ can be used when the auxiliary data contain every
right-hand side variable without measurement errors. The function
‘bndovbme’ can be used when noisy proxies for the omitted variable
exist in the auxiliary data. Other regressors in the auxiliary data are
assumed measurement error-free. The function requires another R package,
‘factormodel,’ written by the same author.

When using ‘bndovb,’ a user should specify a method for density
estimation as part of an estimation procedure, either 1 (parametric
normal density assumption) or 2 (nonparametric kernel density
estimation). In general, it is strongly recommended to use method 1
(parametric normal density assumption), particularly when data is large
or the regression model is large. Method 2 calls an R package “np” (Li
and Racine, 2008; Li, Lin and Racine, 2013) but this method is very
slow, as emphasized in their vignette file. I recommend using their
method only when (i) data is small and (ii) there is only one common
variable, which makes the conditional CDF and quantile function
univariate. The default method is 1, using parametric normal density
assumption.

When using ‘bndovbme’, the auxiliary data must contain noisy proxy
variables for the omitted variable. A user should set the type of the
proxy variables, ptype, to either 1 (continuous) or 2 (discrete). When
proxy variables are continuous, the auxiliary data must contain at least
2 proxy variables. When proxy variables are discrete, the auxiliary data
must contain at least 3 proxy variables.

## Installation

You can install a package **bndovb** using either CRAN or github.

``` r
install.packages("bndovb")
```

or

``` r
# install.packages("devtools")
devtools::install_github("yujunghwang/bndovb")
```

## Example 1 : bndovb

The below example shows how to use a function ‘bndovb’ when the
auxiliary data contain the omitted variable from main data without any
measurement error. The code first simulates fake data using the same DGP
in both main data and auxiliary data. Next, the main data omits one
variable. The function ‘bndovb’ provides a bound on regression
coefficients by using both main data and auxiliary data.

``` r
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
#> $hat_beta_l
#>        con         x1         x2         x3 
#>  1.8277099 -0.7843462  3.0145152  1.9318175 
#> 
#> $hat_beta_u
#>      con       x1       x2       x3 
#> 3.164502 1.143567 3.633396 2.594093 
#> 
#> $mu_l
#> [1] 34.37488
#> 
#> $mu_u
#> [1] 36.97911

# use "bndovb" function using nonparametric estimation of the CDF and quantile function (set method=2)
# for nonparametric density estimator, the R package "np" was used. See Hayfield and Racine (2008), Li and Racine (2008), Li, Lin and Racine (2013)
#### The next line takes very long because of large sample size. You can try using a smaller sample and run the next line.
#oout <- bndovb(maindat=maindat,auxdat=auxdat,depvar="y",ovar="x1",comvar=c("x2","x3"),method=2)
#print(oout)
```

## Example 2 : bndovbme (continuous proxy variables)

The code below shows how to use a function ‘bndovbme’ when the auxiliary
data does not contain the omitted variable but contain continuous proxy
variables for the omitted variable. The code may take some time to run.

``` r
library(bndovb)
library(MASS)
library(pracma)

set.seed(210413)

### continuous proxy variables

# set DGP
nu      <- 0.5   # sd of measurement errors in proxy variables
beta    <- c(0,1,1,1) # true parameters in a regression model
gamma   <- c(0,1,1) # parameters to generate correlation between covariates
samsize <- c(6000)  # sample size
mu      <- c(0,0,0,0) # average of covariates
sigma   <- eye(4)

#### simulate data
A <- rbind( c(1,0,0,0), c(0,1,0,0), c(gamma[2],gamma[3],1,0), c(beta[3]+beta[2]*gamma[2],beta[4]+beta[2]*gamma[3], beta[2],1))
B <- c(0,0,gamma[1],beta[1])
mu2    <- A%*%mu + B
sigma2 <- A%*%sigma%*%t(A)
Sim     = 100         ;  # number of Monte Carlo simulations

n=6000;na=3000;nb=3000
simdata <- mvrnorm(n,mu=mu2,Sigma=sigma2)

w1<-simdata[,1]
w2<-simdata[,2]
x <-simdata[,3]
y <-simdata[,4]

# main data
w1_a <- w1[1:na]
w2_a <- w2[1:na]
x_a  <- x[ 1:na]
y_a  <- y[ 1:na]

# auxiliary data
w1_b <- w1[(na+1):n]
w2_b <- w2[(na+1):n]
x_b  <- x[ (na+1):n]
y_b  <- y[ (na+1):n]

# generate continuous proxies
z_b <- w2_b + cbind(rnorm(n-na,mean=0,sd=nu), rnorm(n-na,mean=0,sd=nu), rnorm(n-na,mean=0,sd=nu))

# main data does not include a variable w2
maindat <- data.frame(y=y_a,x=x_a,w1=w1_a)

# auxiliary data does not include a dependent variable y 
# auxiliary data contain three proxy variables for the omitted variable w2
auxdat <- data.frame(x=x_b,w1=w1_b,z1=z_b[,1],z2=z_b[,2],z3=z_b[,3])


# use 'bndovbme' function
oout <- bndovbme(maindat=maindat,auxdat=auxdat,depvar=c("y"),pvar=c("z1","z2","z3"),ptype=1,comvar=c("x","w1"),normalize=FALSE)
print(oout)
#> $hat_beta_l
#>        con       ovar          x         w1 
#> -0.1088779 -1.8499939  0.5519592 -0.4152109 
#> 
#> $hat_beta_u
#>        con       ovar          x         w1 
#> 0.01428739 1.72932693 2.40020851 1.40518506 
#> 
#> $mu_l
#> [1] 0.5594916
#> 
#> $mu_u
#> [1] 2.309199
```

## Example 3 : bndovbme (discrete proxy variables)

The code below is similar to the Example 2 but assumes the proxy
variables in auxiliary data are discrete. The code may take some time to
run.

``` r
library(bndovb)
library(MASS)
library(pracma)

set.seed(210413)

### discrete proxy variables
# set DGP

n=6000;na=3000;nb=3000
mu2 <- c(0,0,0)
Sigma2 <- rbind(c(1,0.5,0.5),c(0.5,1,0.5),c(0.5,0.5,1))

simdata <- mvrnorm(n,mu=mu2,Sigma=Sigma2)
# discretize
simdata[,2] <- (simdata[,2]>0)+1

beta    <- c(0,1,1,1) # true parameters to get bounds on

# simulate a dependent variable
y <- cbind(rep(1,n),simdata)%*%as.matrix(beta) + rnorm(n)

w1<-simdata[,1]
w2<-simdata[,2]
x <-simdata[,3]

# main data
w1_a <- w1[1:na]
w2_a <- w2[1:na]
x_a  <- x[ 1:na]
y_a  <- y[ 1:na]

# auxiliary data
w1_b <- w1[(na+1):n]
w2_b <- w2[(na+1):n]
x_b  <- x[ (na+1):n]
y_b  <- y[ (na+1):n]

# set measurement matrices for discrete proxy variables
M_param <- list()
M_param[[1]] <- rbind(c(0.9,0.1),c(0.1,0.9))
M_param[[2]] <- rbind(c(0.9,0.1),c(0.1,0.9))
M_param[[3]] <- rbind(c(0.9,0.1),c(0.1,0.9))

CM_param <- list()
CM_param[[1]] <- t(apply(M_param[[1]],1,cumsum))
CM_param[[2]] <- t(apply(M_param[[2]],1,cumsum))
CM_param[[3]] <- t(apply(M_param[[3]],1,cumsum))

# simulate proxy variables
z_b <- matrix(NA,nrow=nb,ncol=3)
for (k in 1:nb){
  for (l in 1:3){
    z_b[k,l] <- which(runif(1)<CM_param[[l]][w2_b[k],])[1]
  }
}


# main data
maindat <- data.frame(y=y_a,x=x_a,w1=w1_a)
# auxiliary data
auxdat <- data.frame(x=x_b,w1=w1_b,z1=z_b[,1],z2=z_b[,2],z3=z_b[,3])

# use 'bndovbme' function
oout <- bndovbme(maindat=maindat,auxdat=auxdat,depvar=c("y"),pvar=c("z1","z2","z3"),ptype=2,comvar=c("x","w1"),sbar=2,normalize=FALSE)
print(oout)
#> $hat_beta_l
#>        con       ovar          x         w1 
#> -1.1624776 -1.9791250  0.9362842  0.7931693 
#> 
#> $hat_beta_u
#>      con     ovar        x       w1 
#> 4.453464 1.766742 1.426545 1.269087 
#> 
#> $mu_l
#> [1] 2.240954
#> 
#> $mu_u
#> [1] 2.99594
```

## Conclusion

This vignette showed how to use functions in \`bndovb’ R package.

## References

  - [Hayfield, Tristen, and Jeffrey S. Racine. “Nonparametric
    econometrics: The np package.” Journal of statistical software 27,
    no. 5 (2008): 1-32.](https://doi.org/10.18637/jss.v027.i05)

  - [Hwang, Yujung, Bounding Omitted Variable Bias Using Auxiliary Data.
    Available at SSRN:](https://www.ssrn.com/abstract=3866876)

  - [Li, Qi, and Jeffrey S. Racine. “Nonparametric estimation of
    conditional CDF and quantile functions with mixed categorical and
    continuous data.” Journal of Business & Economic Statistics 26,
    no. 4
    (2008): 423-434.](https://www.tandfonline.com/doi/abs/10.1198/073500107000000250?casa_token=tUdlEvmt_fMAAAAA:IALIN23XRN8bpnL0ZBEQp8MIUO9Ie_SkHzdBTBVa-DD1oYaxdqaqrr_EyBD7IMKjxmXIanGfHIBW)

  - [Li, Qi, Juan Lin, and Jeffrey S. Racine. “Optimal bandwidth
    selection for nonparametric conditional distribution and quantile
    functions.” Journal of Business & Economic Statistics 31, no. 1
    (2013): 57-65.](https://www.tandfonline.com/doi/full/10.1080/07350015.2012.738955?casa_token=8S1iR7ki1qkAAAAA%3AQQI6lwjAKgYfv5dmpbvmbCZckpscxYXFUSvZlXQ64Gz8D45E1yYEh0BPQF5DSg0chfTkcvG6HMim)
