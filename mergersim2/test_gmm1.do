
version 11
clear all
compile
use painkillers

gen atc1 = substance != 5
mergersim init, nests( form atc1  substance  ) ces price(Ptablets) revenue(PX1) marketsize(BL) firm(firm) 

local endog  M_lp M_lsji M_lsih M_lshg
local exog  sw sm time marketing1 month2-month12 
local instr num* instrp* instrd*

xtivreg M_ls marketing1 sw sm time month2-month12 (M_lp M_lsji M_lsih M_lshg = num* instrp* instrd*), fe //robust

ivregress gmm M_ls `exog' (`endog' = `instr') 

reg M_ls `endog' `exog' 

gmm (M_ls - {xb:`endog' `exog' } - {b0}), instruments(`instr' `exog' )

* Get all parameters in M_ls:varname format:
foreach var in `endog' `exog' _cons  {
	local params `params' M_ls:`var'
}
di "`params'"

gmm gmm_residuals, nequations(1) parameters(`params') instruments(`instr' `exog' , constant) twostep

 asdf
*mergersim market if year == 2007 | year == 2008 ,groupelasticities(form)
*mergersim market if year == 2008 & month == 12  , groupelasticities(form)
 
//tabstat M_costs if year == 2008 & month == 12 , by(firm)

mergersim simulate if year == 2007 | year == 2008 , seller(1) buyer(2)  
exit

