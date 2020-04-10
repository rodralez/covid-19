function str = num2bip(num,sgf,pfx,trz) %#ok<*ISMAT>
% Convert a scalar numeric into a binary-prefixed string (1xN char) (ISO/IEC 80000-13)
%
% (c) 2011-2020 Stephen Cobeldick
%
% Convert a scalar numeric value into a 1xN character vector, the value as
% a coefficient with a binary prefix, for example 1024 -> '1 Ki'. If the
% rounded |num|<10^-4 or |num|>=1024^9 then E-notation is used, sans prefix.
%
%%% Syntax:
% str = num2bip(num)
% str = num2bip(num,sgf)
% str = num2bip(num,sgf,pfx)
% str = num2bip(num,sgf,pfx,trz)
%
%% Examples %%
%
% >> num2bip(10240)  OR  num2bip(1.024e4)  OR  num2bip(pow2(10,10))  OR  num2bip(10*2^10)
% ans = '10 Ki'
% >> num2bip(10240,4,true)
% ans = '10 kibi'
% >> num2bip(10240,4,false,true)
% ans = '10.00 Ki'
%
% >> num2bip(1023,3)
% ans = '1020 '
% >> num2bip(1023,2)
% ans = '1 Ki'
%
% >> num2bip(pow2(19))
% ans = '512 Ki'
% >> num2bip(pow2(19),[],'Mi')
% ans = '0.5 Mi'
%
% >> ['Memory: ',num2bip(pow2(200,20),[],true),'byte']
% ans = 'Memory: 200 mebibyte'
%
% >> sprintf('Data saved in %sbytes.',num2bip(1234567890,3,true))
% ans = 'Data saved in 1.15 gibibytes.'
%
% >> num2bip(bip2num('9 Ti')) % 9 tebi == pow2(9,40) == 9*1024^4
% ans = '9 Ti'
%
%% Binary Prefix Strings (ISO/IEC 80000-13) %%
%
% Order  |1024^1 |1024^2 |1024^3 |1024^4 |1024^5 |1024^6 |1024^7 |1024^8 |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Name   | kibi  | mebi  | gibi  | tebi  | pebi  | exbi  | zebi  | yobi  |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Symbol*|  Ki   |  Mi   |  Gi   |  Ti   |  Pi   |  Ei   |  Zi   |  Yi   |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
%
%% Input and Output Arguments %%
%
%%% Inputs (*=default):
%  num = NumericScalar, the value to be converted to string <str>.
%  sgf = NumericScalar, the significant figures in the coefficient, 5*.
%  pfx = CharacterVector, forces the output to use that prefix, e.g. 'Ki'.
%      = LogicalScalar, true/false* -> select binary prefix as name/symbol.
%  trz = LogicalScalar, true/false* -> select if decimal trailing zeros are required.
%
%%% Output:
%  str = Input <num> as a 1xN char vector: coefficient + space character + binary prefix.
%
% See also BIP2NUM NUM2SIP SIP2NUM NUM2STR MAT2STR SPRINTF NUM2WORDS WORDS2NUM

%% Input Wrangling %%
%
% Uncomment your preferred space character:
%wsp = ' '; % ASCII (U+0020) 'SPACE'
wsp = char(160);  % (U+00A0) 'NO-BREAK SPACE'
%
% Prefix and corresponding power:
pfC = {'','Ki'  ,'Mi'  ,'Gi'  ,'Ti'  ,'Pi'  ,'Ei'  ,'Zi'  ,'Yi';...
       '','kibi','mebi','gibi','tebi','pebi','exbi','zebi','yobi'};
vPw = [0, +10,   +20,   +30,   +40,   +50,   +60,   +70,   +80];
dPw = unique(diff(vPw));
assert(isscalar(dPw),'Something is wrong with the vector of powers...')
%
assert(isnumeric(num)&&isscalar(num)&&isreal(num),'First input <num> must be a real numeric scalar.')
num = double(num);
%
if nargin<2 || isnumeric(sgf)&&isempty(sgf) % default
	sgf = 5;
else
	assert(isnumeric(sgf)&&isscalar(sgf)&&isreal(sgf),'Second input <sgf> must be a real numeric scalar.')
	sgf = double(sgf);
end
%
if nargin<3 || isnumeric(pfx)&&isempty(pfx) % default
	pfx = false;
	adj = n2pAdjust(log2(abs(num)),dPw);
elseif ischar(pfx)&&ndims(pfx)==2&&size(pfx,1)<2 % user-requested prefix:
	[idr,idc] = find(strcmp(pfC,pfx));
	if numel(idr)<1
		str = sprintf(', ''%s''',pfC{:});
		error('Third input <pfx> can be one of the following:%s.',str(2:end))
	end
	pfx = idr(1)>1;
	adj = vPw(idc([1,1]));
else % determine prefix powers pfx0<=pwr<pfx1:
	assert(islogical(pfx)&&isscalar(pfx),'Third input <pfx> can be a logical scalar.')
	adj = n2pAdjust(log2(abs(num)),dPw);
end
%
if nargin<4 || isnumeric(trz)&&isempty(trz) % default
	trz = false;
else
	assert(islogical(trz)&&isscalar(trz),'Fourth input <trz> must be a logical scalar.')
end
%
%% Generate String %%
%
% Obtain the coefficients:
vec = pow2(num,-adj);
% Determine the number of decimal places:
p10 = 10.^(sgf-1-n2pPower(log10(abs(vec))));
% Round coefficients to decimal places:
vec = round(vec.*p10)./p10;
% Identify which prefix is required:
idx = 1+any(abs(vec)==[pow2(dPw),1]);
% Obtain the required prefix index:
idp = vPw==adj(idx);
if any(idp) % Use prefix:
	pwr = 1+n2pPower(log10(abs(vec(idx))));
	fmt = n2pFormat(trz,sgf,pwr);
	str = sprintf(fmt,max(sgf,pwr),vec(idx),wsp,pfC{1+pfx,idp});
else % No suitable prefix:
	fmt = n2pFormat(trz,sgf,1);
	str = sprintf(fmt,sgf,num,wsp,'');
end
%
%str = strrep(str,'-',char(8722)); % (U+2212) 'MINUS SIGN'
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%num2bip
function pwr = n2pPower(pwr)
pwr = floor(pwr);
pwr(~isfinite(pwr)) = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2pPower
function adj = n2pAdjust(pwr,dPw)
adj = dPw*((0:1)+floor(n2pPower(pwr)/dPw));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2pAdjust
function fmt = n2pFormat(trz,sgf,pwr)
if trz && (sgf>pwr)
	fmt = '%#.*g%s%s';
else
	fmt = '%.*g%s%s';
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2pFormat