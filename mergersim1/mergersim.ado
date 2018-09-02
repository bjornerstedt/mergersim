/***************************
*! version 1.0 2013-04-04

*! MERGER SIMULATION PACKAGE FOR STATA
*! Copyright Jonas Björnerstedt and Frank Verboven 2011
*! Swedish Competition Authority and University of Leuven

$Id: mergersim.ado 194 2013-04-22 11:44:06Z d3687-mb $

***************************/
version 11.2

program mergersim , rclass
	syntax anything [if] [in] [, prefix(string) demand(string) name(namelist max=1) clear *]
	
	local subcommands init market simulate results mre equilibrium demand
	gettoken subcommand anything : anything
	
	if strpos("`subcommands'", "`subcommand'")==0 {
		display "Error: `subcommand' is not a valid subcommand of merger."
		display "The valid subcommands are: `subcommands'."
		error 199
	}
	if "`name'" == ""  {
		local name M
	}
	
	if "`subcommand'" == "init" {
		// Ask for confirmation if M_ variables exist and mergersim has NOT been run
		capture .`name'.prefix 	
		if _rc {
			local test .`name'.prefix
			capture sum `test'* 
			if !_rc & "`clear'" == "" { 
				di "Files with prefix `prefix' already exist. "
				local answer
				while upper("`answer'") != "Y" & upper("`answer'") != "N" {
					di "Do you want to delete these and clear simulation (Y/N)?" _request(_answer)
					if upper("`answer'") == "N" {
						error 1
					}
				}
			}
		}
		.`name' = .mergersim_merger.new `name'	`demand'	
	}
	else {
		if "`.`name'.prefix'" == "" {
			di as error "mergersim init has to be run first."
			error 99
		}
	}

	if "`options'" != "" {
		local comma , 
	}
	if "`subcommand'" == "market" | "`subcommand'" == "demand" {
		local subcommand `subcommand'calc
	}
	return clear
	.`name'.`subcommand' `anything' `if' `in' `comma' `options'	
	return add
end
