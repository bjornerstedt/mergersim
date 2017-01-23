/*********************************************************************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: test.do 225 2014-08-17 09:19:25Z d3687-mb $

*********************************************************************************/
* This is a set of tests for the mergersim package
* Compares with numerical results of 2011-12-01

quietly {

version 11.2
clear all
discard
compile

capture program drop testresult
program testresult
	args vectorname index value
	matrix vect = r(`vectorname')
	scalar compval = el(vect,`index',1) 
	di as result "Result: " compval
	di "Compared with: `value'"
	if compval > 1 {
		assert abs( compval - `value')/compval < 10^-5
	}
	else {
		assert abs( compval - `value') < 10^-5
	}
end

if 0 {
	use cars1old
	egen yearcountry=group(year country)
	xtset co yearcountry
	gen MSIZE=pop/4		  	//assume 4 persons in a household
		// calibration of a constant expenditures demand instead of unit demand specification
	gen MSIZE1=ngdp/5   	// assume potential budget is 20% of GDP
	save test , replace
}
use test 
}

//local fp method(fixedpoint)
timer on 1

// ********************* TEST 1 ***********************

mergersim init, nests(segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear
*mergersim init, nests(segment domestic) unit p(princ) q(qu) m(MSIZE) f(firm) clear

xtreg M_ls horsepower fuel width height year yearsquared country2-country5 domestic princ M_lsjh M_lshg, fe 	//must use princ, does not work with M_price
mergersim market if year == 1998 & country==3 

// matlist r(elasticities)
testresult elasticities 1 -7.779042 

	// effect in Germany
mergersim simulate if year == 1998 & country == 3, sell(15) buy(26) detail error `fp' keep

// matlist r(M_price2)
testresult M_price2 1 .7499176 
// matlist r(M_price_ch)
testresult M_price_ch 1 .00265315 
// matlist r(M_marketsh2)
testresult M_marketsh2 1 .07859031 

sum qu M_quantity2 if year == 1998 & country==3 

// ********************* TEST 2 ***********************
	// effect in France
mergersim init, nests( segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) 
mergersim simulate if year == 1998 & country == 2, seller(15) buyer(26) error  
// matlist r(M_price2)
testresult M_price2 1 .8046489 


// ********************* TEST 3 ***********************
// extension: do a remedy, Peugeot owns brand 4 (citroen) and brand=20 (peugeot) and it must sell off citroen
// use newfirm option

gen firm_rem=firm
replace firm_rem=16 if firm==18
replace firm_rem=999 if brand==4

mergersim init, nests(segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear
mergersim simulate if year == 1998 & country == 2, newfirm(firm_rem) maxit(20) error `fp'
// matlist r(M_price2)
testresult M_price2 1 .8039549 

// ******************************************************************************************************

if "`0'" != "" {
	di "Short test completed"
	exit
}
// ********************* TEST 4 *************************************************************************
// extension: do a pure industry pass-on analysis, without a merger
// use efficiencies option

gen eff=0.5

mergersim init, nests(segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear
mergersim simulate if year == 1998 & country == 2, newfirm(firm) efficiencies(eff) method(fixedpoint) maxit(200) dampen(0.5)  error
// matlist r(M_price2)
testresult M_price2 1 .4356029  

// ********************* TEST 5 ***********************
// EFFICIENCIES

	// effect in Germany
mergersim init, nests( segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear

	// cost saving of 20%
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0.50) buyereff(0.50) method(fixedpoint) dampen(1)  error
// matlist r(M_price2)
testresult M_price2 1 .7323028 

	// Test running simulate twice
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0.50) buyereff(0.50) method(fixedpoint) dampen(1)  error
// matlist r(M_price2)
testresult M_price2 1 .7323028 

// mre after simulate
mergersim mre if year == 1998 & country == 3, seller(15) buyer(26)
// matlist r(mre)
testresult mre 3    .1081781   


// ********************* TEST 6 ***********************
// COLLUSION

	// effect in Germany, partial coordination of 50% both pre- and post-merger
mergersim init, nests( segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear
mergersim market if year == 1998 & country == 3, conduct(0.5)
// matlist r(elasticities)
testresult elasticities 1 -7.779042

mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) conduct(0.5) method(fixedpoint) error
// matlist r(M_price2)
testresult M_price2 1 .7546139

// ********************* TEST 7 ***********************
// ONE-LEVEL NESTED LOGIT

mergersim init, nests(segment) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear

	// fixed effects one-level nested logit
	xtreg M_ls horsepower fuel width height year yearsquared country2-country5 domestic princ M_lsjg, fe 	//must use princ, does not work with M_price

mergersim market if year == 1998 & country == 3
// matlist r(elasticities)
testresult elasticities 1 -6.191355 

mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0) buyereff(0) error `fp'
// matlist r(M_price2)
testresult M_price2 1 .7502598 

// ********************* TEST 8 ***********************
// SIMPLE LOGIT

	// two ways
	// specify one-level nest, but set sigma=0
mergersim init, nests(segment) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-4) sigmas(0) clear
mergersim market if year == 1998 & country == 3
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0) buyereff(0) `fp'
// matlist r(M_price2)
testresult M_price2 1 .7478045  

// ********************* TEST 8b ***********************

	// do not specify nest
mergersim init, unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-4) clear
mergersim market if year == 1998 & country == 3
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0) buyereff(0) error `fp'
// matlist r(M_price2)
testresult M_price2 1 .7478045  


// CALIBRATION OR ESTIMATION OF ALPHA, SIGMA1 AND SIGMA2

// ********************* TEST 9 ***********************
	// to illustrate: specify alpha and sigmas as rounded values of the previous estimates
mergersim init, nests(segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-1.2) sigmas (0.9 0.6) clear
mergersim market if year == 1998 & country == 3
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0) buyereff(0) error `fp'
// matlist r(M_price2)
testresult M_price2 1 .7500784  

// ********************* TEST 10 ***********************
	// no efficiencies
mergersim init, nests(segment domestic) ces price(pr) quantity(qu) marketsize(MSIZE1) firm(firm) alpha(-0.5) sigmas(0.9 .6) clear
mergersim market if year == 1998 & country == 3
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0) buyereff(0) error  `fp'
// matlist r(M_price2)
testresult M_price2 1 34375.15 

// ********************* TEST 11 ***********************
	// efficiencies of 10%
mergersim init, nests(segment domestic) ces price(pr) quantity(qu) marketsize(MSIZE1) firm(firm) alpha(-0.5) sigmas(0.9 .6) clear
mergersim market if year == 1998 & country == 3
mergersim mre if year == 1998 & country == 3, seller(15) buyer(26) 
// matlist r(mre)
testresult mre 1   26989.926 
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0.1) buyereff(0.1) error  `fp'
// matlist r(M_price2)
testresult M_price2 1 34177.48  

timer off 1


* Total time used *

timer list 1



************************************
************************************
**                                **
**        All tests passed        **
**                                **
************************************
************************************




