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

version 11
clear all
capture log close

use cars1


// 	PREPARATORY WORK

	// summarize the data
summarize year country co segment domestic firm qu price horsepower fuel width height pop ngdp

	// define panel to Stata
egen yearcountry=group(year country), label
xtset co yearcountry

	// define outside good
gen MSIZE=pop/4


// BASIC MERGER SIMULATIONS

	// STEP 1. initialize relevant parameters

mergersim init, nests(segment domestic) price(price) quantity(qu) marketsize(MSIZE) firm(firm)

	// STEP 2. premerger investigation

xtreg M_ls price M_lsjh M_lshg horsepower fuel width height domestic year country2-country5, fe 	
mergersim market if year == 1998 

	// STEP 3. merger simulation: GM (seller=15) and VW (buyer=26) in Germany 1998

mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) detail

	// GRAPH PRICE EFFECTS

gen perc_price_ch=M_price_ch*100
graph bar (mean) perc_price_ch if country==3&year==1998, ///
	over(firm, sort(perc_price_ch) descending label(angle(vertical))) ///
	ytitle(Percentage) title(Average percentage price increase per firm)


// EFFICIENCIES

mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) ///
	sellereff(0.20) buyereff(0.20) method(fixedpoint) maxit(40) dampen(0.5)

mergersim mre if year == 1998 & country == 3, seller(15) buyer(26)


// REMEDIES
	// merger between Renault (buyer=18) and PSA (seller=16) in France
	// remedy: PSA owns brand=4 (citroen) and brand=20 (peugeot) and it must sell off citroen to Fiat (firm=4)
	
gen firm_rem=firm
replace firm_rem=16 if firm==18 	// original merger
replace firm_rem=4 if brand==4 		// divestiture
		
quietly mergersim init, nests(segment domestic) unit price(price) quantity(qu) marketsize(MSIZE) firm(firm)
quietly mergersim simulate if year == 1998 & country == 2, seller(16) buyer(18) 
mergersim simulate if year == 1998 & country == 2, newfirm(firm_rem)


// CONDUCT

	// partial coordination of 50% both pre- and post-merger
mergersim market if year == 1998 & country == 3, conduct(0.5)
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) conduct(0.5)


// CALIBRATION INSTEAD OF ESTIMATION OF ALPHA, SIGMA1 AND SIGMA2

	// specify alpha as -0.04 instead of -0.047 before
quietly mergersim init, nests(segment domestic) price(price) quantity(qu) ///
	marketsize(MSIZE) firm(firm) alpha(-0.035) sigmas (0.91 0.57)
mergersim market if year == 1998 & country == 3
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26)

	// calibration of a constant expenditures demand instead of unit demand specification
gen MSIZE1=ngdpe/5

mergersim init, nests(segment domestic) ces price(price) quantity(qu) ///
	marketsize(MSIZE1) firm(firm) alpha(-0.5) sigmas(0.9 .6) 
mergersim market if year == 1998 & country == 3
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) detail 


// APPLICATION OF CALIBRATION: PARAMETRIC BOOTSTRAP FOR CONFIDENCE INTERVALS OF MERGING FIRMS' AVERAGE PRICE CHANGE

quietly mergersim init, nests(segment domestic) price(price) quantity(qu) marketsize(MSIZE) firm(firm)
matrix b=e(b)
matrix V=e(V)
matrix bsub = ( b[1,1] , b[1,2] , b[1,3] ) 
matrix Vsub = ( V[1,1], V[1,2], V[1,3] \ V[2,1] , V[2,2], V[2,3] \ V[3,1], V[3,2], V[3,3] )
local ndraws 100
set seed 1
preserve
drawnorm alpha sigma1 sigma2, n(`ndraws') cov(Vsub) means(bsub) clear
mkmat alpha sigma1 sigma2, matrix(params)
restore
matrix pr_ch = J(`ndraws',2,0)
forvalues i = 1 2 to `ndraws' {
local alpha = params[`i',1]
local sigma1 = params[`i',2]
local sigma2 = params[`i',3]
quietly mergersim init, nests(segment domestic) price(price) quantity(qu) ///
	marketsize(MSIZE) firm(firm) alpha(`alpha') sigmas(`sigma1' `sigma2')
quietly mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26)
sum M_price_ch if year == 1998 & country == 3&firm==15, meanonly
matrix pr_ch[`i',1] = r(mean)
sum M_price_ch if year == 1998 & country == 3&firm==26, meanonly
matrix pr_ch[`i',2] = r(mean)
}
clear
quietly svmat pr_ch , names(pr_ch)
sum pr_ch1 pr_ch2



