/*******************************************************************************************
This program performs merger simulations for the four scenario's, ces=1 and ces=0
	* this is based on test.do for simulations and on old 4simulationanalysis for the output

*******************************************************************************************/

version 11
clear all
quietly compile
use painkillers
drop if year > 2008

local marketing marketing1

if 1 {
// ces
gen atc1 = substance != 5
mergersim init, nests( form  substance  )  price(Ptablets) revenue(PX1) marketsize(BL) firm(firm) 

xtivreg M_ls `marketing' sw sm time month2-month12 (`r(pricevar)' `r(loggroupshares)'  = num* ), fe //robust
*mergersim market if year == 2007 | year == 2008 ,groupelasticities(form)
mergersim market if year == 2008 & month == 12  , groupelasticities(form)
 
//tabstat M_costs if year == 2008 & month == 12 , by(firm)

mergersim simulate if year == 2007 | year == 2008 , seller(1) buyer(2)  
exit
}
if 1 {
// unit
mergersim init, nests(form substance) price(Ptablets1) quantity(Xtablets) marketsize(BL1) firm(firm) name(U)
quietly xtivreg2 `r(depvar)' `marketing' sw sm time month2-month12 (`r(pricevar)' `r(loggroupshares)'  = num* instrp* instrd* ),fe //robust	//CAUTION: it does not work with M_price
mergersim simulate if year == 2007 | year == 2008 , seller(1) buyer(2) name(U)
// table substance if year==2008&month==12,contents(mean M_price2 mean M_price_ch count M_price2 mean M_lerner)
exit
}

if 1 {
mergersim init, nests(form substance) ces price(P) revenue(PX1) marketsize(BL) name(P)

quietly xtivreg `r(depvar)' `marketing' sw sm time month2-month12 (`r(pricevar)' `r(loggroupshares)'  = num* instrp* instrd*), fe //vce(robust)
quietly mergersim market, firm(firm) predict  name(P) // Option prediction to generate predicted delta!

quietly xtreg P_costs time month2-month12 , fe 
mergersim equilibrium if year == 2007 | year == 2008, predict method(fixedpoint)  name(P)
	
mergersim simulate if year == 2007 | year == 2008 , seller(1) buyer(2) predict  name(P)
}

if 1 {
mergersim init, nests(form substance) ces price(P) revenue(PX1) marketsize(BL) name(B)
//mergersim init, nests(form substance) price(P) revenue(PX1) marketsize(BL1) name(B)

quietly xtivreg `r(depvar)' `marketing' sw sm time month2-month12 (`r(pricevar)' `r(loggroupshares)'  = num* instrp* instrd*), fe //vce(robust)
mergersim market if year == 2008 & month == 12, firm(firm) bootreps(1000) name(B) // Option prediction to generate predicted delta!

timer on 1
mergersim simulate if year == 2008 & month == 12 , seller(1) buyer(2) bootreps(1000) name(B) method(fixedpoint) //dampen(0.5)
timer off 1
timer list 1

}

mergersim results if year == 2008 & month == 12 , show(?_price_ch*)

