{smcl}
{* *! version 0.5  01may2010}{...}
{cmd:help mergersim}
{hline}

{title:Title}

{phang}
{bf:mergersim} {hline 2} Merger Simulation Package


{title:Syntax}

{phang}
Initialization and demand specification 

{p 8 16 2}{cmd:mergersim init} {ifin} [{cmd:,} {it:{help mergersim##init_options:init_options}}]

{phang}
Market specification and cost calculation 

{p 8 16 2}{cmd:mergersim market} {ifin} [{cmd:,} {it:{help mergersim##market_options:market_options}}]

{phang}
Merger simulation 

{p 8 16 2}{cmd:mergersim simulate} {ifin} [{cmd:,} {it:{help mergersim##simulate_options:simulate_options}}]

{phang}
Minimum required efficiencies 

{p 8 27 2}{cmd:mergersim mre} {ifin} [{cmd:,} {it:{help mergersim##mre_options:mre_options}}]


{marker init_options}{...}
{synoptset 20 tabbed}{...}
{synopthdr :init_options}
{synoptline}
{syntab:Required}
{synopt:{opth mark:etsize(varname)}}Potential market size (including outside good){p_end}
{syntab:Two of three required}
{synopt:{opth q:uantity(varname)}}quantity variable{p_end}
{synopt:{opth p:rice(varname)}}price variable{p_end}
{synopt:{opth r:evenue(varname)}}revenue variable{p_end}
{syntab:Optional}
{synopt:{opth nests(varlist)}}nesting structure, variables specifying group and possibly subgroup (in that order){p_end}
{synopt:{opt unit:demand}}unit demand specification (default){p_end}
{synopt:{opt ces:demand}}constant expenditure specification{p_end}
{synopt:{opt a:lpha(#)}}value of price parameter (alpha){p_end}
{synopt:{opt s:igmas(# [#])}}value(s) of nesting parameter(s) (sigma's){p_end}
{synopt:{opt n:ame(string)}}change name of simulation from default name M. {p_end}

{marker market_options}{...}
{synoptset 20 tabbed}{...}
{synopthdr :market_options}
{synoptline}
{syntab:Required}
{synopt:{opth f:irm(varname)}}firm variable for pre-merger ownership{p_end}
{syntab:Optional}
{synopt:{opt conduct(#)}}degree of collusion between firms, between 0 and 1 with default 0{p_end}
{synopt:{opt name(string)}}change name of simulation from default name M. {p_end}

{marker simulate_options}{...}
{synoptset 20 tabbed}{...}
{synopthdr :simulate_options}
{synoptline}
{syntab:Required}
{synopt:{opth f:irm(varname)}}firm variable, if it has not been set in {cmd: mergersim market}{p_end}
{syntab:Alternative required options}
{synopt:{opt buy:er(#)}}buyer id as specified in firm variable{p_end}
{synopt:{opt sell:er(#)}}seller id as specified in firm variable{p_end}
{synopt:{opth newf:irm(varname)}}firm variable for post-merger ownership. Alternative to buyer and seller {p_end}
{syntab:Optional}
{synopt:{opt buyereff(#)}}buyer efficiency gains (% cost saving), between 0 and 1 with default 0{p_end}
{synopt:{opt sellereff(#)}}seller efficiency gains (% cost saving), between 0 and 1 with default 0{p_end}
{synopt:{opth efficiencies(varname)}}variable with efficiency gains after merger (% cost saving) {p_end}
{synopt:{opt conduct(#)}}degree of joint profit maximization between firms, between 0 and 1 with default 0{p_end}
{synopt:{opt newconduct(#)}}new degree of joint profit maximization between firms after merger, default conduct{p_end}
{synopt:{opt method(fixedpoint|newton)}} fixed point or Newton method (default) for solving Bertrand-Nash equilibrium{p_end}
{synopt:{opt maxit(#)}}maximum number of iterations in finding equilibrium{p_end}
{synopt:{opt dampen(#)}}dampening factor in fixed point iteration (between 0 and 1){p_end}
{synopt:{opt keep:vars}}do not drop any generated variables after simulation{p_end}
{synopt:{opt name(string)}}change name of simulation from default name M {p_end}
{synopt:{opt detail}}show market shares, changes in surplus and concentration measures in mergersim simulate{p_end}

{marker mre_options}{...}
{synoptset 20 tabbed}{...}
{synopthdr :mre_options}
{synoptline}
{syntab:Optional}
{synopt:{opt buy:er(#)}}buyer id{p_end}
{synopt:{opt sell:er(#)}}seller id{p_end}
{synopt:{opth newf:irm(varname)}}firm variable for post-merger ownership. Alternative to buyer and seller {p_end}
{synopt:{opt name(string)}}change name of simulation from default name M {p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{cmd:mergersim} performs a merger simulation, using the subcommands {opt init}, {opt market}, {opt simulate}. 
{cmd:mergersim init} must be invoked first to initialize the settings. {cmd:mergersim market} calculates the price elasticities and marginal costs. 
{cmd:mergersim simulate} performs a merger simulation, it automatically invokes 
{cmd:mergersim market} if the command has not been called by the user. {cmd:mergersim mre} can be invoked
after {cmd:mergersim init}. In addition to displaying results, mergersim creates various variables at each 
step. By default the names of these variables begin with M_. 

{pstd}
{cmd:mergersim init} initializes the merger, erasing all parameters and generated variables of previous simulations. 
The command has to be invoked first. 

{pstd}
{cmd:mergersim init} also generates the variables necessary to estimate the demand parameters (alpha and sigmas) using a linear (nested) logit regression, 
along the lines of Berry (1994) and the extensions of Björnerstedt and Verboven (2012). The names of the market share and price variables to
use in the regression will depend on the demand specification, and are shown in the display output of {cmd:mergersim init}. Alternatively, the
demand parameters can be calibrated with the {opt alpha()} and {opt sigmas()} options, rather than being estimated. 

{pstd}
{cmd:mergersim market} calculates the price elasticities and the marginal costs, based on demand parameters and market conditions. It uses the demand parameter estimates of the 
most recent regression after {cmd:mergersim init}, unless explicitly specified in the {opt alpha} and {opt sigmas} options. It must be invoked prior
to {cmd:mergersim simulate}. If demand parameters are not explicitly specified, {cmd:mergersim market} looks for
the values in the most recent estimation. 

{pstd}
{cmd:mergersim simulate} performs the merger simulation. The results of the simulation are saved in generated
variables with prefix M_ by default. All but the most important variables are dropped by default upon command 
completion. They can be retained by specifying the {opt keepvars} option.

{pstd}
{cmd:mergersim mre} calculates minimum required efficiencies. It can be invoked at any point after {cmd:mergersim init}. 

{title:Options}

{pstd}
The {cmd:mergersim} program has a set of options, some of which are required. A merger simulation
has to specify the price, quantity, and nesting variables, as well as the identity
of the buying and selling firms. By default, the seller is completely 
acquired by the buyer. To model more complex changes in ownership, the {cmd:newfirm(varname)} 
option can alternatively be used to specify new ownership. It is also possible to specify efficiencies (percentage
marginal cost savings) and conduct (pre-merger and post-merger) in the market.

{dlgtab:Demand and market specification}

{pstd}
The demand and market specification are set in {cmd:mergersim init} and {cmd:mergersim market} (and in {cmd:mergersim simulate}
if {cmd:mergersim market} is not explicitly invoked by the user).

{pstd}
Any two of {opt price}, {opt quantity} or {opt revenue} have to be used to specify the corresponding variables.

{phang}
{opth q:uantity(varname)} quantity variable

{phang}
{opth p:rice(varname)} price variable

{phang}
{opth r:evenue(varname)} revenue variable

{phang}
{opth nests(varlist)} one or two nesting variables. The outer nest is specified first. If only one variable is specified,
a one-level nested logit model applies. If the option is not specified, a simple logit model applies.

{phang}
{opth mark:etsize(varname)} Variable specifying the potential size of market (total number of potential buyers in unit 
demand specification, total potential budget in constant expenditures specification)

{phang}
{opt ces:demand} specify constant expenditure specification rather than the default unit demand.

{phang}
{opt unit:demand} specify unit demand specification (default).

{phang}
{opth f:irm(varname)} integer variable, indexing the firm owning the product.

{phang}
{opt conduct(#)} The degree of joint profit maximization between firms before the merger, in percentage terms (number between 0 and 1).
It measures the fraction of the competitors' profits that firms take into account when setting their own prices.

{phang}
{opt alpha(#)} Specify a value for the alpha parameter rather than using an estimate. Note that this option has no effect
if mergersim market has been run.

{phang}
{opt sigmas(# [#])} Specify a value for the sigma parameter(s) rather than using an estimate. In the two-level
nested logit, the first sigma corresponds to the log share of the product in the subgroup and the second corresponds
to the log share of the subgroup in the group.

{phang}
{opt name(string)} Specify a name for the simulation. Variables created will have the specified name followed by an 
underscore character, rather than the default M_. Can be used with all the mergersim subcommands.

{dlgtab:Merger specification}

{pstd}
The merger specification is set in {cmd:mergersim simulate}, or in {cmd:mergersim mre}.

{pstd}
Either the identity of buyer and seller firms or the new ownership structure have to be specified. The identity 
corresponds to the value in the variable specified with the {opt firm} option.

{phang}
{opt buyer(#)} buyer id in firm variable

{phang}
{opt seller(#)} seller id in firm variable

{phang}
{opth newf:irm(varname)} A variable that specifies post merger ownership in more detail than the buyer and seller options. 
For example, it can be used to simulate divestitures or two cumulative mergers, by manually constructing a new firm ownership variable 
that differs from the firm variable specified with the {opt firm} option.

{pstd}
Efficiency gains, in terms of percentage reduction in marginal costs, can either be specified for all seller and buyer products 
using the {opt buyereff} and {opt sellereff} option, or product by product with the {opt efficiencies} option.

{phang}
{opt buyereff(#)} The efficiency gain of all products of the buyer firm after the merger. A value of 0 (default) indicates no efficiency gain. 
For example, to incorporate a 10% efficiency gain, specify the option: {cmd:buyereff(0.1)}.

{phang}
{opt sellereff(#)} The efficiency gain of all products of the seller firm after the merger.  

{phang}
{opth efficiencies(varname)} specifies a variable for efficiency gains more generally (i.e. product by product), where 
for example .2 is a 20% decrease in marginal costs and 0 no change.

{phang}
{opth newc:osts(varname)} specifies a variable for post-merger costs.

{phang}
{opt newconduct(#)} The degree of joint profit maximization between firms after the merger, in percentage terms. With a conduct value of
1, the profits of other firms are as important as own profits.

{dlgtab:Computation}

{pstd}
The computation options can be set in {cmd:mergersim simulate}, where the post-merger Nash equilibrium is computed.

{phang}
{opt method(string)} Specify the method used to find post-merger Nash equilibrium. It can be specified as {opt fixedpoint} or {opt newton} (default). 
The Newton method starts with one iteration of the fixedpoint method.

{phang}
{opt maxit(#)} Maximum number of iterations in the solver methods.

{phang}
{opt dampen(#)} An initial dampening factor lower than the default 1 in the fixed point method. If fixedpoint
does not converge, the method automatically tries a dampening factor of half of the initial dampening.

{dlgtab:Display and results}

{phang}
{opt detail} Show also market shares in {cmd:mergersim simulate}. These market shares are relative to total actual sales (excluding the outside good).
Market shares are in terms of volumes for the unit demand specification and in value terms for the constant 
expenditure. Changes in consumer and producer surplus and in the Herfindahl Hirshman index are also displayed.

{phang}
{opt keep:vars} Specifies that all generated variables should be kept after simulation, calculation of elasticities
or minimal required efficiencies. 

{title:Remarks}

{pstd}
The merger simulation program was created by Jonas Björnerstedt and Frank Verboven. For detailed information on the 
merger simulation program, see {browse "http://www.bjornerstedt.org/stata/merger"}.

{title:Examples}

{phang}{cmd:. mergersim init,  price(princ) quantity(qu) nests(segment domestic) marketsize(MSIZE) firm(firm)}

{phang}{cmd:. xtreg M_ls princ M_lsjh M_lshg horsepower fuel width height year domestic country*, fe}

{phang}{cmd:. mergersim market  if year ==2008 }

{phang}{cmd:. mergersim simulate if year ==2008 & country==3,  buyer(26) seller(15)}


{title:Saved results}

{pstd}
{cmd:mergersim} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(markets)}}number of markets of simulation{p_end}
{synopt:{cmd:r(products)}}number of products in market{p_end}
{synopt:{cmd:r(maxit)}}Maximum number of iterations allowed.{p_end}
{synopt:{cmd:r(iterations)}}Number of iterations to converge.{p_end}
{synopt:{cmd:r(maxiterations)}}Maximum number of iterations to converge (if simulation is done in many markets).{p_end}
{synopt:{cmd:r(convergence)}}Set to 1 if simulation converged.{p_end}
{synopt:{cmd:r(fixedpointdiff)}}Difference between fixed point expression and zero.{p_end}
{synopt:{cmd:r(maxpricediff)}}Maximum price change in last iteration.{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}Name of log-share variable created by mergersim{p_end}
{synopt:{cmd:r(loggroupshares)}}Name of log-share variable created by mergersim{p_end}
{synopt:{cmd:r(pricevar)}}Name of price variable to use in regression{p_end}
{synopt:{cmd:r(marketsize)}}Name of market size variable{p_end}
{synopt:{cmd:r(nests)}}Names of variables defining nest membership{p_end}

{synopt:{cmd:r(method)}}Simulation method{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(M_costs)}}Calculated costs{p_end}
{synopt:{cmd:r(M_lerner)}}Calculated Lerner index{p_end}
{synopt:{cmd:r(elasticities)}}Average elasticities, with sd, min and max {p_end}

{synopt:{cmd:r(M_price)}}Average pre-merger prices, by firm{p_end}
{synopt:{cmd:r(M_price2)}}Average post-merger prices, by firm{p_end}
{synopt:{cmd:r(M_price_ch)}}Average price change in merger{p_end}

{synopt:{cmd:r(mre)}}Minimal required efficiencies{p_end}

