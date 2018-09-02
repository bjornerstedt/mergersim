/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: test.do 115 2012-11-25 16:39:22Z d3687-mb $

***************************/
* This is a short run of tests for Bjornerstedt and Verboven's mergersim package
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

use cars1

egen yearcountry=group(year country), label
xtset co yearcountry
gen MSIZE=pop/4		  	//assume 4 persons in a household
	// calibration of a constant expenditures demand instead of unit demand specification
gen MSIZE1=ngdp/5   	// assume potential budget is 20% of GDP


// BASIC MERGER SIMULATIONS

mergersim init, nests(segment domestic) ces(0) price(princ) quantity(qu) marketsize(MSIZE) firm(firm)

quietly xtreg M_ls horsepower fuel width height year yearsquared country2-country5 domestic princ M_lsjh M_lshg, fe 	//must use princ, does not work with M_price
mergersim market if year == 1998 & country==3
testresult elasticities 1 -7.779042 

	// effect in Germany
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0) buyereff(0) 
testresult M_price2 1 .7499176 
exit
	// efficiencies of 10%
mergersim init, nests(segment domestic) ces(1) price(pr) quantity(qu) marketsize(MSIZE1) firm(firm)
mergersim market if year == 1998 & country == 3, alpha(-0.5) sigmas(0.9 .6)
mergersim mre if year == 1998 & country == 3, seller(15) buyer(26) 
matlist r(mre)
testresult mre 1   26989.926 
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0.1) buyereff(0.1)  
testresult M_price2 1 34177.48  





************************************
************************************
**                                **
**        Short tests passed      **
**                                **
************************************
************************************







