% Test GMM estimation. 
% We get the same estimate but slightly better t-values

clear

m = SimMarket();
m.model.markets = 200;
m.model.epsilon = .5;
% Add cost shifter w with c being gamma*w
m.model.gamma = 2;
% m.model.products = 5;
m.model.typeList = [1,2,1,2,1];
m.model.firm = [1,1,3,2,2]';
m.model.x = [5, 0];
m.model.productProbability = .5;
%% Test: Count instruments
m.model.randomProducts = true;
m.model.endog = true;
m.demand = NLDemand;
m.demand.var.nests = 'type';
m.demand.alpha = 2;
m.demand.sigma = 0.5;

m.create()
disp 'Estimate with count instruments'
results = m.demand.estimate()

%% Test: NLDemand
% m = SimMarket(model);
% m.model.randomProducts = true;
% m.model.endog = true;
% m.demand = NLDemand;
% m.demand.alpha = 1;
% %m.demand.var.nests = 'type';
% 
% m.demand.settings.paneltype = 'fe';
% m.create()

display('2SLS estimate')
% m.demand.var.instruments = 'nprod w';
results = m.demand.estimate()

m.findCosts(m.demand)
mean(m.data.c)

display('GMM estimate')
%m.estDemand.settings.paneltype = 'none';
m.demand.settings.estimateMethod = 'gmm';
results = m.demand.estimate()

% Estimate alpha nonlinearly
% gmm_funcs(m.demand);

display('Simultaneous Estimate')
alpha = [-.3, .3]';

market = Market(m.demand);
market.var.firm = 'productid';
market.settings.paneltype = 'none';
market.var.exog = 'w';
market.init();

% Joint estimate of demand (with LSDV) and costs mean and gamma
theta = market.estimateGMM( alpha)

market.findCosts()
display 'Average market c:'
mean(market.c)

% Shares incorrect with randomProducts = true
aa=market.summary()
sum(aa{:,5})

writetable(m.data,'simdata.csv')