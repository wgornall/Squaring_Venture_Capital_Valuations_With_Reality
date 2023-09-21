% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% Author: Will Gornall 
% email: wrgornall@gmail.com
% 2018; Last revision: Aug 2018

function parameters = getAllParameters()
%%

parameters = struct();

parameters.robustnessCheck = false;    

parameters.LoadAllCOI = struct( 'debug',0,...
    'COIFileLocation','COI Data_UnicornPaper 20180211s.xlsx',...
    'ExtrDataFileLocation','Non COI Model Inputs 20180211s.xlsx');
parameters.Scenarios.XToSkipBaseCase = 5;
parameters.Scenarios.XToSkipSpecialCases = 10;

parameters.randfTrialExit = rand(qrandstream('halton',2,'Skip',1e3,'Leap',1e2),1e7,2);
        
parameters.Scenarios = struct('debug',0,...
    'X',unique([0:0.01:3,3:0.05:5,5:.1:10,10:.5:20,20.^[1:.25:10],1e40]'),...
    'T',unique([0, 0.1:20,0.9:20,20:10:40,10.^[2:4],1e10]),....
    'XToSkipBaseCase',0, ...
    'XToSkipSpecialCases',0, ...
    'TToSkipSpecialCases',0 ...
    );

parameters.COIToPayoffs = struct(   'debug',0,...
    'OptionPool',0.05,...
    'allForBenefitCommon',false,...
    'proceedsPerIPO',.25,...
    'IPOfn', @(x)max(0,min(1,min(.65*(log(x)-log(32e6))/(log(1e9)-log(32e6)),.65+.2*(log(x)-log(1e9))/(log(1e11)-log(1e9))))),...
    'doesNotHoldUp',0,...
    'cramDownFrac',0,...
    'OptFrac',0,...
    'OptStrikeFrac',0);

parameters.PayoffsToValuation = struct('debug',0,...
    'ExitRate',0.25,...
    'Volatility',0.9,...
    'rf',0.025,...
    'ROGrowth',-0.005,...
    'ROInv',1e11,...
    'illiqpremium',0,...
    'UseRO',false,...
    'TolIntegAppx',1e-4,...
    'appx',false,...
    'OptOpt',optimset('Display','off','TolX',1) );

parameters.Outputs = struct('debug',0);