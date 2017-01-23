/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: test.do 118 2012-12-02 14:00:15Z d3687-mb $

***************************/
* Various tests

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

use test

************************************************************************************************************
if 1 {

mergersim init, nests(segment domestic) price(princ) ces quantity(qu) marketsize(MSIZE) firm(firm) // alpha(-.5) sigmas(.9, .6)

quietly xtreg `r(depvar)' horsepower fuel width height year yearsquared country2-country5 ///
domestic `r(pricevar)' `r(loggroupshares)', fe 	

mergersim market  //, conduct(0.2) keep
//mergersim market if year == 1998 & country == 3 , conduct(0.2) keep
// mergersim mre if year == 1998 & country == 3 , seller(15) buyer(26) 

mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) maxit(4)
return list
mergersim mre
exit

mergersim results if year == 1998 & country == 3 , marketshares value
mergersim results if year == 1998 & country == 3 
exit

mergersim simulate if year == 1998 & country == 4, seller(15) buyer(26) newconduct(0.1) //add 
//mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) newconduct(0)
exit
mergersim demand
rename M_quantity3 qtest
generate newp = 1.05*princ
mergersim demand , price(newp)
generate qpercent = (qu - M_quantity3)/qu

sum princ newp qu qtest M_quantity3 qpercent

mergersim demand if year == 1998 & country == 3, ssnip(0.05)

exit
//mergersim market 

//mergersim mre
//mergersim results if year == 1998 & country == 3, marketshares
//mergersim results if year == 1998 & country == 3, marketshares
}
if 0 {
***************************************************************************
mergersim init, nests( segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm)

quietly xtreg `r(depvar)' horsepower fuel width height year yearsquared country2-country5 ///
domestic `r(pricevar)' `r(loggroupshares)', fe 	

mergersim market if year == 1998 

mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0.50) buyereff(0.50) ///
method(fixedpoint)  dampen(0.5)

mergersim init, nests( segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) name(P)

quietly xtreg `r(depvar)' horsepower fuel width height year yearsquared country2-country5 ///
domestic `r(pricevar)' `r(loggroupshares)', fe 	

mergersim market if year == 1998 & e(sample), name(P)

mergersim simulate if year == 1998 & country == 3 & e(sample), seller(15) buyer(26) sellereff(0.50) buyereff(0.50) ///
method(fixedpoint)  dampen(0.5) name(P)
generate M_price_ch = (M_price2 - princ)/princ
generate P_price_ch = (P_price2 - princ)/princ
mergersim results , show(?_price_ch)
 sum ?_*
 }
 
 ***************************************************************************

.M = .mergersim_merger.new M

.M.init, nests( segment domestic) price(princ) quantity(qu) marketsize(MSIZE) firm(firm)

quietly xtreg `r(depvar)' horsepower fuel width height year yearsquared country2-country5 ///
domestic `r(pricevar)' `r(loggroupshares)', fe 	

.M.market
.M.simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0.50) buyereff(0.50) method(fixedpoint)  dampen(0.5)

.N = .mergersim_merger.new N

.N.init, nests( segment) price(princ) quantity(qu) marketsize(MSIZE) firm(firm) 

quietly xtreg `r(depvar)' horsepower fuel width height year yearsquared country2-country5 ///
domestic `r(pricevar)' `r(loggroupshares)', fe 	

.N.market

.N.simulate if year == 1998 & country == 3, seller(15) buyer(26) sellereff(0.50) buyereff(0.50) method(fixedpoint)  dampen(0.5)

 sum ?_*
