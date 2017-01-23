/***************************

MERGERSIM: Merger Simulation Package

$Id: test_merger.do 187 2013-04-15 18:41:18Z d3687-mb $

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

capture program drop testresult
program testresult
	args min max
	sum  M_price2 if year==2008 & month ==12 & firm == 1, meanonly
	di "Result: `r(mean)'"
	assert r(mean) < `max' & r(mean) > `min'
end

// Run new versions of ado-files and Mata code

}
**************************************************************************************** 

// Generate dataset and estimates
if 0 {
	// Global variables to select treatment
	global CES 1 
	global level 2 // Set to 3 to get subsubgroup estimate
	global yd 0 // Set yd to 1 to get year dummies	
	global sel2f3s 1 // Select 2 forms 3 substances 
	global nochildren 0 // Use only adult forms

	do dataset
	
	// Note wrong shares for linear
//	mergersim_logit_shares 
	drop if s==0

	count_instruments form , prefix(num)
	quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`r(pricevar)' M_lsjg = num*),fe
	estimates save ces1, replace
	
	count_instruments form substance, prefix(num)
	quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`r(pricevar)' M_lsjh M_lshg = num*),fe
	estimates save ces2, replace
	
	quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`r(pricevar)' M_lsjh M_lshg = num* ),fe
	estimates save lin2, replace
	
	save base, replace
	// Add single level and linear estimates here
}


capture program drop ces_nested_logit_demand
program ces_nested_logit_demand
	args nestcount
	local mm `.M.prefix'
	local Q `mm'revenue
	tempvar totQ
	quietly {
	egen `totQ' = sum(`Q'), by(time)
	sum `totQ', meanonly
	local medincome = 649144.4 // time varying potential budget measure (very similar to budget0) (649144 is income in median period time=84)
	gen BL = 2*r(mean)*GDPnom/`medincome'	
	}
//	mergersim_logit_shares
	count_instruments `r(nests)', prefix(num)
	if `nestcount' == 1 {
		quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`r(pricevar)' M_lsjg = num*),fe
	}
	else {
		quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`r(pricevar)' M_lsjh M_lshg = num*),fe
	}
end

capture program drop nested_logit_demand
program nested_logit_demand
	mergersim_set method 2 // Newton
	
// Create quantity variable and potential market
	local Q M_quantity
	tempvar totQ
	egen `totQ' = sum(`Q'), by(time)
	sum `totQ', meanonly
	gen BL = 2*r(mean)				// time invariant potential budget measure	
	
	count_instruments `r(nests)', prefix(num)
		
	quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`r(pricevar)' M_lsjh M_lshg = num* ),fe
end


***************************************
// Two level nests

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
//mergersim_logit_shares
count_instruments `r(nests)', prefix(num)
quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`pricevar' M_lsjh M_lshg = num*),fe

mergersim market if year == 2008 & month ==12, firm(firm) 

mergersim mre , buyer(1) seller(2)

// mergersim costs
mergersim simulate if year == 2008, seller(1) buyer(2) sellereff(0.25) buyereff(0.25) error

//mergersim results if year==2008, marketshares

//table substance if year==2008&month==12,contents(mean Ptablets mean M_price2 mean M_price_ch mean M_price2sd mean M_lerner)

//mergersim results if year == 2008 & month == 12 ,  rowvars(firm substance)
//return list
matlist r(M_price2)
matlist r(M_marketsh2)

// testresult  1.3613258 1.3613259 
testresult  1.3647 1.3648 

***************************************
// Specify alpha and sigmas and test just dropping all M_ variables


// To test manual input in next test
local alpha = _b[M_lp]
local sigma1 =_b[M_lsjh]
local sigma2 = _b[M_lshg]

drop M_*
//drop formsubstance

//mergersim init, nests(form substance) ces price(P) revenue(PX1) alpha(`alpha') sigmas(`sigma1' `sigma2')  marketsize(BL)
mergersim init, nests(form substance) ces price(P) revenue(PX1)   marketsize(BL)
quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`pricevar' M_lsjh M_lshg = num*),fe

quietly generate newowner = firm
quietly replace newowner =  2 if firm == 1
quietly generate efficiencies = 0
quietly replace efficiencies = 0.25 if newowner ==2


mergersim simulate if year == 2008 , firm(firm) newfirm(newowner) efficiencies(efficiencies) method(fixedpoint) error

testresult  1.3647 1.3648 


***************************************
// Large efficiencies
mergersim init, nests(form substance) unit price(P) revenue(PX1) marketsize(BL) 
local pricevar `r(pricevar)'

//mergersim_logit_shares
count_instruments `r(nests)', prefix(num)
quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`pricevar' M_lsjh M_lshg = num*),fe

// mergersim costs
mergersim simulate if year == 2008, firm(firm) seller(1) buyer(2) sellereff(0.75) buyereff(0.75) method(fixedpoint) error

// testresult  1.3613258 1.3613259 

***************************************
// One level nests

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

mergersim init, nests(form) price(P) ces revenue(PX1) marketsize(BL)
local pricevar `r(pricevar)'

	count_instruments `r(nests)', prefix(num)
quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`pricevar' M_lsjg = num*),fe

mergersim market, firm(firm)

mergersim simulate if year == 2008 & month == 12, seller(1) buyer(2) sellereff(0.25) buyereff(0.25) error
// testresult  1.206101 1.206102
testresult  1.20601 1.20602

***************************************
// Linear with two level nests
use painkillers, clear
	tempvar totQ
	egen `totQ' = sum(X), by(time)
	sum `totQ', meanonly
	gen BL = 2*r(mean)				// time invariant potential budget measure	
	

mergersim init, nests(form substance) price(P) quantity(X) marketsize(BL)
local pricevar `r(pricevar)'

	count_instruments `r(nests)', prefix(num)
	quietly xtivreg M_ls marketing1 sw sm time month2-month12 (`pricevar' M_lsjh M_lshg = num* ),fe

mergersim simulate if year == 2008 & month == 12 , seller(1) buyer(2)  firm(firm) error // method(fixedpoint) // maxit(2000)

testresult  1.564495 1.564497
//testresult    1.563653 1.563654

***************************************
// Linear with no nests
use painkillers, clear
	
	tempvar totQ
	egen `totQ' = sum(X), by(time)
	sum `totQ', meanonly
	gen BL = 2*r(mean)				// time invariant potential budget measure	
	
		
mergersim init, price(P) quantity(X) marketsize(BL) firm(firm) alpha(-4) 
local pricevar `r(pricevar)'
//	mergersim_logit_shares
	 xtreg M_ls `pricevar' marketing1 sw sm time month2-month12 ,fe
//	count_instruments , prefix(num)
//	 xtivreg M_ls marketing1 sw sm time month2-month12 (`r(pricevar)' = num* ),fe

//mergersim market 
mergersim simulate if year == 2008 & month == 12 , conduct(.1) seller(1) buyer(2) error // method(fixedpoint)
mergersim mre if year == 2008 & month == 12

//testresult  1.564495 1.564497

/*
mergersim init, price(P) quantity(X) marketsize(BL) firm(firm) alpha(-1) sigmas(2 22)
*/
***************************************
***************************************
*                                     *
*    Test of mergersim successful     *
*                                     *
***************************************
***************************************
