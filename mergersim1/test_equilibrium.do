discard
clear
capture compile

local xi1 .01
local xi2 .01
local epsilon .1
local averagecosts 1
local averagedelta 5

xtcreatepanel firm time , panelsize(2) panels(1000) equations(2)

gen delta =`averagedelta' + `xi1' * xi1 + `epsilon' * epsilon1
gen costs = `averagecosts' +  `xi2' * xi2 + `epsilon' * epsilon2
drop if costs < 0

gen ms = 1
exit
mergersim init , price(p) quantity(q) costs(costs) alpha(-4) delta(delta) marketsize(ms)
mergersim equilibrium , firm(firm) //method(fixedpoint) dampen(.25)
return list 

mergersim init , price(p) quantity(q) marketsize(ms) 
xtreg `r(logshares)' `r(pricevar)'
mergersim market , firm(firm)
mergersim simulate , buyer(2) seller(1) keep
mergersim results 

