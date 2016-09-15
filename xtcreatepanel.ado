program xtcreatepanel
	syntax namelist , panels(integer) [panelsize(integer 0) equations(integer 1) ]
	gettoken panel namelist : namelist
	gettoken time : namelist
	tempvar cluster
	
	if `panelsize' {
		set obs `panelsize'
		generate `panel' = _n
	}
	generate `cluster' = 1
	if `equations' == 1 {
		generate xi = rnormal()
	}
	else {
		forvalues i = 1/ `equations' {
			generate xi`i' = rnormal()
		}
	}
	expandcl `panels' , cluster(`cluster') generate(`time')
	if `equations' == 1 {
		generate epsilon = rnormal()
	}
	else {
		forvalues i = 1/ `equations' {
			generate epsilon`i' = rnormal()
		}
	}
	xtset `panel' `time' 
	sort `time' `panel'
	order `time' `panel'
end
