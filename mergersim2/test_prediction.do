/***************************

MERGERSIM: Merger Simulation Package

$Id: test_merger.do 138 2013-03-14 18:31:30Z d3687-mb $

***************************/
version 11.0

quietly {

****************************************************************************************
capture program drop clear_all
program clear_all
	discard
	macro drop _all
	clear all
	mata: mata clear
end

clear_all
compile

}
**************************************************************************************** 

use painkillers, clear
generate X0 = X/10^6

local Q PX1
quietly {
tempvar totQ
local medincome = 649144.4 // time varying potential budget measure (very similar to budget0) (649144 is income in median period time=84)
egen `totQ' = sum(`Q'), by(time)
sum `totQ', meanonly
gen BL = 2*r(mean)*GDPnom/`medincome'	
}

mergersim init, nests(form substance) ces price(P) revenue(PX1) marketsize(BL) 

local pricevar `r(pricevar)'
count_instruments `r(nests)', prefix(num_)
quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`pricevar' M_lsjh M_lshg = num*),fe


if 1 {
	mergersim market, firm(firm) predict // Option prediction to generate predicted delta!
	// Get predicted costs and delta 
	
	xtreg M_costs time month2-month12 , fe
//	predict costs , xbu
	
	mergersim equilibrium if year == 2008, predict	
	
} 
else {
	mergersim market, firm(firm) 
}

mergersim simulate if year == 2008 & month ==12, seller(1) buyer(2) predict // sellereff(0.25) buyereff(0.25) error
