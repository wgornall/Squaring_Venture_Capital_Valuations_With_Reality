% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% Author: Will Gornall 
% email: wrgornall@gmail.com
% 2018; Last revision: Aug 2018

function [ allCOI, rawCOI] = loadAllCOI(parameters)

%% Load Security Records
dSecurities = readtable(parameters.LoadAllCOI.COIFileLocation,'Sheet',3);
dSecurities.FileNumber = str2double(dSecurities.FileNumber);
dSecurities(1:2,:)=[];

%% Load COI Records
dGeneralData = readtable(parameters.LoadAllCOI.COIFileLocation,'Sheet',2);
dGeneralData.FileNumber = str2double(dGeneralData.FileNumber);
dGeneralData(1:2,:)=[];

%% Load extra data
dExtraDataEmp  = readtable(parameters.LoadAllCOI.ExtrDataFileLocation);

%% Combine the COI, securities, and ExtraData into a single struct
rawCOI = [];

for iter0 = unique(dExtraDataEmp.FileNumber(dExtraDataEmp.FileNumber>-Inf))'
    COI =  table2struct(dExtraDataEmp(dExtraDataEmp.FileNumber==iter0,:));
    COI.g = dGeneralData(dGeneralData.FileNumber==iter0,:);
    COI.s = dSecurities(dSecurities.FileNumber==iter0,:);
    
    rawCOI = [rawCOI; COI];
end

%% Clean all COI
allCOI =[];

for COI = rawCOI([rawCOI.Working]>0)'
    
    %% Fix data codings.
    
    for iter0 = {'Number'	'OriginalIssuePrice'	'LiquidationMultiple'	'ConversionPrice' 'LiquidationValue' 'LiquidationPriority' 'Participation' 'ParticipationCapPresent'    'ParticipationCapMultiple'    'ParticipationCapValue'   'DividendRate'    'Dividend_'  'VotesPerShare'}
        try
            COI.s.(iter0{1}) = str2double(COI.s.(iter0{1})) ;
        end
    end
    
    for iter0 = {'AutomaticConversionProceedsMin'	'AutomaticConversionSharePriceMinValue'	'AutomaticConversionValuationMin'	'BothProceedsAndValuationNeeded'}
        COI.g.(iter0{1}) = str2double(COI.g.(iter0{1})) ;
    end
    
    for iter0 = { 'OriginalDateOfIncorporation','COIDate'}
        COI.g.(iter0{1}) = str2double(COI.g.(iter0{1}));
        COI.g.(iter0{1}) = datetime(COI.g.(iter0{1}),'ConvertFrom','excel');
    end
    
    for iter0 = {'COIDate'}
        COI.s.(iter0{1}) = datetime(COI.s.(iter0{1}),'InputFormat','M/d/yyyy');
    end
    
    for iter0 = {'SeparateVetoRightOverIPOExists' 'SeparateConversionVeto_No_ConversionInAtLeastSomeIPOs'}
        try
            COI.s.(iter0{1}) = ismember(COI.s.(iter0{1}),'1') ;
            
        end
    end
    %% Clean up COI
    
    if ~isnumeric(COI.s.RatchetLvl(1))
        COI.s.RatchetLvl = max(COI.s.Number*0,str2double(COI.s.RatchetLvl));
    end
    
    if iscell(COI.s.SeparateVetoRightOverIPOExists(1))
        COI.s.SeparateVetoRightOverIPOExists = 0<str2double(COI.s.SeparateVetoRightOverIPOExists);
    end
    if iscell(COI.s.SeparateConversionVeto_No_ConversionInAtLeastSomeIPOs(1))
        COI.s.SeparateConversionVeto_No_ConversionInAtLeastSomeIPOs = 0<str2double(COI.s.SeparateConversionVeto_No_ConversionInAtLeastSomeIPOs);
    end
    
    if ~ismember('ConversionCanBeForced', COI.g.Properties.VariableNames)
        COI.g.ConversionCanBeForced = 0;
    end
    
    if ~isnumeric(COI.PostmoneyValuation)
        COI.PostmoneyValuation = str2double(COI.PostmoneyValuation);
    end
    
    COI.s.OriginalIssuePrice(isnan(COI.s.OriginalIssuePrice))=COI.s.ConversionPrice(isnan(COI.s.OriginalIssuePrice));
   
   COI.s(ismember(COI.s.SecurityType,'Common')'&(1:numel(COI.s.SecurityType)>1),:) = [];
        
    if ~isnan(COI.CumulativeRdAmt)
        COI.s.Number(end) = COI.CumulativeRdAmt/COI.s.OriginalIssuePrice(end);
    end
    
    allCOI = [allCOI COI];
end


