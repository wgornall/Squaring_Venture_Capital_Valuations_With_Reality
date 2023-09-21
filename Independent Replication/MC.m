% Squaring Venture Capital Valuations With Reality - Will Gornall and Ilya A. Strebulaev
% Supporting Code
%
% This code was independantly produced by Timur Sobolev to replicate our results. 
%
% Author: Timur Sobolev  
% email: tsobolev@stanford.edu
% 2018; Last revision: Aug 2018
 
 
function [T z] = MC(n)
z = randn(n,1);
T = exprnd(4,n,1);
end

