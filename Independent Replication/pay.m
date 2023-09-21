% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% This code was independantly produced by Timur Sobolev to replicate our results. 
%
% Author: Timur Sobolev  
% email: tsobolev@stanford.edu
% 2018; Last revision: Aug 2018
 
 
%Calculates the preferred payoffs of a contract given the kinks of the
%payoff function

function p = pay(x, a, exit, I, sh,sh_c,l,s,m,v,t,e,ac,x_lo_ma, x_hi_ma, x_lo_ipo, x_hi_ipo)
n = length(I);
% M&A payoffs
d = (x.*ones(1,n) > x_hi_ma);
p_l = l(a).*I(a)./sum((s == s(a)).*l.*I, 2).*max(x - sum((s < s(a)).*l.*I, 2),0);
p_nc = min(l.*I + p_c_ma(x, d, 1:n), m.*l.*I);
p_ma = (x <= x_lo_ma(a)).*p_l + (x > x_lo_ma(a)).*(x <= x_hi_ma(a)).*p_nc(:,a) + (x > x_hi_ma(a)).*p_c_ma(x, d, a);

% IPO payoffs
s1 = (t == 0).*s;
d = (x.*ones(1,n) > x_hi_ipo);
p_nc = max((x < v).*l.*I,t.*I);
p_l = p_nc(:,a)./(sum((s1 == s1(a)).*p_nc, 2) + (sum((s1 == s1(a)).*p_nc, 2) == 0)).*max(x - sum((s1 < s1(a)).*p_nc, 2),0);
p_nc = max((x < v).*min(l.*I + p_c_ipo(x, d, 1:n), m.*l.*I), t.*I);
p_ipo = (x <= x_lo_ipo(a)).*p_l + (x > x_lo_ipo(a)).*(x <= x_hi_ipo(a)).*p_nc(:,a) + (x > x_hi_ipo(a)).*p_c_ipo(x, d, a);

% Total payoff
p = (x < ac) .* p_ma + (x >= ac) .* (exit .* p_ipo + (1-exit) .* p_ma);

% Sub-functions
function p = p_c_ma(x, d, o)
p_nc = l.*I;
p = (1 + e).*sh./(sum((d + (1-d).*(m>1)).*sh,2) + sh_c).*max(x - sum((1-d).*p_nc,2),0);
cap = (1-d).*(m > 1).*(p_nc + p >= m.*l.*I); %investors who have reached cap
surp = zeros(length(x),n); %capped investors accounted for in coversion
for k = 1:sum((m > 1).*(m < inf),2)
    nocap = d + (1-d).*(m > 1).*(p_nc + p < m.*l.*I); %investors who have not reached their cap
    surp = surp + cap; 
    p = p + min((1 + e).*nocap.*sh./(sum(nocap.*sh,2) + sh_c),1).*sum(cap.*(p + p_nc - m.*l.*I),2);
    cap = (1-d).*(m > 1).*(p_nc + p >= m.*l.*I) - surp; %investors who have reached their cap, but haven't been accounted for
end
p = p(:,o);
end

function p = p_c_ipo(x, d, o)
p_nc = (x < v).*max(t,l).*I + (x >= v).*t.*I;
p = (1 + e).*sh./(sum((d + (1-d).*(m>1).*(x<v)).*sh,2) + sh_c).*max(x - sum((1-d).*p_nc,2),0);
cap = (1-d).*(m > 1).*(x < v).*(p_nc + p >= m.*l.*I); %investors who have reached cap
surp = zeros(length(x),n); %capped investors accounted for in coversion
for k = 1:sum((m > 1).*(m < inf).*(x < v),2)
    nocap = d + (1-d).*(m > 1).*(x < v).*(p_nc + p < m.*l.*I); %investors who have not reached their cap
    surp = surp + cap; 
    p = p + min((1 + e).*nocap.*sh./(sum(nocap.*sh,2) + sh_c),1).*sum(cap.*(p + p_nc - m.*l.*I),2);
    cap = (1-d).*(m > 1).*(x < v).*(p_nc + p >= m.*l.*I) - surp; %investors who have reached their cap, but haven't been accounted for
end
p = p(:,o);
end

end