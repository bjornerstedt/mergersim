/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Bjornerstedt and Frank Verboven
Version 2

Create instruments with product counts or sums of other products characteristics.
To use:

count_instruments [sumvars] [if] [in], by(varlist)
prefix(string) product(string) firm(string) 

sumvars - if specified count_instruments sums over variables, otherwise it counts products
by - required option specifiying groups to count/sum over
prefix - variables will be named with prefix followed by a consecutive number, defaults to 'inst'
product - the panelvar if not set
firm - the firm variable to create counts over firms, defaults to name 'firm' 
replace - drops all variables with prefix before creating instruments

***************************/

version 11

program count_instruments
	syntax [if] [in] , by(string) [ prefix(string) product(string) firm(string) SUMvariables(string) Replace ]
	marksample touse
	
	if "`prefix'" == "" {
		local prefix inst
	}
	quietly xtset
	local time = r(timevar)
	if "`product'" == "" {
		local product = r(panelvar)
	}
	if "`firm'" == "" {
		local firm firm
	}
	if "`replace'" != "" {
		capture drop `prefix'*
	}
	local i = 0
	quietly {
	tempvar groupsum1 groupsum2
	local list1 `by'
	local time date
	if "`sumvariables'" == "" {
		egen `prefix'`i' = count(`product') if `touse', by(`time')
		egen `prefix'f`i' = count(`product') if `touse', by(`time' `firm')
		label var `prefix'`i' "count(`product'), by(`time')"
		label var `prefix'f`i' "count(`product'), by(`time' `firm')"
		local `i++'
	}
	else {
		foreach sumvariable of local sumvariables {
			egen `groupsum1' = sum(`sumvariable') if `touse', by(`time')
			egen `groupsum2' = sum(`sumvariable') if `touse', by(`time')
			gen `prefix'`i' = `groupsum1'  - `sumvariable'
			gen `prefix'f`i' = `groupsum2'  - `sumvariable'
			label var `prefix'`i' "sum(`sumvariable') - `sumvariable', by(`time')"
			label var `prefix'f`i' "sum(`sumvariable') - `sumvariable', by(`time' `firm')"
			drop `groupsum1' `groupsum2' 
			local `i++'
		}
	}
	local group1 x
	while "`group1'" != "" {
		local group2 x
		local list2 `list1'
		local cat 
		foreach group of local list2 {
			local cat "`cat' `group'"
			if "`sumvariables'" == "" {
				egen `prefix'`i' = count(`product') if `touse', by(`time' `cat')
				egen `prefix'f`i' = count(`product') if `touse', by(`time' `firm' `cat')
				label var `prefix'`i' "count(`product'), by(`time' `cat')"
				label var `prefix'f`i' "count(`product'), by(`time' `firm' `cat')"
				local `i++'
			}
			else {
				foreach sumvariable of local sumvariables {
					egen `groupsum1' = sum(`sumvariable') if `touse', by(`time' `cat')
					egen `groupsum2' = sum(`sumvariable') if `touse', by(`time' `cat')
					gen `prefix'`i' = `groupsum1'  - `sumvariable'
					gen `prefix'f`i' = `groupsum2'  - `sumvariable'
					label var `prefix'`i' "sum(`sumvariable') - `sumvariable', by(`time' `cat')"
					label var `prefix'f`i' "sum(`sumvariable') - `sumvariable', by(`time' `firm' `cat')"
					drop `groupsum1' `groupsum2' 
					local `i++'
				}
			}
		}
		gettoken group1 list1 : list1
	}
	}
	display "Created `= 2*`i'' variables `prefix'*"
end
