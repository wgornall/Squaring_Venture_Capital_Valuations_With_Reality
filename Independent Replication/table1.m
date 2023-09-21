% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% This code was independantly produced by Timur Sobolev to replicate our results. 
%
% Author: Timur Sobolev  
% email: tsobolev@stanford.edu
% 2018; Last revision: Aug 2018
 
%% Setup

n = 10^5;
[T, z] = MC(n);
i = 1;
TV = zeros(20,1);
tv_c = TV;

%% Baseline values

I = [50, 100]; %investment amounts
pmv = [450, 1000]; %post-money valuations
pool = 0.05;
sh = [100, 100, 750]; %Number of shares owned, last is number of common shares
l = [1, 1]; %Liquidation multiple
s = [1, 1]; %Seniority
m = [1, 1]; %Participation cap multiple. Note that 1 = no participation
v = [0, 0]; %ACV value
t = [0, 0]; %ratchet multiple
e = [0, 0]; %dividends, not important for table 1
ac = 0; %ACE, not important for table 1

%% Scenarios 

%Baseline
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%1.25X LM
l(end) = 1.25;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%1.5X LM
l(end) = 1.5;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%2X LM
l(end) = 2;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

l(end) = 1; %Returning to baseline value

%Option pool 0% 
sh(end) = 800;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%Option pool 10%
sh(end) = 700; 
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

sh(end) = 750; %Returning to baseline value

%Junior
s = [1, 2];
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%Senior
s = [2, 1];
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

s = [1,1]; %Returning to baseline value

%Participation no cap 
m(end) = inf;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%Participation 2.5X cap
m(end) = 2.5;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

m = [1, 1]; %Returning to baseline value

%IPO ratchet 1X
t(end) = 1;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%IPO ratchet 1.25X 
t(end) = 1.25;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%IPO ratchet 1.5X
t(end) = 1.5;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

t(end) = 0; %Returning to baseline value

%ACV below 1X
v(end) = 1000;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%ACV below 0.75X
v(end) = 750;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%ACV below 0.5X
v(end) = 500;
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

v(end) = 0; %Returning to baseline value

%I2 = 400
I(end) = 400;
sh = [200/3, 400, 1450/3];
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%I2 = 10
I(end) = 10;
sh = [110, 10, 830];
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

I(end) = 100; %Returning to baseline value

%I1 = 400
I(end-1) = 400;
sh = [800, 100, 50];
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%I1 = 10
I(end-1) = 10;
sh = [20, 100, 830];
[TV(i), tv_c(i)] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac);
tv_c(i) = tv_c(i)/sh(end);
i = i + 1;

%% Table 

dv = 1000./TV - 1;
dc = 1./tv_c - 1;
var = {'Company_FV','dv','Common_FV','dc'};
scen = {'Baseline';'1.25X LM';'1.5X LM';'2X LM';'0% Option pool';'10% Option pool';'Junior';'Senior';'No cap';'2.5X Cap';'1X Ratchet';'1.25X Ratchet';'1.5X Ratchet';'1X ACV';'0.75X ACV';'0.5X ACV';'I2 = $400M';'I2 = $10M';'I1 = $400M';'I1 = $10M'};
res = table(TV,dv,tv_c,dc,'RowNames',scen,'VariableNames',var)






