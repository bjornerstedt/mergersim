* Test new options: upp newdelta newcosts jointelasticities

quietly {

version 11.2
clear all
discard
compile

use test 
}

// ********************* TEST 1 ***********************
 
mergersim init, nests(segment domestic) unit price(princ) quantity(qu) marketsize(MSIZE) firm(firm) clear
*mergersim init, nests(segment domestic) unit p(princ) q(qu) m(MSIZE) f(firm) clear

xtreg M_ls horsepower fuel width height year yearsquared country2-country5 domestic princ M_lsjh M_lshg, fe 	//must use princ, does not work with M_price
mergersim market if year == 1998 & country==3 , groupelasticities(segment) keepvars

matrix m = r(elas)
return list

matrix asdf = r(indelasticities)
matrix asdf = asdf[1..5 , 1..5]
matlist asdf

keep if year == 1998 & country==3
format M_e?? %10.7f
list M_ejj M_ejk M_ejl M_ejm in 1/5

mergersim simulate if year == 1998 & country == 3, sell(15) buy(26) detail keep upp 

// Equilibrium with a 10% cost increase, with no change in ownership
gen costs2 = 1.1*M_costs
gen newdelta = 1.1*M_delta
mergersim simulate if year == 1998 & country == 3, newdelta(newdelta) // newcosts(costs2) 

mergersim demand , ssnip(0.05)

generate newp = 1.1*princ

mergersim demand , price(newp)
