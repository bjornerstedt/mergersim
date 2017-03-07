/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Bjornerstedt and Frank Verboven
Version 2

Create instruments with product counts or sums of other products characteristics.
To use:

count_instruments [list of variables to count over] [if] [in],
prefix(string) product(string) firm(string) SUMvariable(string)

prefix - variables will be named with prefix followed by a consecutive number
product - the panelvar if not set
firm - the firm variable to create counts over firms, defaults to name 'firm' 
SUMvariable - take sums of other products sumvariable rather than counting.

***************************/

version 11

program count_instruments
	syntax [varlist] [if] [in] [ , prefix(string) product(string) firm(string) SUMvariable(string)]
	marksample touse
	
	if "`prefix'" == "" {
		local prefix num
	}
	quietly xtset
	local time = r(timevar)
	if "`product'" == "" {
		local product = r(panelvar)
	}
	if "`firm'" == "" {
		local firm firm
	}

	tempvar groupsum1 groupsum2
	local list1 `varlist'
	local i = 0
	local time date
	capture drop `prefix'*
	local group1 x
	while "`group1'" != "" {
		local group2 x
		local list2 `list1'
		local cat 
		foreach group of local list2 {
			local cat "`cat' `group'"
			if "`sumvariable'" == "" {
				egen `prefix'`i' = count(`product'), by(`time' `cat')
				egen `prefix'f`i' = count(`product'), by(`time' `firm' `cat')
				label var `prefix'`i' "count(`product'), by(`time' `cat')"
				label var `prefix'f`i' "count(`product'), by(`time' `firm' `cat')"
			}
			else {
				egen `groupsum1' = sum(`sumvariable'), by(`time' `cat')
				egen `groupsum2' = sum(`sumvariable'), by(`time' `cat')
				gen `prefix'`i' = `groupsum1'  - `sumvariable'
				gen `prefix'f`i' = `groupsum2'  - `sumvariable'
				label var `prefix'`i' "sum(`sumvariable') - `sumvariable', by(`time' `cat')"
				label var `prefix'f`i' "sum(`sumvariable') - `sumvariable', by(`time' `firm' `cat')"
				drop `groupsum1' `groupsum2' 
			}
			local `i++'
		}
		gettoken group1 list1 : list1
	}
end
