% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% Author: Will Gornall 
% email: wrgornall@gmail.com
% 2018; Last revision: Aug 2018
 
 
%% Load Parameters
parameters = helper_allParameters();


%% Load and merge COI
allCOI = helper_loadAllCOI(parameters); 
 
%% Table 1: Impact of Contract Terms on Fair Value
tab_EffectOfTerms = output_tab_EffectOfTerms(allCOI,parameters)
 

%% Figures
output_fig_HistogramOfOvervaluation(codedCOI) 
 