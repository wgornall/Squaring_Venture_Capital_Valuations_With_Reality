% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% Author: Will Gornall 
% email: wrgornall@gmail.com
% 2018; Last revision: Aug 2018

function [values] = helper_payoffsGivenLiq(COI, convert,IPO,parameters)
%%

% Potential exits in MC 
ExitValues = COI.scenario.ExitValue;
ExitTimes = COI.scenario.ExitTime;

onesSec = ones(1, size(COI.s,1));
onesScen = ones(size(ExitValues));

% Code to handle cumulative dividends
DividendRate =  ismember(COI.s.CumulativeDividends,'1').*max([0*onesSec',COI.s.Dividend_./COI.s.OriginalIssuePrice,COI.s.DividendRate],[],2);

if max(DividendRate)>0
    DividendsOwedAC = (1+onesScen*DividendRate').^(ExitTimes*onesSec)-1;
    DividendsOwedAN = ExitTimes*DividendRate';
    DividendsOwedA = (onesScen*ismember(COI.s.CompoundingDividends,'1')').*DividendsOwedAC + (1-onesScen*ismember(COI.s.CompoundingDividends,'1')').*DividendsOwedAN;
    
    DividendsOwedB = min(1e100,max(0,DividendsOwedA));
    DividendsOwed =  DividendsOwedB .* (onesScen*max(0,COI.s.OriginalIssuePrice.*COI.s.Number)');
else
    DividendsOwed =0;
end

seniorityClasses = unique( COI.s.LiquidationPriority);
liqidationPriority = onesScen*COI.s.LiquidationPriority';
maxParticipation = onesScen*COI.s.MaxParticipation';

% We deal with qualified IPOs that force conversion by setting liquidation preference to 0 (unless there is an IPO that forces conversion).
if IPO
    maxLiquidation = onesScen*max( 0, COI.s.RatchetLvl.*COI.s.OriginalIssuePrice.*COI.s.Number)';
else
    maxLiquidation = onesScen*COI.s.MaxLiquidation';
end

% This code handles WA antidilution triggered in an IPO. 
if IPO && str2double(COI.g.LowIPOValuesTriggerAntidilution)==1
    FDOwnershipByState = (onesScen*COI.s.FDOwnership' )./min(1,(1  + .25 * ExitValues * min(1e10,1./COI.s.ConversionPrice') /sum(COI.s.Number) ) / 1.25);
else
    FDOwnershipByState  = onesScen*COI.s.FDOwnership' ;
end

maxLiquidation = min(maxLiquidation,1e30);

maxParticipation = max(0,maxParticipation - maxLiquidation);

% Main Calculation

PayoutMatrix = 0*onesScen*onesSec;

ValueAvailible = ExitValues;

%This loop goes through each seniority class. For each seniority class, we
%iterate through and see who gets what based on liquidation decisions.
for iter0 = 1:numel(seniorityClasses)
    securitiesBeingPaid = ~convert&ismember(liqidationPriority ,seniorityClasses(iter0));
    securitiesBeingPaidDiv = ismember(liqidationPriority,seniorityClasses(iter0));
    PotentialClassRecovery = maxLiquidation.*securitiesBeingPaid +  DividendsOwed.*securitiesBeingPaidDiv;
    portionRecoveredByClass = min(1, ValueAvailible./sum(PotentialClassRecovery+.1,2));
    
    ClassRecovery =PotentialClassRecovery.*(portionRecoveredByClass*onesSec);
    
    ValueAvailible = ValueAvailible -  sum(ClassRecovery,2);
    PayoutMatrix = PayoutMatrix + ClassRecovery;
end

payoutOnFDB = 0;


if parameters.COIToPayoffs.OptFrac==Inf %HANDLE STOCK OPTIONS FOR ROBUSTNESS CHECK.
    strikeOwing= ones(size(ValueAvailible,1),1)*parameters.strikeOwing';
elseif parameters.COIToPayoffs.OptFrac>0 %HANDLE STOCK OPTIONS FOR ROBUSTNESS CHECK.
    strikePaid = 0;
end

%This code handles participation. We iterate through, allocating value to
%converted and participating shares. 
for iter0 = 1:3
    ValueAvailibleT = ValueAvailible - sum(payoutOnFDB,2);
    TryToPayT = payoutOnFDB < maxParticipation+convert*1e40;
    FDToAttemptT = TryToPayT.*FDOwnershipByState;
    AttemptedPayoutT = ( ValueAvailibleT./sum(FDToAttemptT,2) * ones(1,size(FDToAttemptT,2))) .* FDToAttemptT ;
    AttemptedPayoutT(~isfinite(AttemptedPayoutT))=0;
    ActualPayT = min(maxParticipation+convert*1e40,  AttemptedPayoutT);
    
    if parameters.COIToPayoffs.OptFrac==Inf %HANDLE STOCK OPTIONS FOR ROBUSTNESS CHECK.
        strikePaid = max(0,min(strikeOwing,ActualPayT));
        strikeOwing = strikeOwing-strikePaid;
        ActualPayT = ActualPayT-strikePaid;
        
    elseif parameters.COIToPayoffs.OptFrac>0 %HANDLE STOCK OPTIONS FOR ROBUSTNESS CHECK.
        ActualPayTold =ActualPayT;
        ActualPayT(:,1) = ActualPayT(:,1)*(1-parameters.COIToPayoffs.OptFrac)+...
            max(0,  strikePaid + ( ActualPayT(:,1) -  parameters.COIToPayoffs.OptStrikeFrac * COI.PostmoneyValuation*(1-parameters.COIToPayoffs.OptionPool).*COI.s.FDOwnership(1)))...
            *parameters.COIToPayoffs.OptFrac ;
        strikePaid = strikePaid + ActualPayTold(:,1) - ActualPayT(:,1);
    end
    
    payoutOnFDB  = payoutOnFDB +ActualPayT;
end


PayoutMatrix = PayoutMatrix + payoutOnFDB;

values = PayoutMatrix;
