/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: count_instruments.ado 224 2014-08-16 16:36:47Z d3687-mb $

***************************/

version 11

program count_instruments
	syntax [varlist] [if] [in] [ , prefix(string) product(string) firm(string)]
	marksample touse
	
	if "`prefix'" == "" {
		local prefix num
	}
	quietly xtset
	local time = r(timevar)
	if "`product'" == "" {
		local product = r(panelvar)
		local product product
	}
	if "`firm'" == "" {
		local firm firm
	}


	local cat 
	local group x
	local i = 0
	capture drop `prefix'*
	while "`group'" != "" {
		egen `prefix'`i' = count(`product'), by(`time' `cat')
		egen `prefix'f`i' = count(`product'), by(`time' `firm' `cat')
		local `i++'
		gettoken group varlist : varlist
		local cat "`group' `cat'"
	}
end


