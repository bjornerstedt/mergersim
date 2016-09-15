
clear all
quietly compile
use painkillers
drop if year > 2008
sort product

* Select nested or simple logit
* mergersim init, price(Ptablets) nests(form substance) quantity(Xtablets) marketsize(BL1) firm(firm) 
mergersim init, price(Ptablets)  quantity(Xtablets) marketsize(BL1) firm(product) 

local price `r(pricevar)'
local endog  _`price' `r(loggroupshares)'
local exog  sw sm time marketing1 month2-month12
local instr num* instrp* instrd*

clonevar _`price' = `price' //  demeaned price has underscore, non-demeaned is needed for cost calc.
gen sh = Xtablets / BL1

xtivreg2 M_ls `exog' (`endog' = `instr'), fe  
xtivreg2 M_ls `exog' (`endog' = `instr'), fe gmm robust


***************************************************************
* Demean vars:
tempvar mv
quietly {
foreach var of varlist M_ls `endog' `exog' `instr' {
	egen `mv'=mean(`var'), by(product)
	replace `var' = `var' - `mv'
	drop `mv'
}
}
* Gives same result as xtivreg2
ivreg2 M_ls `exog' (`endog' = `instr')  

* Here is the difference:
ivregress 2sls M_ls `exog' (`endog' = `instr') , nocons 
ivregress gmm M_ls `exog' (`endog' = `instr') , nocons 

* reg M_ls `endog' `exog' 

gmm (M_ls - {xb:`endog' `exog' } ), instruments(`instr' `exog' ,  noconstant)

timer on 1

****************************************************************
* Get all parameters in M_ls:varname format:
foreach var in `endog' `exog' {
	local params `params' d:`var'
}
di "`params'"

gmm J_resid, nequations(1) parameters(`params') ///
instruments(`instr' `exog' date, noconstant) twostep ///
winitial(unadjusted, independent) wmatrix(unadjusted) from(_`price' -1)  


* FE estimation of costs, with time as only parameter.
* To estimate with single product firms, include price and share options:

gmm J_resid_mk, nequations(2) parameters(`params' c:time) ///
instruments(`instr' `exog' date, noconstant) twostep ///
winitial(unadjusted, independent) wmatrix(unadjusted) from(_`price' -1) // price(`price') share(sh) panel(product)

timer off 1
timer list

asdf
* The following command can take 30 minutes 

timer on 2

* Estimating with conduct parameter in collperiod, without FE in costs:
gen collperiod = (year < 2004)

gmm J_resid_cond, nequations(2) parameters(`params' c:collperiod c:date c:_cons) ///
instruments(`instr' `exog' date, noconstant) twostep ///
winitial(unadjusted, independent) wmatrix(unadjusted) from(_`price' -1) 

timer off 2
timer list

