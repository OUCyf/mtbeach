function u = beta2u(beta)
%BETA2V u(beta) for lune colatitude
%
% INPUT
%   beta    n x 1 vector of lune colatitudes, radians
%
% OUTPUT
%   u       n x 1 vector
%
% From Tape and Tape (2015 GJI) "A uniform parameterization for moment tensors"
%
% Example values:
%   beta2u(0) = 0
%   beta2u(pi/2) = 3*pi/8 = 1.1781
%   beta2u(pi) = 2*pi/4 = 2.3562
%

u = (3/4)*beta - (1/2)*sin(2*beta) + (1/16)*sin(4*beta);
