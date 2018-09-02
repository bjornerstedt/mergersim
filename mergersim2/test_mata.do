/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: test.do 161 2013-04-04 15:58:46Z d3687-mb $

***************************/

quietly {
version 11.2
clear all
discard
compile

capture program drop testresult
program testresult
	args vectorname index value
	matrix vect = `vectorname'
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

capture program drop getsample
program getsample
	syntax [if] [in]
	marksample touse
	capture drop M_sample
	quietly generate M_sample = `touse'
end
}
use test

if  0 {
mergersim init, unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-4) clear
mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26)
exit
}

// ***************************************************
// mergersim init, unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-4) clear
local marketsize MSIZE
local alpha -4
local price princ 

mata: M = Merger()
mata: D = LogitDemand()

mata {
	M.marketvar = "yearcountry"
	D.marketvar = "yearcountry"
	D.alpha = -4
	D.estimate = "M_estimate"
	D.delta = "M_delta"
	D.nest1 = ""
	D.nest2 = ""
	D.marketsize = "`marketsize'"
	D.nests = 0
	D.valueshares = 0
	D.ces = 0
	M.init()
	D.parameters()
}
return list

// ***************************************************
// mergersim market if year == 1998 & country==3
getsample if year == 1998 & country==3
matrix M_estimate = (-4)
quietly generate double M_share = qu/`marketsize'
tempvar totQ shareoutside
egen `totQ' = sum(qu) , by(yearcountry)	
quietly generate double `shareoutside' = (`marketsize'-`totQ')/`marketsize'
quietly generate double M_ls = log(M_share/`shareoutside')
quietly generate M_delta = M_ls + `alpha' * princ
quietly generate double M_costs = .
egen firm2 = group(firm)
mata { 
	M.m[1].price = "princ"
	M.m[1].initprice = "princ"
	M.m[1].quantity = "qu" 
	M.m[1].conduct = 0
	M.m[1].firm = "firm2"
	M.m[1].costs = "M_costs"
	M.costestimate(D, "M_sample", 1) 
}
return list

// ***************************************************
//mergersim quantity if year == 1998 & country == 3, seller(15) buyer(26)

quietly generate M_share3 = .
mata { 
	M.m[2].param.method = 2
	M.m[3].conduct = 0
	M.m[3].firm = "firm"
	M.m[3].costs = "M_costs"
	M.m[3].quantity = "qu" 
	
	M.m[3].price = "princ"
	M.m[3].initprice = "princ"

	M.demand(D, "M_sample", 3)
}
gen M_quantity3 = M_share3 * `marketsize'
return list
sum qu M*3 if year == 1998 & country == 3
di r(p)
di r(s)

// ***************************************************
//mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26)
quietly generate M_quantity2 = .
quietly generate M_firm2 = firm2
replace M_firm2 = 26 if M_firm2 == 15

quietly generate M_share2 = M_share
quietly generate M_price2 = princ
mata { 
	M.m[2].param.method = 1
	M.m[2].conduct = 0
	M.m[2].firm = "M_firm2"
	M.m[2].costs = "M_costs"	
	M.m[2].quantity = "M_quantity2" 
	M.m[2].price = "M_price2"
	M.m[2].initprice = "princ"

	M.equilibrium(D, "M_sample", 2)
}
return list
preserve
quietly generate M_price_ch = (M_price2 - princ)/princ
collapse princ M_price2 M_price_ch if M_sample , by( firm) 

tabdisp firm , c(princ M_price2 M_price_ch) cellwidth(18) stubwidth(20) format(%9,3f) 
mkmat M_price2 
restore
testresult M_price2 1 .7478045  

//sum pr M_price2 M_price_ch if year == 1998 & country == 3


************************************
************************************
**                                **
**        All tests passed        **
**                                **
************************************
************************************




