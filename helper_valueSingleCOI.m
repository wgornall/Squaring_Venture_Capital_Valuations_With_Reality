% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% Author: Will Gornall 
% email: wrgornall@gmail.com
% 2018; Last revision: Aug 2018

function COI = helper_valueSingleCOI(COI, parameters)
       
%% Clean COI more


if parameters.robustnessCheck ==10
    COI.PostmoneyValuation = 1.2*COI.PostmoneyValuation;
elseif parameters.robustnessCheck ==11
    COI.PostmoneyValuation = 0.8*COI.PostmoneyValuation;
elseif parameters.robustnessCheck ==12
    COI.PostmoneyValuation = sum(ismember(COI.s.SecurityType,'Common').*COI.s.Number)*COI.s.ConversionPrice(end);
end


if COI.FileNumber == 3306 %Buzzfeed SPECIAL CASE.
    COI.s(end-1,:)=[];
end


if COI.FileNumber == 7776 %On deck to check
disp('   ');
end

COI.NumberShares =    COI.PostmoneyValuation./min(COI.s.OriginalIssuePrice(end),COI.s.ConversionPrice(end));

COI.HardNumberSharesReset=false;
if(COI.NumberShares  <  1.0001*sum(ismember(COI.s.SecurityType,'Preferred').*COI.s.Number.*max(COI.s.OriginalIssuePrice./COI.s.ConversionPrice,1))/(1-parameters.COIToPayoffs.OptionPool))
    COI.NumberShares = 1.0001*sum(ismember(COI.s.SecurityType,'Preferred').*COI.s.Number.*max(COI.s.OriginalIssuePrice./COI.s.ConversionPrice,1))/(1-parameters.COIToPayoffs.OptionPool);
    COI.HardNumberSharesReset=true;
end

COI.s.Number(1) = COI.NumberShares - sum(COI.s.Number(2:end));

COI.proceeds = COI.s.Number(end).*COI.s.OriginalIssuePrice(end);

