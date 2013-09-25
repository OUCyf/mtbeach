function [xi0,xi,q,ixi0,trALL,imaxtr] = U2xi0(U,iorthoU,idisplay)
%U2XI0 convert rotation matrix to rotation angle
%
% INPUT
%   U         3 x 3 x n set of rotation matrices
%   iorthoU   =1 to use quaternions for orthogonalization
%                (this is a technicality that is generally not necessary)
%                (THIS PART NEEDS ADDITIONAL CHECKING)
%   idisplay  optional: display details (=1)
%
% OUTPUT   
%   xi0     n x 1 set of minimum rotation angles (a.k.a. kagan angle, principal axis angle)
%   xi      n x 1 set of rotation angles
%   q       4 x n set of unit quaternions
%   ixi0    index into subset zone (=1 for w; =2 for x; =3 for y; =4 for z)
%   trALL   OPTIONAL: 4 x n set of tr(U, U*Xpi, etc)
%   imaxtr  OPTIONAL: index into trALL for the max trace
%
% See TapeTape2012, "Angle between principal axis triples"
% 
% Carl Tape, 8/12/2012
%

if ~exist('idisplay','var'), idisplay = 0; end 

[~,~,n] = size(U);

u11 = squeeze(U(1,1,:));
u12 = squeeze(U(1,2,:));
u13 = squeeze(U(1,3,:));
u21 = squeeze(U(2,1,:));
u22 = squeeze(U(2,2,:));
u23 = squeeze(U(2,3,:));
u31 = squeeze(U(3,1,:));
u32 = squeeze(U(3,2,:));
u33 = squeeze(U(3,3,:));

% reshape to row vectors
u11 = u11(:)'; u12 = u12(:)'; u13 = u13(:)';
u21 = u21(:)'; u22 = u22(:)'; u23 = u23(:)';
u31 = u31(:)'; u32 = u32(:)'; u33 = u33(:)';

% unit quaternion (Eq F1a)
% w > 0 since trU > -1 for rotation matrices
qww = 0.5 * sqrt(1 + u11 + u22 + u33);
qwx = (u32-u23)./(4*qww);
qwy = (u13-u31)./(4*qww);
qwz = (u21-u12)./(4*qww);

% qxx = 0.5 * sqrt(1 + u11 - u22 - u33);
% qxw = (u32-u23)./(4*qxx);
% qxy = (u12+u21)./(4*qxx);
% qxz = (u13+u31)./(4*qxx);
% 
% qyy = 0.5 * sqrt(1 - u11 + u22 - u33);
% qyw = (u13-u31)./(4*qyy);
% qyx = (u12+u21)./(4*qyy);
% qyz = (u23+u32)./(4*qyy);
% 
% qzz = 0.5 * sqrt(1 - u11 - u22 + u33);
% qzw = (u21-u12)./(4*qzz);
% qzx = (u13+u31)./(4*qzz);
% qzy = (u23+u32)./(4*qzz);

qw = [ qww ;  qwx ;  qwy ;  qwz];
%qx = [ qxw ;  qxx ;  qxy ;  qxz];
%qy = [ qyw ;  qyx ;  qyy ;  qyz];
%qz = [ qzw ;  qzx ;  qzy ;  qzz];

q = qw;

