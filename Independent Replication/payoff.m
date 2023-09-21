% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% This code was independantly produced by Timur Sobolev to replicate our results. 
%
% Author: Timur Sobolev  
% email: tsobolev@stanford.edu
% 2018; Last revision: Aug 2018
 
 
%Calculates the sections of a given contract's payoff functions.
%There are three sections in each investor's payoff in case of an M&A and 
%an IPO: liquidation, non-conversion and conversion. Thus, two borders
%each.
%Dividends to be fixed.

function [x_lo_ma, x_hi_ma, x_lo_ipo, x_hi_ipo] = payoff(I, sh, sh_c, l, s, m, v, t, e)

n = size(I,2); %number of investment rounds
x_lo_ma = zeros(1,n);
x_hi_ma = zeros(1,n);
x_lo_ipo = zeros(1,n);
x_hi_ipo = zeros(1,n);
liq = zeros(1,n+1);
conv = zeros(1,n+1);


%% M&A borders

for i = 1:n
    cs = s == s(i); %current seniority
    hs = s < s(i); %higher seniority
    x_lo_ma(i) = sum((hs + cs).*l.*I,2);
    
    if m(i) < inf %no cap participation contracts do not have a second kink
        sp = m(i)*l(i)*I(i)/(1+e(i))/sh(i);
        dec = (1+e).*sp.*sh - min(l.*I + (1+e).*sp.*sh, m.*l.*I) > -10^-5;
        x_hi_ma(i) = sum(dec.*sp.*sh + (1-dec).*min(l.*I + sp.*sh, m.*l.*I),2) + sp.*sh_c;
    else
        x_hi_ma(i) = inf;
    end
end
   
%% IPO borders

for i = 1:n %investor index
    s1 = (t == 0).*s; %ratchet investors are given higher seniority
    cs = s1 == s1(i); %current seniority
    hs = s1 < s1(i); %higher seniority
    v1 = [v, inf]; 
    %The current investor (i) may choose to convert at any point between 0
    %and his ACV value. Since the other investors' decisions depend on the
    %position of this point relative to their own ACV value, the following
    %loop has to check for optimal conversion between each other ACV value 
    %and the current investor's ACV value.
    for j = 1:n+1
        if ((m(i) < inf) && (v(i) >= v1(j)) && (v(i) > 0)) || (t(i) > 0)
            sp = max((v(i) >= v1(j))*m(i)*l(i)*I(i),t(i)*I(i))/(1+e(i))/sh(i); %conversion point share price
            dec = (1+e).*sp.*sh - max((v >= v1(j)).*min(l.*I + (1+e).*sp.*sh, m.*l.*I), t.*I) > -10^-5; %conversion decisions for given share price
            conv(j) = min(sum(dec.*sp.*sh + (1-dec).*max((v >= v1(j)).*min(l.*I + sp.*sh, m.*l.*I), t.*I),2) + sp.*sh_c,v1(j));

            p_nc = max((v >= v1(j)).*l.*I,t.*I);
            liq(j) = min(sum((hs+cs).*p_nc,2), v1(j));
        elseif (m(i) == inf) && (v(i) >= v1(j)) && (v(i) > 0)
            conv(j) = v1(j);

            p_nc = max((v >= v1(j)).*l.*I,t.*I);
            liq(j) = min(sum((hs+cs).*p_nc,2), v1(j));
        else 
            conv(j) = 0;
            liq(j) = 0;
        end
    end
    x_hi_ipo(i) = max(conv);
    x_lo_ipo(i) = max(liq);
end

end