COI.s.MaxLiquidation = (max([COI.s.LiquidationMultiple.*COI.s.OriginalIssuePrice,COI.s.LiquidationValue,zeros(size(COI.s.OriginalIssuePrice))]'))'.*COI.s.Number;
COI.s.MaxParticipation = max(0,COI.s.Participation.*(max([COI.s.ParticipationCapMultiple.*COI.s.OriginalIssuePrice,COI.s.ParticipationCapValue,zeros(size(COI.s.OriginalIssuePrice)),1e40*(1-COI.s.ParticipationCapPresent)]'))'.*COI.s.Number);

COI.s.FDOwnership = COI.s.Number.*max(COI.s.OriginalIssuePrice./COI.s.ConversionPrice,1)./(COI.NumberShares*(1-parameters.COIToPayoffs.OptionPool));
COI.s.FDOwnership(1) = 1-sum(COI.s.FDOwnership(2:end));

COI.PMV = COI.NumberShares * min(COI.s.OriginalIssuePrice(end),COI.s.ConversionPrice(end));




%% Come up with an array of scenarios
if true
    scenarios = struct();
    scenarios.basic.ExitValue = parameters.Scenarios.X([1:1+parameters.Scenarios.XToSkipBaseCase:end-1 end]);
    scenarios.basic.ExitTime = 1e20+0*scenarios.basic.ExitValue;
    scenarios.basic.Dimensions = [numel(scenarios.basic.ExitValue), 1];
    
    scenarios.timeVarying.LineTimes = parameters.Scenarios.T([1:1+parameters.Scenarios.TToSkipSpecialCases:end-1 end]');
    scenarios.timeVarying.LineExits = scenarios.basic.ExitValue([1:1+parameters.Scenarios.XToSkipSpecialCases:end-1 end]);
    scenarios.timeVarying.Dimensions = [numel(scenarios.timeVarying.LineExits) numel(scenarios.timeVarying.LineTimes )];
    scenarios.timeVarying.ExitTime = repelem(scenarios.timeVarying.LineTimes',size(scenarios.timeVarying.LineExits ,1),1);
    scenarios.timeVarying.ExitValue= repmat(scenarios.timeVarying.LineExits,size(scenarios.timeVarying.LineTimes',1),1);
end


%% Find payoffs in each scenario
if true
    %% Create time varying scenarios for time-varying payouts
    COI.TimeSensitive = sum(ismember(COI.s.CumulativeDividends,'1'))+sum(ismember(COI.FileNumber,[1018    2362    1067        1288        1380        1445        1575        1601        1656        2029        3218        3304        3306        3314 3315        3317        3318        3340        3347]))>0;
    
    if COI.TimeSensitive
        COI.scenario = scenarios.timeVarying;
    else
        COI.scenario = scenarios.basic;
    end
    COI.scenario.ExitValue = COI.scenario.ExitValue * COI.PMV;
 
    
    if true
        %% M&A
        convert = ones(numel(COI.scenario.ExitValue),size(COI.s,1));
        for iter1 = 1:3
            for iter2 = size(COI.s,1):-1:1
                testMat = ones(size(convert,1),1) * [zeros(1,iter2-1) 1 zeros(1,size(convert,2)-iter2)];
                poIfLiq =   helper_payoffsGivenLiq2(COI, (~testMat)&convert,0,parameters);
                poIfConv =   helper_payoffsGivenLiq2(COI, testMat|convert  ,0,parameters);
                convert(:,iter2) =  poIfLiq(:,iter2)  <  poIfConv(:,iter2) + 1;
            end
        end
        
        COI.scenario.valuesAtExitsMA  = helper_payoffsGivenLiq2(COI, convert,0,parameters);
    end
    
    if true
        %% IPO
        convert = ones(numel(COI.scenario.ExitValue),size(COI.s,1));
        for iter2 = size(COI.s,1):-1:1
            testMat = ones(size(convert,1),1) * [zeros(1,iter2-1) 1 zeros(1,size(convert,2)-iter2)];
            poIfLiq =   helper_payoffsGivenLiq2(COI, (~testMat)&convert,1,parameters);
            poIfConv =   helper_payoffsGivenLiq2(COI, testMat|convert  ,1,parameters);
            convert(:,iter2) =  poIfLiq(:,iter2)  <  poIfConv(:,iter2) + 1;
        end
        
        valuesAtExitsIPOGoesAhead = helper_payoffsGivenLiq2(COI, convert, 1, parameters);
        
        %% Conversion
        
        ForceConversion = ( COI.scenario.ExitValue >= max([0,...
            COI.g.AutomaticConversionProceedsMin./parameters.COIToPayoffs.proceedsPerIPO, ...
            COI.g.AutomaticConversionValuationMin ,...
            COI.NumberShares*COI.g.AutomaticConversionSharePriceMinValue ]))*ones(1,size(valuesAtExitsIPOGoesAhead,2));
        
        if COI.FileNumber == 2029           % Kabbage.         37.03 for three years,
            ForceConversion = ForceConversion.*(COI.NumberShares*COI.scenario.ExitValue>37.03*(COI.scenario.ExitTime<3));
        end
        
        
        ForceConversion = ForceConversion|ismember(COI.g.ConversionCanBeForced,'1');
        
        wantsToBlockIPO = valuesAtExitsIPOGoesAhead<COI.scenario.valuesAtExitsMA;
        blockedIPO = max(wantsToBlockIPO&~ForceConversion,[],2);
        
        classHasSeperateVeto = 0<COI.s.SeparateVetoRightOverIPOExists;
        
        if COI.FileNumber == 3315
            blockedIPO = blockedIPO + (COI.scenario.ExitTime<=15/12) .* ((1*wantsToBlockIPO)* COI.s.SeparateConversionVeto_No_ConversionInAtLeastSomeIPOs )>0;
        elseif COI.FileNumber == 3304
            blockedIPO = blockedIPO + (COI.scenario.ExitTime<=21/12).* ((1*wantsToBlockIPO)* COI.s.SeparateConversionVeto_No_ConversionInAtLeastSomeIPOs )>0;
        end
        
        
        blockedIPO = blockedIPO + (wantsToBlockIPO+0)*classHasSeperateVeto >0;
        
        COI.scenario.valuesAtExitsIPO  = valuesAtExitsIPOGoesAhead.*(1-(1-parameters.COIToPayoffs.doesNotHoldUp)*blockedIPO*ones(1,size(valuesAtExitsIPOGoesAhead,2)))+COI.scenario.valuesAtExitsMA.*((1-parameters.COIToPayoffs.doesNotHoldUp)*blockedIPO*ones(1,size(valuesAtExitsIPOGoesAhead,2)));
        
        
    end
    
    %% Payoff in exit
    if true
        
        COI.scenario.valuesAtExits = COI.scenario.valuesAtExitsIPO .*(parameters.COIToPayoffs.IPOfn(COI.scenario.ExitValue)*ones(1,size(COI.s,1))) +...
            COI.scenario.valuesAtExitsMA .*(1-parameters.COIToPayoffs.IPOfn(COI.scenario.ExitValue)*ones(1,size(COI.s,1)));
                
        if	parameters.COIToPayoffs.allForBenefitCommon == true
            IPOBenefitsCommon = COI.scenario.valuesAtExitsIPO(:,1) > COI.scenario.valuesAtExitsMA(:,1);
            
            COI.scenario.valuesAtExits = COI.scenario.valuesAtExitsIPO .*(IPOBenefitsCommon*ones(1,size(COI.s,1))) +...
                COI.scenario.valuesAtExitsMA .*(1-IPOBenefitsCommon*ones(1,size(COI.s,1)));
        end

        if	parameters.COIToPayoffs.cramDownFrac > 0
            valuesAtExitsCramDown = COI.scenario.ExitValue*COI.s.FDOwnership';
            COI.scenario.valuesAtExits = COI.scenario.valuesAtExits * (1-parameters.COIToPayoffs.cramDownFrac) + valuesAtExitsCramDown*parameters.COIToPayoffs.cramDownFrac;
        end
        
    end
    
end


%% Code an approximation of the payoff at each exit
if true
    discountFactor = @(t) exp(-t*parameters.PayoffsToValuation.rf);
    
    if COI.TimeSensitive
        %% For time sensitive COI (e.g. dividends)
        ExitValuesSquare = reshape(COI.scenario.ExitValue, COI.scenario.Dimensions )';
        ExitTimesSquare =reshape(COI.scenario.ExitTime, COI.scenario.Dimensions )';
        valuesAtExitsSquare =permute(reshape(COI.scenario.valuesAtExits, [COI.scenario.Dimensions size(COI.s,1)]),[2,1,3]);
        valuesAtExitsSquareMA =permute(reshape(COI.scenario.valuesAtExitsMA, [COI.scenario.Dimensions size(COI.s,1)]),[2,1,3]);
        valuesAtExitsSquareIPO =permute(reshape(COI.scenario.valuesAtExitsIPO, [COI.scenario.Dimensions size(COI.s,1)]),[2,1,3]);
        
        COI.valueAppxXY = @(x,y,n) interp2(...
            ExitValuesSquare,ExitTimesSquare,squeeze(valuesAtExitsSquare(:,:,end*(n==0)+n)),...
            x,y).*discountFactor(y);
        
        COI.valueAppxXYMA = @(x,y,n) interp2(...
            ExitValuesSquare,ExitTimesSquare,squeeze(valuesAtExitsSquareMA(:,:,end*(n==0)+n)),...
            x,y).*discountFactor(y);
        
        COI.valueAppxXYIPO = @(x,y,n) interp2(...
            ExitValuesSquare,ExitTimesSquare,squeeze(valuesAtExitsSquareIPO(:,:,end*(n==0)+n)),...
            x,y).*discountFactor(y);
    else
        %% For other COI
        COI.valueAppxXY = @(x,y,n) interp1(...
            COI.scenario.ExitValue,COI.scenario.valuesAtExits(:,end*(n==0)+n),...
            x).*discountFactor(y);
        
        COI.valueAppxXYMA = @(x,y,n) interp1(...
            COI.scenario.ExitValue,COI.scenario.valuesAtExitsMA(:,end*(n==0)+n),...
            x).*discountFactor(y);
        
        COI.valueAppxXYIPO = @(x,y,n) interp1(...
            COI.scenario.ExitValue,COI.scenario.valuesAtExitsIPO(:,end*(n==0)+n),...
            x).*discountFactor(y);
    end  
    
    if parameters.PayoffsToValuation.illiqpremium~=0
        COI.valueAppxXY = @(x,y,n) COI.valueAppxXY(x*(parameters.PayoffsToValuation.illiqpremium./parameters.PayoffsToValuation.ExitRate+1),y,n).*exp(-parameters.PayoffsToValuation.illiqpremium*y);

    end
end

%% Code an approximation of security value given payoff
if true
    
    if parameters.PayoffsToValuation.appx
        %% APPROXIMATE VALUATION METHOD USING MONTE CARLO
        randfTrialExit = parameters.randfTrialExit ;
        
        TrialExitTime = -log(randfTrialExit(:,1))/parameters.PayoffsToValuation.ExitRate;
        
        if(parameters.robustnessCheck==999||parameters.robustnessCheck==1999)
            TrialExitTime = TrialExitTime*0+1/parameters.PayoffsToValuation.ExitRate;
        end        
        
        
        TrialExitValue = exp(norminv(randfTrialExit(:,2)).*(parameters.PayoffsToValuation.Volatility.^2.*TrialExitTime).^.5+(parameters.PayoffsToValuation.rf-parameters.PayoffsToValuation.Volatility.^2/2).*TrialExitTime);
        TrialExitRes = TrialExitValue.*exp(-parameters.PayoffsToValuation.rf.*TrialExitTime);
        TrialExitValue(TrialExitRes==max(TrialExitRes))=(numel(TrialExitValue)-sum(TrialExitRes(TrialExitRes~=max(TrialExitRes)))).*exp( parameters.PayoffsToValuation.rf.*TrialExitTime(TrialExitRes==max(TrialExitRes)));
        
        integrations = struct('ExitTime',TrialExitTime,'ExitValue',TrialExitValue);
        assert(0.0001>abs(1-mean(TrialExitValue.*exp(-parameters.PayoffsToValuation.rf.*TrialExitTime))));
               
        COI.inpExits = @(x,n) mean(COI.valueAppxXY(x*TrialExitValue,TrialExitTime,n));

       if parameters.PayoffsToValuation.UseRO
            epsilon2= -1/parameters.PayoffsToValuation.Volatility^2 *(parameters.PayoffsToValuation.ROGrowth - parameters.PayoffsToValuation.Volatility^2/2 - sqrt((parameters.PayoffsToValuation.ROGrowth - parameters.PayoffsToValuation.Volatility^2/2 )^2 + 2* parameters.PayoffsToValuation.Volatility^2 * parameters.PayoffsToValuation.rf));
            XI = epsilon2/(epsilon2 - 1) * parameters.PayoffsToValuation.ROInv * ( parameters.PayoffsToValuation.rf - parameters.PayoffsToValuation.ROGrowth);

            npv = @(x) x/(parameters.PayoffsToValuation.rf - parameters.PayoffsToValuation.ROGrowth)-parameters.PayoffsToValuation.ROInv;
            npvinv = @(V) (V+parameters.PayoffsToValuation.ROInv)*(parameters.PayoffsToValuation.rf - parameters.PayoffsToValuation.ROGrowth);
            V = @(x) npv(x).*(x>=XI) + npv(XI).*(x/XI).^epsilon2.*(x<XI);                  
                        
            x0 = @(V0) npvinv(V0).*(V0>=npv(XI)) +  (V0/npv(XI)).^(1/epsilon2)*XI.*(V0<npv(XI));

            COI.inpExits = @(x,n) mean(COI.valueAppxXY(V(x*100*TrialExitValue.*exp(TrialExitTime*(parameters.PayoffsToValuation.ROGrowth-parameters.PayoffsToValuation.rf))),TrialExitTime,n));

       end
        

        if parameters.robustnessCheck ==19
            COI.inpExits = @(x,n) mean(COI.valueAppxXY(max(x*(TrialExitValue-0.14216)/0.9,0),TrialExitTime,n));
        elseif parameters.robustnessCheck ==20
            COI.inpExits = @(x,n) mean(COI.valueAppxXY(max(x*(TrialExitValue-0.065125)/0.95,0),TrialExitTime,n));
        end        
        
    else
        %% LESS APPROXIMATE SOLUTION INTEGRATING ACROSS INTERPOLATION
        xyToTime = @(y)-log(y)/parameters.PayoffsToValuation.ExitRate;
        if(parameters.robustnessCheck==999||parameters.robustnessCheck==1999)
            xyToTime = @(y) 1/parameters.PayoffsToValuation.ExitRate;
        end        
        
        xyToValue = @(x,y) (exp(norminv(x).*(parameters.PayoffsToValuation.Volatility.^2.*xyToTime(y)).^.5+(parameters.PayoffsToValuation.rf-parameters.PayoffsToValuation.Volatility.^2/2).*xyToTime(y)));
        assert( (parameters.robustnessCheck ~=19)&( parameters.robustnessCheck ~=20));
   
        COI.inpExits = @(z,n) integral2(...
            @(x,y) COI.valueAppxXY(z*xyToValue(x,y),xyToTime(y),n), ...
            0,1,0,1,'RelTol',parameters.PayoffsToValuation.TolIntegAppx,'AbsTol',COI.PMV*parameters.PayoffsToValuation.TolIntegAppx);
    
        
       if parameters.PayoffsToValuation.UseRO

           %%
            epsilon2= -1/parameters.PayoffsToValuation.Volatility^2 *(parameters.PayoffsToValuation.ROGrowth - parameters.PayoffsToValuation.Volatility^2/2 - sqrt((parameters.PayoffsToValuation.ROGrowth - parameters.PayoffsToValuation.Volatility^2/2 )^2 + 2* parameters.PayoffsToValuation.Volatility^2 * parameters.PayoffsToValuation.rf));
            XI = epsilon2/(epsilon2 - 1) * parameters.PayoffsToValuation.ROInv * ( parameters.PayoffsToValuation.rf - parameters.PayoffsToValuation.ROGrowth);

            npv = @(x) x/(parameters.PayoffsToValuation.rf - parameters.PayoffsToValuation.ROGrowth)-parameters.PayoffsToValuation.ROInv;
            npvinv = @(V) (V+parameters.PayoffsToValuation.ROInv)*(parameters.PayoffsToValuation.rf - parameters.PayoffsToValuation.ROGrowth);
            V = @(x) npv(x).*(x>=XI) + npv(XI).*(x/XI).^epsilon2.*(x<XI);                  
                        
            x0 = @(V0) npvinv(V0).*(V0>=npv(XI)) +  (V0/npv(XI)).^(1/epsilon2)*XI.*(V0<npv(XI));

            COI.inpExits = @(z,n) integral2(...
                @(x,y) COI.valueAppxXY(V(100*z*xyToValue(x,y).*exp(xyToTime(y)*(parameters.PayoffsToValuation.ROGrowth-parameters.PayoffsToValuation.rf))),xyToTime(y),n), ...
                0,1,0,1,'RelTol',parameters.PayoffsToValuation.TolIntegAppx,'AbsTol',COI.PMV*parameters.PayoffsToValuation.TolIntegAppx);

            
       end
        
    
    
    end
    
    
    
end

%% Find valuation given the payoff approximation
if true
    
    try
        %%
        
        if parameters.robustnessCheck ==1000||parameters.robustnessCheck ==1999
                COI.TV = parameters.TV;
                
            for iter1 = 1:size(COI.s,1)
                COI.AllValues(iter1)=COI.inpExits(COI.TV,iter1)./COI.NumberShares./COI.s.FDOwnership(iter1)/(1-parameters.COIToPayoffs.OptionPool);
            end
        else

                COI.TV = fzero( @(q) ...
                mean((    COI.proceeds-COI.inpExits(q,0))./    COI.proceeds), ...
                [0,1.1*COI.PMV]);

                asdf = 0;
            for iter1 = 1:size(COI.s,1)
                COI.AllValues(iter1)=COI.inpExits(COI.TV,iter1)./COI.NumberShares./COI.s.FDOwnership(iter1)/(1-parameters.COIToPayoffs.OptionPool);
                asdf = asdf + COI.AllValues(iter1)*(1/(1./COI.NumberShares./COI.s.FDOwnership(iter1)/(1-parameters.COIToPayoffs.OptionPool)));
            end
            if parameters.PayoffsToValuation.UseRO
                COI.TV = asdf;
            end

            assert(abs(COI.TV/asdf-1)<0.01+(parameters.robustnessCheck>0)*.2)
        end
        
        COI.ValuationSucceeded = true;
        
    catch
        
        COI.ValuationSucceeded = false;
    end
end

%% Put in additional columns

   COI.DeltaV= COI.PMV/COI.TV-1;
        
        COI.TVPerCommon=COI.AllValues(1);
        COI.DeltaC= COI.AllValues(end)/COI.TVPerCommon-1;
        
        COI.PMVPerShare = COI.AllValues(end);
        
        COI.CoName = COI.g.Company;
        
        for iterToCodeFromGeneral = {'COIDate' 'OriginalDateOfIncorporation' 'FileNumber' 'AutomaticConversionProceedsMin'    'AutomaticConversionValuationMin'    'AutomaticConversionSharePriceMinValue'  }
            COI.(iterToCodeFromGeneral{1}) = COI.g.(iterToCodeFromGeneral{1});
        end
        
        
        temp = COI.COIDate;
        if(    isdatetime(temp))
            temp= datenum(temp);
        end
        COI.yearfrac = yearfrac(datenum(2000,1,1),temp)+2000;
        COI.Rounds = size(COI.s,1);
        COI.CumulativeRaised = nansum(COI.s.Number.*COI.s.OriginalIssuePrice);

        COI.NumberOfLiquidationClasses = numel(unique(COI.s.LiquidationPriority));
        
        COI.PMVw = COI.PMV/1e9;
        COI.TVw= COI.TV/1e9;
        
        COI.Proceeds = COI.s.Number(end).*COI.s.OriginalIssuePrice(end);
        COI.ProceedsOverPMV = COI.Proceeds/COI.PMV;
        
        COI.LastParticipation = COI.s.Participation(end)>0;
        COI.LastLP = max([max(COI.s.LiquidationMultiple(end)),max(COI.s.LiquidationValue(end)./COI.s.OriginalIssuePrice(end)),1]);
        COI.LastOwnLC = COI.s.LiquidationPriority(end)< min(COI.s.LiquidationPriority(1:end-1));
        COI.LastLPG1 =  COI.LastLP>1;
        COI.LastRatchetLvl = COI.s.RatchetLvl(end);
        
        COI.LastSeniorToSome = max([-Inf;COI.s.LiquidationPriority(2:end-1)])>COI.s.LiquidationPriority(end);
        COI.LastSeniorToFrac = 1-sum(((COI.s.LiquidationPriority(2:end)<=COI.s.LiquidationPriority(end))).*COI.s.Number(2:end)./COI.NumberShares);
        COI.LastCumDiv = max(str2double(COI.s.CumulativeDividends(end)))>0;
        COI.LastCumDivIfHas =     max(str2double(COI.s.CumulativeDividends(end)).*max([0 COI.s.DividendRate(end) COI.s.Dividend_(end)./COI.s.OriginalIssuePrice(end)],[],2))./COI.LastCumDiv;
        
        
        COI.AnyCumDiv = max(str2double(COI.s.CumulativeDividends))>0;
        COI.AnyCumDivIfHas =     max(str2double(COI.s.CumulativeDividends).*max([zeros(size(COI.s.DividendRate)) COI.s.DividendRate COI.s.Dividend_./COI.s.OriginalIssuePrice],[],2))./COI.AnyCumDiv;
        
        COI.AnyParticipation = max([COI.s.Participation]);
        COI.AnyLP = max([COI.s.LiquidationMultiple',max(COI.s.LiquidationValue./COI.s.OriginalIssuePrice)',1]);
        COI.AnyOwnLC = COI.NumberOfLiquidationClasses>2;
        COI.AnyLPG1 = COI.AnyLP>1;
        COI.MaxRatchetLvl = max([COI.s.RatchetLvl]);
        
        
        if (COI.Rounds>1)
            COI.LastRoundChange = COI.s.OriginalIssuePrice(end)/COI.s.OriginalIssuePrice(end-1);
            COI.SLastParticipation = COI.s.Participation(end-1);
            COI.SLastLP = max([max(COI.s.LiquidationMultiple(end-1)),max(COI.s.LiquidationValue(end-1)./COI.s.OriginalIssuePrice(end-1)),1]);
            COI.SLastOwnLC = COI.s.LiquidationPriority(end-1)< min(COI.s.LiquidationPriority(1:end-2));
            
        else
            COI.LastRoundChange = NaN;
            COI.SLastParticipation = NaN;
            COI.SLastLP = NaN;% max([max(COI.s.LiquidationMultiple(end-1)),max(COI.s.LiquidationValue(end-1)./COI.s.OriginalIssuePrice(end-1)),1]);
            COI.SLastOwnLC = NaN;% COI.s.LiquidationPriority(end-1)< min(COI.s.LiquidationPriority(1:end-2));
        end
        
        
        if true
            
            %% MA/IPO Payout Graphs
            returnGraphPoints = 0.01:0.01:2;
            
            COI.magraphreturn = COI.valueAppxXYMA(returnGraphPoints*COI.PMV*(1-parameters.COIToPayoffs.OptionPool),1/parameters.PayoffsToValuation.ExitRate,0)./COI.Proceeds.*exp(parameters.PayoffsToValuation.rf/parameters.PayoffsToValuation.ExitRate);
            COI.ipographreturn = COI.valueAppxXYIPO(returnGraphPoints*COI.PMV*(1-parameters.COIToPayoffs.OptionPool),1/parameters.PayoffsToValuation.ExitRate,0)./COI.Proceeds.*exp(parameters.PayoffsToValuation.rf/parameters.PayoffsToValuation.ExitRate);
            
            COI.magraphreturncommon = COI.valueAppxXYMA(returnGraphPoints*COI.PMV*(1-parameters.COIToPayoffs.OptionPool),1/parameters.PayoffsToValuation.ExitRate,1)./(COI.s.FDOwnership(1)*COI.NumberShares*(1-parameters.COIToPayoffs.OptionPool)*COI.s.OriginalIssuePrice(end)).*exp(parameters.PayoffsToValuation.rf/parameters.PayoffsToValuation.ExitRate);
            COI.ipographreturncommon = COI.valueAppxXYIPO(returnGraphPoints*COI.PMV*(1-parameters.COIToPayoffs.OptionPool),1/parameters.PayoffsToValuation.ExitRate,1)./(COI.s.FDOwnership(1)*COI.NumberShares*(1-parameters.COIToPayoffs.OptionPool)*COI.s.OriginalIssuePrice(end)).*exp(parameters.PayoffsToValuation.rf/parameters.PayoffsToValuation.ExitRate);
            
            COI.avgLowReturnIPO = mean(COI.ipographreturn(returnGraphPoints<1));
            COI.avgLowReturnMA = mean(COI.magraphreturn(returnGraphPoints<1));
            
            for iter1 = [10 25 50 100 200]
                COI.(['ma' num2str(iter1) 'return']) = interp1(returnGraphPoints,COI.magraphreturn ,iter1/100);
                COI.(['ipo' num2str(iter1) 'return']) = interp1(returnGraphPoints,COI.ipographreturn ,iter1/100);
                COI.(['ma' num2str(iter1) 'returncommon']) = interp1(returnGraphPoints,COI.magraphreturncommon ,iter1/100);
                COI.(['ipo' num2str(iter1) 'returncommon']) = interp1(returnGraphPoints,COI.ipographreturncommon ,iter1/100);
            end
        end
        
        COI.IPOAD = (ismember(COI.g.LowIPOValuesTriggerAntidilution,'1'));
        
        COI.LastHasRatchet = (COI.LastRatchetLvl>0);
        COI.LastRatchetIfHas = COI.LastRatchetLvl./(COI.LastRatchetLvl>0);
        COI.AnyHasRatchet = (COI.MaxRatchetLvl>0);
        COI.AnyRatchetIfHas = COI.MaxRatchetLvl./(COI.MaxRatchetLvl>0);
        
        COI.MinACProceeds = (1-ismember(COI.g.ConversionCanBeForced,'1')).*COI.g.AutomaticConversionProceedsMin;
        COI.MinACVal = (1-ismember(COI.g.ConversionCanBeForced,'1')).*max([0,...
            COI.g.AutomaticConversionValuationMin ,...
            COI.NumberShares*COI.g.AutomaticConversionSharePriceMinValue ]);
        COI.MinAutoConv = max(COI.MinACProceeds ,COI.MinACVal );
        
        COI.ObsIPOProceedsNom = COI.MinACProceeds./(COI.MinACProceeds>0);
        COI.ObsIPOValNom = COI.MinACVal./(COI.MinACVal>0);
        
        COI.ObsIPOProceeds = COI.ObsIPOProceedsNom >0;
        COI.ObsIPOVal = COI.ObsIPOValNom >0;
        
        COI.ObsIPOProceedsRPMV = COI.ObsIPOProceedsNom./COI.PMV;
        COI.ObsIPOValRPMV = COI.ObsIPOValNom./COI.PMV;
        
        COI.ObsIPONom = max(COI.ObsIPOProceedsNom./parameters.COIToPayoffs.proceedsPerIPO , COI.ObsIPOValNom );
        COI.ObsIPORPMV = COI.ObsIPONom./COI.PMV;
        
        COI.ObsIPO = COI.ObsIPONom >= 0;
        COI.ObsIPOMajor = COI.ObsIPORPMV >= .5;
        
        
        COI.LastMajor = COI.LastLPG1+COI.LastParticipation+COI.LastHasRatchet+COI.LastOwnLC+COI.ObsIPOMajor >0;
        COI.AnyMajor = COI.AnyLPG1+COI.AnyParticipation+COI.AnyHasRatchet+COI.AnyOwnLC+COI.ObsIPOMajor >0;
        
        
        
        if true
            %% COI CODES
            COI.coded = '';
            if(COI.LastCumDiv>0 );       COI.coded =             [COI.coded 'd'];                    end
            if(COI.LastLP>1.001);    	 COI.coded =             [COI.coded 'm'];                    end
            if(COI.ObsIPOMajor);         COI.coded =             [COI.coded 'o'];                    end
            if(COI.LastParticipation);   COI.coded =             [COI.coded 'p'];                    end
            if(COI.LastHasRatchet);      COI.coded =             [COI.coded 'r'];                    end
            if(COI.LastOwnLC);           COI.coded =             [COI.coded 's'];                    end
            
            COI.anycoded = '';
            if(COI.AnyCumDiv );          COI.anycoded =         [COI.anycoded 'd'];                  end
            if(COI.AnyLP>1.001);     	 COI.anycoded =         [COI.anycoded 'm'];                  end
            if(COI.ObsIPOMajor);         COI.anycoded =         [COI.anycoded 'o'];                  end
            if(COI.AnyParticipation>0);  COI.anycoded =         [COI.anycoded 'p'];                  end
            if(COI.AnyHasRatchet);       COI.anycoded =         [COI.anycoded 'r'];                  end
            if(COI.AnyOwnLC);            COI.anycoded =         [COI.anycoded 's'];                  end
        end
        
        true;
        if(~parameters.PayoffsToValuation.debug)

     

if isfield(parameters,'OPTIONGRAPH')
    %%
        
        commonS = COI.NumberShares.*COI.s.FDOwnership(1)*(1-parameters.COIToPayoffs.OptionPool);
        
        COI.valueAppxXYAAA = @(x,y,strike) interp1(...
            COI.scenario.ExitValue,...
            max(0,-strike*commonS +COI.scenario.valuesAtExits(:,1)),...
            x).*discountFactor(y);
    
        COI.inpExitsAAA = @(strike) integral2(...
            @(x,y) COI.valueAppxXYAAA(COI.TV*xyToValue(x,y),xyToTime(y),strike), ...
            0,1,0,1,'RelTol',parameters.PayoffsToValuation.TolIntegAppx,'AbsTol',COI.PMV*parameters.PayoffsToValuation.TolIntegAppx)./commonS;
    
        
        
        COI.valueAppxXYBBB = @(x,y,strike) ...
            max(0,-strike + x).*discountFactor(y);
    
        COI.inpExitsBBB = @(strike) integral2(...
            @(x,y) COI.valueAppxXYBBB(COI.s.OriginalIssuePrice(end)*xyToValue(x,y),xyToTime(y),strike), ...
            0,1,0,1,'RelTol',parameters.PayoffsToValuation.TolIntegAppx,'AbsTol',COI.PMV*parameters.PayoffsToValuation.TolIntegAppx);
         
        COI.inpExitsCCC = @(strike) (COI.s.OriginalIssuePrice(end)-strike);
        
          
   strikeprices = 0:20;
   resA = [];
    for iter0 = 1:numel(strikeprices)
        strike= strikeprices(iter0);
        resA(:,iter0) = [ COI.inpExitsAAA(strike); COI.inpExitsBBB(strike); COI.inpExitsCCC(strike)];           
    end    
    resA
    
    
    COI.OptionGraphRes = [strikeprices;resA];
    COI.OptionsAt911 = [COI.inpExitsAAA(9.11)
    COI.inpExitsBBB(9.11)
    COI.inpExitsCCC(9.11)];


end
    
     
end
          %%
            COI.scenario=[];