if iorthoU==1
    % TT2012, before Eq F9a:
    % "For a given U the best choice q0 among qw, qx, qy, qz is therefor
    % determined by which if U, UXpi, UYpi, UZpi has the largest trace or,
    % equivalently, by which has the smallest rotation angle."
    Xpi = diag([ 1 -1 -1]);
    Ypi = diag([-1  1 -1]);
    Zpi = diag([-1 -1  1]);
    trALL = NaN(4,n);
    for kk=1:n
       U0 = U(:,:,kk);
       trALL(:,kk) = [sum(diag(U0))     ; sum(diag(U0*Xpi)) ;
                      sum(diag(U0*Ypi)) ; sum(diag(U0*Zpi)) ];
    end
    [~,imaxtr] = max(trALL);
    
    % REPLACE q with the q based on max trace (case 1: do nothing)
    for ii=1:n
        switch imaxtr(ii)
            case 2
                x = 0.5 * sqrt(1 + u11(ii) - u22(ii) - u33(ii));
                q(1,ii) = (u32(ii)-u23(ii))/(4*x);
                q(2,ii) = x;
                q(3,ii) = (u12(ii)+u21(ii))/(4*x);
                q(4,ii) = (u13(ii)+u31(ii))/(4*x);
            case 3
                y = 0.5 * sqrt(1 - u11(ii) + u22(ii) - u33(ii));
                q(1,ii) = (u13(ii)-u31(ii))/(4*y);
                q(2,ii) = (u12(ii)+u21(ii))/(4*y);
                q(3,ii) = y;
                q(4,ii) = (u23(ii)+u32(ii))/(4*y);
            case 4
                z = 0.5 * sqrt(1 - u11(ii) - u22(ii) + u33(ii));
                q(1,ii) = (u21(ii)-u12(ii))/(4*z);
                q(2,ii) = (u13(ii)+u31(ii))/(4*z);
                q(3,ii) = (u23(ii)+u32(ii))/(4*z);
                q(4,ii) = z;
        end
    end 
    % ensure that first entry of quaternion is positive (convention)
    % warning: this will turn an imaginary-valued q to real-valued
    q = convertq(q);
    
    % TT2012 Eq 11: U*Xpi, U*Ypi, U*Zpi
    w1 = q(1,:);
    x1 = q(2,:);
    y1 = q(3,:);
    z1 = q(4,:);
    qi = [-x1 ;  w1 ; -z1 ; -y1];
    qj = [-y1 ; -z1 ;  w1 ;  x1];
    qk = [-z1 ;  y1 ; -x1 ;  w1];
    qi = convertq(qi);
    qj = convertq(qj);
    qk = convertq(qk);
end

% compute the kagan angle: Eq 34 of TapeTape2012
[val,ixi0] = max(abs(q));
%[val,ixi0] = max([w ; x ; y; z]);
xi0 = 2*acos(val)*180/pi;
xi0 = xi0(:);

% rotation angle: Eq 34 of TapeTape2012
xi = 2*acos(q(1,:))*180/pi;

if and(any(~isreal(q(1,:))),iorthoU==0)
    disp('WARNING (U2xi0.m): imaginary entry in w, x, y, z');
    %error('imaginary entry in w, x, y, z');
end

