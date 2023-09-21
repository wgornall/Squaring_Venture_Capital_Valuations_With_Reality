% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% Author: Will Gornall 
% email: wrgornall@gmail.com
% 2018; Last revision: Aug 2018

function  output =  output_tab_EffectOfTerms(allCOI,parameters)
%% Terms Table
SimpleCOI = allCOI([allCOI.T_Example]==1);

termsToTable = {...
    'Baseline',SimpleCOI,parameters;
    '1.25X LM',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'LiquidationMultiple',[0,1,1.25]')),parameters;
    '1.5X LM',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'LiquidationMultiple',[0,1,1.5]')),parameters;
    '2X LM',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'LiquidationMultiple',[0,1,2]')),parameters;
    '10% Option Pool',SimpleCOI,setfield(parameters,'COIToPayoffs',setfield(parameters.COIToPayoffs,'OptionPool',.1));
    '0% Option Pool',SimpleCOI,setfield(parameters,'COIToPayoffs',setfield(parameters.COIToPayoffs,'OptionPool',0));
    'Senior',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'LiquidationPriority',[3,2,1]')),parameters;
    'Junior',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'LiquidationPriority',[3,1,2]')),parameters;
    'Participating',setfield(SimpleCOI,'s',setfield(setfield(SimpleCOI.s,'ParticipationCapPresent',[0 0 0 ]'),'Participation',[0,0,1]')),parameters;
    'Participating, 2.5X Cap',setfield(SimpleCOI,'s',setfield(setfield(setfield(SimpleCOI.s,'ParticipationCapMultiple',[0 0 2.5]'),'ParticipationCapPresent',[0 0 1 ]'),'Participation',[0,0,1]')),parameters;
    'IPO Ratchet at 1X',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'RatchetLvl',[0,0,1]')),parameters;
    'IPO Ratchet at 1.25X',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'RatchetLvl',[0,0,1.25]')),parameters;
    'IPO Ratchet at 1.5X',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'RatchetLvl',[0,0,1.5]')),parameters;
    'Automatic Conversion Veto at 1X',setfield(SimpleCOI,'g',setfield(SimpleCOI.g,'AutomaticConversionSharePriceMinValue',1)),parameters;
    'Automatic Conversion Veto at 0.75X',setfield(SimpleCOI,'g',setfield(SimpleCOI.g,'AutomaticConversionSharePriceMinValue',0.75)),parameters;
    'Automatic Conversion Veto at 0.5X',setfield(SimpleCOI,'g',setfield(SimpleCOI.g,'AutomaticConversionSharePriceMinValue',0.5)),parameters;
    '\$400 m Raised in Second Round',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'Number',[1000*10^6,100*10^6,400*10^6]')),parameters;
    '\$10 m Raised in Second Round',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'Number',[1000*10^6,100*10^6,10*10^6]')),parameters;
    '\$400 m Raised in First Round',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'Number',[1000*10^6,800*10^6,100*10^6]')),parameters;
    '\$10 m Raised in First Round',setfield(SimpleCOI,'s',setfield(SimpleCOI.s,'Number',[1000*10^6,20*10^6,100*10^6]')),parameters;

    };

resultArray = [];



for iterTermToChange = 1:size(termsToTable,1)
    tempRes = helper_valueSingleCOI(termsToTable{iterTermToChange,2},termsToTable{iterTermToChange,3});
    tempRes.Title = termsToTable{iterTermToChange,1};
    resultArray = [resultArray; tempRes];
end

outputTBL = struct2table(resultArray);
output = outputTBL(:,{'Title','PMV','TV','DeltaV','PMVPerShare','TVPerCommon','DeltaC'});

