version 11.2
clear all
discard
compile

use test 

// ********************* TEST 8 ***********************
// SIMPLE LOGIT
if 0 {

	// two ways
	// specify one-level nest, but set sigma=0
mergersim init, nests(segment) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-4) sigmas(0) clear
mergersim market if year == 1998 & country == 3
matrix elas = r(elasticities)
local ejj = el(elas,1,1)
local ejk = el(elas,1,2)
di `ejj'
di `ejk'
mergersim init, nests(segment) unit price(princ) quantity(qu) marketsize(MSIZE) alpha(-4) sigmas(0) firm(firm) clear
mergersim market if year == 1998 & country == 3, elasticities(`ejj' `ejk' )

exit
}
if 0 {

// ********************* TEST 8b ***********************

	// do not specify nest
mergersim init, unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-4) clear
mergersim market if year == 1998 & country == 3
matrix elas = r(elasticities)
local ejj = el(elas,1,1)
di `ejj'
mergersim init, unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear
mergersim market if year == 1998 & country == 3, elasticities(`ejj' )
exit
}

if 1 {
// ********************* TEST 9 ***********************
	// to illustrate: specify alpha and sigmas as rounded values of the previous estimates
mergersim init, nests(segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) alpha(-1.2) sigmas (0.9 0.6) clear
mergersim market if year == 1998 & country == 3
matrix elas = r(elasticities)
local ejj = el(elas,1,1)
local ejk = el(elas,1,2)
local ejl = el(elas,1,3)
di `ejj'
di `ejk'
di `ejl'
mergersim init, nests(segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear
mergersim market if year == 1998 & country == 3, elasticities(`ejj' `ejk' `ejl')

}
if 1 {

// ********************* TEST 10 ***********************
	// no efficiencies
mergersim init, nests(segment domestic) ces price(pr) quantity(qu) marketsize(MSIZE1) firm(firm) alpha(-0.5) sigmas(0.9 .6) clear
mergersim market if year == 1998 & country == 3
matrix elas = r(elasticities)
local ejj = el(elas,1,1)
local ejk = el(elas,1,2)
local ejl = el(elas,1,3)
di `ejj'
di `ejk'
di `ejl'
mergersim init, nests(segment domestic) ces price(pr) quantity(qu) marketsize(MSIZE1) firm(firm) clear
mergersim market if year == 1998 & country == 3, elasticities(`ejj' `ejk' `ejl')

}
