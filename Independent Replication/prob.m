% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% This code was independantly produced by Timur Sobolev to replicate our results. 
%
% Author: Timur Sobolev  
% email: tsobolev@stanford.edu
% 2018; Last revision: Aug 2018
 
 
function f = prob(x)
p1 = 0.65*(log10(x)-log10(32))/(3-log10(32));
p2 = 0.65 + 0.1*(log10(x)-3);
f = (x > 32) .* (x < 1000) .* p1 + (x >= 1000) .* (x < 100000) .* p2 + (x >= 100000);
end

