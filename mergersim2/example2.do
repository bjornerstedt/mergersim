/****************************************** EXPLANATION *********************************************************************
This file runs the Stata Journal example for Bjornerstedt and Verboven's mergersim package.

1.	You first need to download the simulation package, this requires version Stata 11 or higher.

In the Stata command line you need to do the following:

	net from http://www.bjornerstedt.org/stata/mergersim
	net install mergersim

In the future, you can get updates, using the command:

	adoupdate, update

2.	Once the package is installed you can run it after having done nested logit estimation.

This do-file illustrates how this works: mergersim is done as a post-estimation command.
In this example, this is after an OLS regression of the nested logit, but in practice one must use appropriate IV regression.
The do-file uses the public car dataset 1970-1999, cars1.dta, a simplified version of the one on my webpages.
****************************************************************************************************************************/


quietly {

version 11.2
clear all
capture log close
discard
*compile

use cars1
}


// 	PART 1. PREPARATORY DATA WORK

	// summarize the data
summarize year country co segment domestic firm qu price horsepower fuel width height pop ngdp

	// define panel to Stata
egen yearcountry=group(year country), label
xtset co yearcountry

	// define outside good
gen MSIZE=pop/4

quietly mergersim init, nests(segment domestic) price(price) quantity(qu) marketsize(MSIZE) firm(firm)
quietly xtreg M_ls price M_lsjh M_lshg horsepower fuel width height domestic year country2-country5, fe
mergersim market
local ndraws 100
set seed 1

preserve
drawnorm alpha sigma1 sigma2, n(`ndraws') cov(M_demand_V) means(M_demand_b) clear
mkmat alpha sigma1 sigma2, matrix(params)
restore


keep if year == 1998 & country == 3
tempfile market bootstrap
save `market'
drop if 1
save `bootstrap' , replace // Save empty dataset
forvalues i = 1/`ndraws' {
	use `market' , clear
	gen obs = `i'
	local alpha = params[`i',1]
	local sigma1 = params[`i',2]
	local sigma2 = params[`i',3]
	local alpha = params[1,1]
	local sigma1 = params[1,2]
*	local sigma2 = params[1,3]
	gen alpha = `alpha'
	gen sigma1 = `sigma1'
	gen sigma2 = `sigma2'
	quietly mergersim init, nests(segment domestic) price(price) quantity(qu) ///
		marketsize(MSIZE) firm(firm) alpha(`alpha') sigmas(`sigma1' `sigma2') 
		
	quietly mergersim simulate , seller(15) buyer(26)
	quietly append using `bootstrap'
	quietly save `bootstrap' , replace 
}

tabstat M_price_ch , by(firm) statistics(mean sd) format(%9.3f) 
reg M_price_ch alpha sigma* if firm==15 | firm ==26
gen pr15=M_price_ch if firm==15
gen pr26=M_price_ch if firm==26
collapse alpha sigma* pr*, by(obs)
scatter pr?? sigma2