if idisplay==1
    stlab1 = {'w','x','y','z'};
    stlab2 = {'q(U)','q(U*Xpi)','q(U*Ypi)','q(U*Zpi)'};
    stfmt = '%24.12f%20.12f%20.12f';
    for kk=1:n
        U0 = U(:,:,kk);
        disp(sprintf('input U (%i/%i):',kk,n));
        for ii=1:3, disp(sprintf(stfmt,U0(ii,:))); end
        disp('UT*U:'); UTU = U0'*U0;
        for ii=1:3, disp(sprintf(stfmt,UTU(ii,:))); end
        disp('det(U):'); det(U0)
        disp(sprintf('%11s%9.4f%9.4f%9.4f%9.4f','q(U):',q(:,kk)'));
        if any(~isreal(q(:,kk)))
            disp('WARNING: imaginary entry in q');
            disp('q = '); q(kk)
        else
            if iorthoU==1
                disp('computing trace to pick the best choice for orthogonalization:');    
                disp('quaternions:');
                %whos qw qi qj qk trALL
                qdisp = [qw(:,kk) qi(:,kk) qj(:,kk) qk(:,kk) q(:,kk)];
                disp(sprintf('%20s%9s%9s%9s',stlab2{:}));
                for ii=1:4
                    disp(sprintf('%11s%9.4f%9.4f%9.4f%9.4f%9.4f',stlab1{ii},qdisp(ii,:)));
                end
                disp(sprintf('%11s%9.4f%9.4f%9.4f%9.4f%9.4f','trace',trALL(:,kk)));
                disp(sprintf('      --> max trace is for %s',stlab2{imaxtr(kk)}));
                %disp(sprintf('%20s%9s%9s%9s','w','x','y','z'));
                %disp(sprintf('%20.4f%9.4f%9.4f%9.4f',w(kk),x(kk),y(kk),z(kk)));
                %disp(sprintf('  max(|w|,|x|,|y|,|z|) = %.4f',val(kk)));
            end
            disp(sprintf('              max(|q|) = %.4f',val(kk)));
            disp(sprintf('        rotation angle = %.3f deg (w)',xi(kk)));
            disp(sprintf('minimum rotation angle = %.3f deg (%s)',xi0(kk),stlab1{ixi0(kk)}));
            disp('--------------------');
        end
    end
end

%==========================================================================
% EXAMPLES

if 0==1
    clear, close all, clc
    % example bases from Kagan (1991)
    % U1 and U2 are NOT quite orthogonal
    % optional: transform from south-east-up to north-west-up
    P = [-1 0 0 ; 0 -1 0 ; 0 0 1];
    U1 = P * U2pa([24 120 41 232],0,0); % not orthogonal
    U2 = P * U2pa([55 295 17 51],0,0);  % not orthogonal
    U1o1 = Uorth(U1,1);
    U2o1 = Uorth(U2,1);
    U1o2 = Uorth(U1,2);
    U2o2 = Uorth(U2,2);
    disp('INPUT U1:'); U2xi0(U1,0,1);
    disp('INPUT U1o1 (svd):'); U2xi0(U1o1,0,1);
    disp('INPUT U1o2 (tape):'); U2xi0(U1o2,0,1);
    disp('INPUT U2:'); U2xi0(U2,1,1);
    disp('INPUT U2o1 (svd):'); U2xi0(U2o1,0,1);
    disp('INPUT U2o2 (tape):'); U2xi0(U2o2,0,1);
    disp('now consider the matrix U = U1o2T * U2o2:');
    U = U1o2'*U2o2;         % since these are orthogonal, transpose = inverse
    xi0 = U2xi0(U,0,1);
    xi0 = U2xi0(U,1,1);     % display more (check with TapeTape2012, Eq E1)
    
    %---------------------------------------
    % test for non-orthogonal matrices
    [xi0,xi,q,ixi0,trALL,imaxtr]= U2xi0(U1,1,1);
    xi_check = U2xi(U1)
    [xi0,xi,q,ixi0,trALL,imaxtr]= U2xi0(U2,1,1);
    xi_check = U2xi(U2)
    
    % try two at once (input U are orthogonal)
    U(:,:,1) = U1o1; U(:,:,2) = U2o1;
    [xi0,xi,q,ixi0,trALL,imaxtr] = U2xi0(U,1,1);
    
    % check rotation angles with simpler operation
    xi_check = U2xi(U)
    
    %---------------------------------------
    % random rotation matrices
    n = 1e5;
    U = randomU(n);
    [xi0,ixi0,q] = U2xi0(U,0,0); figure; plot_histo(xi0,[0:5:120]);
    xlabel('xi0, principal axis angle'); title('random rotation matrices');
    
    %---------------------------------------
    % try several sets
    % here we use each GCMT basis to represent U = U1'*U2
    isub = 1:10000;
    [otime,tshift,hdur,lat,lon,dep,M] = readCMT(isub);
    n = length(otime);
    [~,U] = CMTdecom(M);
    U = Udetcheck(U);   % ensure that U are rotation matrices
    xi0 = U2xi0(U,0); figure; plot_histo(xi0,[0:5:120]);
    xlabel('xi0, principal axis angle');
end

%==========================================================================
