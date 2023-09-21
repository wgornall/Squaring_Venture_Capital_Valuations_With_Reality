% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% This code was independantly produced by Timur Sobolev to replicate our results. 
%
% Author: Timur Sobolev  
% email: tsobolev@stanford.edu
% 2018; Last revision: Aug 2018
 
 
function [TV, tv_c] = tv(T, z, I, pmv, sh, l, s, m, v, t, e, ac)
a = length(I); %investor of interest
n = length(I); %total number of investors
sh_c = sh(:,size(sh,2)); %number of common shares
sh = sh(:,1:size(sh,2)-1); %vector of preferred shares
sig = 0.9; %value volatility
r = 0.025; %interest rate
pr = 10^-1; %precision level
iter = 3000; %after this number of iterations the function gives out 9876543210 as a form of error message

%% Finding the fair value based on preferred payoff:

%Uncomment to add non-standard terms specified in a separate file
% [sh, l, s, m, v, t, e, ac] = special(x, I, pmv, T, sh, l, s, m, v, t, e, ac, w);

%Calculating the kinks in the payoff function of each investor
[x_lo_ma, x_hi_ma, x_lo_ipo, x_hi_ipo] = payoff(I,sh,sh_c,l,s,m,v,t,e);

%Simulating a vector of exit values (x)
x0 = pmv(length(pmv)); %initial guess equal to the last PMV
dx = exp(sig * sqrt(T) .* z + (r - sig^2/2) * T); % X(T)/X(0)
dx = dx/mean(dx.*exp(-r*T)); 
x = x0 * dx;

%Finding the present value of payoffs for each simulated value of x
p0 = exp(-T * r) .* pay(x,a,prob(x),I,sh,sh_c,l,s,m,v,t,e,ac,x_lo_ma,x_hi_ma,x_lo_ipo,x_hi_ipo); % preferred payoff at time 0
co = cov(p0,T);
co = co(1,2); 
p0 = p0 - co/var(T)*(T-4); %payoff with regression sampling
er = mean(p0) - I(a); %deviation of payoff from investment

%Interval for the fair value
x1 = max(min(x0, x0 - 1000*er), 0.5*x0);
x2 = min(max(x0, x0 - 1000*er), 1.4*x0);

%Finding the fair value 
j = 1;
while and(abs(er) > pr,j < iter) 
    x0 = (x1 + x2)/2; %new guess
    x = x0 * dx;
    p0 = exp(-T * r) .* pay(x,a,prob(x),I,sh,sh_c,l,s,m,v,t,e,ac,x_lo_ma,x_hi_ma,x_lo_ipo,x_hi_ipo);
    if isequal(p0,0) %error check
        x0 = 0;
        break
    end
    co = cov(p0,T);
    co = co(1,2);
    p0 = p0 - co/var(T)*(T-4);
    er = mean(p0) - I(a); %new deviation
    j = j + 1;
  
    %note that both ends of the interval move in case the original interval missed completely
    if er > pr %moving the guess left
        x1 = x1 - er;  
        x2 = (x1 + x2)/2;
    elseif er < -pr %moving the guess right
        x1 = (x1 + x2)/2;
        x2 = x2 - er;
    else 
        break
    end
end

TV = (j < iter).*x0 + (j >= iter).*9876543210;

%% Common payoff:

%Common shareholders receive the rest of the payoff
com = x - sum(pay(x,1:n,prob(x),I,sh,sh_c,l,s,m,v,t,e,ac,x_lo_ma,x_hi_ma,x_lo_ipo,x_hi_ipo),2);
p0c = exp(-T * r) .* com; %common payoff at time 0
co_c = cov(p0c,T);
co_c = co_c(1,2);
p0c = p0c - co_c/var(T)*(T-4); %common payoff with regression sampling

tv_c = mean(p0c); %expected common payoff

end