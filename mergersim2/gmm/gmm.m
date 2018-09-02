load painkillers;
demand = NLDemand(pk);
ces = false;
newinstruments = false;
demand.settings.ces = ces;
%demand.var.nests = 'form substance';
demand.var.exog = ['marketing1 sw sm  month2 month3 month4 month5 month6 '...
    'month7 month8 month9 month10 month11 month12'];

if ces
    disp 'CES Demand'
    demand.var.marketSize = 'BL_CES';
    demand.var.price = 'Ptablets'; 
    demand.var.quantity = 'Xtablets2';
else
    disp 'Unit Demand'
    demand.var.marketSize = 'BL1';
    demand.var.price = 'Ptablets'; 
    demand.var.quantity = 'Xtablets';
end
demand.var.market = 'time';
demand.var.panel = 'product';
if newinstruments
    demand.var.instruments = ['i1_con i2_con i1_ldosage i2_ldosage i1_lpacksize '...
        'i2_lpacksize i1_form2 i2_form2 i1_substance2 i2_substance2 '...
        'i1_substance3 i2_substance3'];
    demand.var.instruments = ['num numg numf numfg numhg numfgh ' ...
        'i1_ldosage i1_lpacksize i2_ldosage i2_lpacksize'];
else
    demand.var.instruments = 'num numg numf numfg numhg numfgh';
end

demand.settings.paneltype = 'lsdv';
%demand.settings.nocons = true;
demand.init(); 

results = demand.estimate()
demand.settings.estimateMethod = 'gmm';
results = demand.estimate()

% Estimate alpha nonlinearly
gmm_funcs(demand);

market = Market(demand);
market.var.firm = 'firm';
% market.settings.paneltype = 'none';
market.var.panel = 'product';
market.var.exog = 'time';
market.init();
alpha = -.3
theta = market.estimateGMM( alpha)