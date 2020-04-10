%% NUM2SIP and NUM2BIP Examples
% The function <https://www.mathworks.com/matlabcentral/fileexchange/33174
% |NUM2SIP|> converts a numeric scalar to a character vector of the number
% value with a <https://en.wikipedia.org/wiki/Metric_prefix metric prefix>,
% for example 1000 -> '1 k'. Optional arguments control the number of
% digits, select the prefix symbol or prefix name, and any trailing zeros:
% this document shows examples of how to use these features.
%
% The development of |NUM2SIP| was motivated by the lack of any well-
% written function that provides this conversion: many of the functions
% available on FEX do not conform to the SI standard, or use buggy
% conversion algorithms, or are simply painfully slow. |NUM2SIP| has been
% tested against a large set of test cases, including many edge-cases
% and with all of the optional arguments.
%% Basic Usage
% In many cases |NUM2SIP| can be called with just a numeric value:

num2sip(1000)
num2sip(1.2e+3)
num2sip(456e-7)
%% 2nd Input: Significant Figures
% |NUM2SIP| returns five significant figures by default. The optional
% second input argument specifies the number of significant figures.
% Note that |NUM2SIP| correctly rounds upwards to the next prefix:
num2sip(987000,3)
num2sip(987000,2)
num2sip(987000,1)
%% 3rd Input: Symbol or Full Prefix
% |NUM2SIP| returns the prefix symbol by default. The optional third input
% argument selects between the symbol and the full prefix name.
num2sip(1e6,[],false) % default
num2sip(1e6,[],true)
%% 3rd Input: Fixed Prefix
% |NUM2SIP| allow the prefix to be selected by the user, and all outputs
% will be given as coefficients of the selected prefix. For convenience
% the "micro" symbol may be provided as |'u'| or (U+00B5) or (U+03BC).
num2sip(10^2,[],'k')
num2sip(10^4,[],'k')
num2sip(10^6,[],'k')
%% 4th Input: Trailing Zeros
% |NUM2SIP| removes trailing zeros by default. The optional fourth input
% argument selects between removing and keeping any trailing zeros:
num2sip(1000,3,[],false) % default
num2sip(1000,3,[],true)
%% Larger/Smaller Values Without a Prefix
% If the magnitude of the input value is outside the prefix range, then no
% prefix is used and the value is returned in exponential notation:
num2sip(9e-87)
num2sip(2e+34)
%% Micro Symbol
% By default |NUM2SIP| uses the "micro" symbol from ISO 8859-1, i.e. Unicode
% (U+00B5) 'MICRO SIGN'. Simply edit the Mfile to select an alternative
% "micro" symbol, e.g. ASCII |'u'| or (U+03BC) 'GREEK SMALL LETTER MU'.
num2sip(5e-6) % default = (U+00B5) 'MICRO SIGN'
%% Space Character
% The standard for the International System of Quantities (ISQ)
% <https://en.wikipedia.org/wiki/International_System_of_Quantities
% ISO/IEC 80000> (previously ISO 31) specifies that
% <http://www.electropedia.org/iev/iev.nsf/display?openform&ievref=112-01-17
% _"there is a space between the numerical value and the unit symbol"_>.
% Note that this applies even when there is just the unit, i.e. no SI prefix.
% |NUM2SIP| correctly includes the space character in all cases (by default
% using (U+00A0) 'NO-BREAK SPACE'):
sprintf('%sV',num2sip(1e-3))
sprintf('%sV',num2sip(1e+0))
sprintf('%sV',num2sip(1e+3))
sprintf('%sV',num2sip(1e99))
%% Binary Prefix Function |NUM2BIP|
% The submission includes the bonus function |NUM2BIP|: this also converts
% a numeric scalar to a prefixed string which uses the ISO 80000 defined
% <https://en.wikipedia.org/wiki/Binary_prefix binary prefixes> instead of
% metric prefixes. Binary prefixes are mostly used for computer memory.
%
% The function |NUM2BIP| has exactly the same arguments as |NUM2SIP|:
num2bip(1024)
num2bip(1025,5,true,true)
%% Reverse Conversion: String to Numeric
% The functions <https://www.mathworks.com/matlabcentral/fileexchange/53886
% |SIP2NUM| and |BIP2NUM|> convert from prefixed strings into numerics:
sip2num('10 M')
bip2num('10 Mi')