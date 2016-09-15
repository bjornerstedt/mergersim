clear all

use painkillers
drop if year > 2008
sort product

gen atc1 = substance != 5
mergersim init, price(Ptablets) revenue(PX1) marketsize(BL) firm(firm) 

local endog  Ptablets 
local exog  sw sm time marketing1 
local instr num* instrp* instrd*

if 0 {
* Demean vars:
tempvar mv
foreach var of varlist M_ls `endog' `exog' `instr' {
	egen `mv'=mean(`var'), by(product)
	by product: replace `var' = `var' - `mv'
	drop `mv'
}
}

* Get all parameters in M_ls:varname format:
foreach var of varlist `endog' `exog'   {
	local params `params' `var'
}
di "`params'"

gmm gmm_residuals2, nequations(2) parameters(d:Ptablets d:sw d:sm ///
d:marketing1  c:_cons c:packsize) instruments(`instr'  marketing1 sm sw packsize) depvar(M_ls) twostep


gmm gmm_residuals2, nequations(2) parameters( d:sw d:sm ///
d:marketing1  c:packsize) instruments(d: marketing1 sm sw ) /// 
instruments(c: packsize) depvar(M_ls) 

