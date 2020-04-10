function str = num2sip(num,sgf,pfx,trz) %#ok<*ISMAT>
% Convert a scalar numeric into a metric-prefixed string (1xN char) (SI/engineering)
%
% (c) 2011-2020 Stephen Cobeldick
%
% Convert a scalar numeric value into a 1xN character vector, the value as
% a coefficient with a metric prefix, for example 1000 -> '1 k'. If the
% rounded |num|<10^-24 or |num|>=10^27 then E-notation is used, sans prefix.
%
%%% Syntax:
% str = num2sip(num)
% str = num2sip(num,sgf)
% str = num2sip(num,sgf,pfx)
% str = num2sip(num,sgf,pfx,trz)
%
%% Examples %%
%
% >> num2sip(10000)  OR  num2sip(1e4)
% ans = '10 k'
% >> num2sip(10000,4,true)
% ans = '10 kilo'
% >> num2sip(10000,4,false,true)
% ans = '10.00 k'
%
% >> num2sip(999,3)
% ans = '999 '
% >> num2sip(999,2)
% ans = '1 k'
%
% >> num2sip(0.5e6)
% ans = '500 k'
% >> num2sip(0.5e6,[],'M')
% ans = '0.5 M'
%
% >> ['Power: ',num2sip(200e6,[],true),'watt']
% ans = 'Power: 200 megawatt'
%
% >> sprintf('Clock frequency is %shertz.',num2sip(1234567890,3,true))
% ans = 'Clock frequency is 1.23 gigahertz.'
%
% >> num2sip(sip2num('9 T')) % 9 tera == 9e12 == 9*1000^4
% ans = '9 T'
%
%% SI Prefix Strings %%
%
% Order  |1000^1 |1000^2 |1000^3 |1000^4 |1000^5 |1000^6 |1000^7 |1000^8 |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Name   | kilo  | mega  | giga  | tera  | peta  | exa   | zetta | yotta |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Symbol*|   k   |   M   |   G   |   T   |   P   |   E   |   Z   |   Y   |
%
% Order  |1000^-1|1000^-2|1000^-3|1000^-4|1000^-5|1000^-6|1000^-7|1000^-8|
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Name   | milli | micro | nano  | pico  | femto | atto  | zepto | yocto |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Symbol*|   m   |   µ   |   n   |   p   |   f   |   a   |   z   |   y   |
%
%% Input and Output Arguments %%
%
%%% Inputs (*=default):
%  num = NumericScalar, the value to be converted to string <str>.
%  sgf = NumericScalar, the significant figures in the coefficient, 5*.
%  pfx = CharacterVector, forces the output to use that prefix, e.g. 'k', 'u'.
%      = LogicalScalar, true/false* -> select binary prefix as name/symbol.
%  trz = LogicalScalar, true/false* -> select if decimal trailing zeros are required.
%
%%% Output:
%  str = Input <num> as a 1xN char vector: coefficient + space character + SI prefix.
%
% See also SIP2NUM NUM2BIP BIP2NUM NUM2STR MAT2STR SPRINTF NUM2WORDS WORDS2NUM

%% Input Wrangling %%
%
% Uncomment your preferred output "micro" symbol:
%mu0 = 'u'; % ASCII (U+0075) 'LATIN SMALL LETTER U'
mu0 = char(181);  % (U+00B5) 'MICRO SIGN'
%mu0 = char(956); % (U+03BC) 'GREEK SMALL LETTER MU'
% Uncomment your preferred space character:
%wsp = ' '; % ASCII (U+0020) 'SPACE'
% wsp = char(160);  % (U+00A0) 'NO-BREAK SPACE'
wsp = '';  % (U+00A0) 'NO-BREAK SPACE'

% Prefix and corresponding power:
pfC = {'y'    ,'z'    ,'a'   ,'f'    ,'p'   ,'n'   ,mu0    ,'m'    ,'','k'   ,'M'   ,'G'   ,'T'   ,'P'   ,'E'  ,'Z'    ,'Y';...
       'yocto','zepto','atto','femto','pico','nano','micro','milli','','kilo','mega','giga','tera','peta','exa','zetta','yotta'};
vPw = [-24,    -21,    -18,   -15,    -12,   -9,    -6,     -3,     0, +3,    +6,    +9,    +12,   +15,   +18,  +21,    +24];
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
	adj = n2pAdjust(log10(abs(num)),dPw);
elseif ischar(pfx)&&ndims(pfx)==2&&size(pfx,1)<2 % user-requested prefix:
	pfx = regexprep(pfx,'^[u\xB5\x3BC]$',mu0);
	[idr,idc] = find(strcmp(pfC,pfx));
	if numel(idr)<1
% 		str = sprintf(', ''%s''',pfC{:});
        str = sprintf(', ''%s''',pfC{:});
		error('Third input <pfx> can be one of the following:%s.',str(2:end))
	end
	pfx = idr(1)>1;
	adj = vPw(idc([1,1]));
else % determine prefix powers pfx0<=pwr<pfx1:
	assert(islogical(pfx)&&isscalar(pfx),'Third input <pfx> can be a logical scalar.')
	adj = n2pAdjust(log10(abs(num)),dPw);
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
vec = num./10.^adj;
% Determine the number of decimal places:
p10 = 10.^(sgf-1-n2pPower(log10(abs(vec))));
% Round coefficients to decimal places:
vec = round(vec.*p10)./p10;
% Identify which prefix is required:
idx = 1+any(abs(vec)==[10.^dPw,1]);
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%num2sip
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