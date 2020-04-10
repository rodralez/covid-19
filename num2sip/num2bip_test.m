function num2bip_test()
% Test function for NUM2BIP.
%
% (c) 2011-2020 Stephen Cobeldick
%
% See Also TESTFUN NUM2BIP BIP2NUM SUN2SIP SIP2NUM

fun = @num2bip;
chk = testfun(fun);
%
%% Help Examples %%
%
chk(1024, fun, '1 Ki')
chk(10240,              fun, '10 Ki')
chk(1.024e4,            fun, '10 Ki')
chk(pow2(10,10),        fun, '10 Ki')
chk(10*2^10,            fun, '10 Ki')
chk(10240,4,true,       fun, '10 kibi')
chk(10240,4,false,true, fun, '10.00 Ki')
chk(1023,3, fun, '1020 ')
chk(1023,2, fun, '1 Ki')
chk(pow2(19),         fun, '512 Ki')
chk(pow2(19),[],'Mi', fun, '0.5 Mi')
chk(pow2(200,20),[],true, fun, '200 mebi') % byte
chk(1234567890,8,true, fun, '1.1497809 gibi') % byte
% chk(bip2num('9 Ti'), fun, '9 Ti') % 9 tebi
%
%% Edge Cases %%
%
chk(0, fun, '0 ')
chk(NaN, fun, 'NaN ')
chk(+Inf, fun, 'Inf ')
chk(-Inf, fun, '-Inf ')

%% Rounding %%
%
% sgf == default
chk(999,      fun, '999 ')
chk(999.9999, fun, '1000 ')
chk(1000,     fun, '1000 ')
% sgf == 6
chk(1023,       6, fun, '1023 ')
chk(1023.9,     6, fun, '1023.9 ')
chk(1023.99,    6, fun, '1023.99 ')
chk(1023.999,   6, fun, '0.999999 Ki')
chk(1023.9999,  6, fun, '1 Ki')
chk(1023.99999, 6, fun, '1 Ki')
chk(1023.999999,6, fun, '1 Ki')
chk(1024,       6, fun, '1 Ki')
chk(1023,       6,[],true, fun, '1023.00 ')
chk(1023.9,     6,[],true, fun, '1023.90 ')
chk(1023.99,    6,[],true, fun, '1023.99 ')
chk(1023.999,   6,[],true, fun, '0.999999 Ki')
chk(1023.9999,  6,[],true, fun, '1.00000 Ki')
chk(1023.99999, 6,[],true, fun, '1.00000 Ki')
chk(1023.999999,6,[],true, fun, '1.00000 Ki')
chk(1024,       6,[],true, fun, '1.00000 Ki')
% sgf == 1:9
chk(1023.999,1,[],true, fun, '1 Ki')
chk(1023.999,2,[],true, fun, '1.0 Ki')
chk(1023.999,3,[],true, fun, '1.00 Ki')
chk(1023.999,4,[],true, fun, '1.000 Ki')
chk(1023.999,5,[],true, fun, '1.0000 Ki')
chk(1023.999,6,[],true, fun, '0.999999 Ki')
chk(1023.999,7,[],true, fun, '1023.999 ')
chk(1023.999,8,[],true, fun, '1023.9990 ')
chk(1023.999,9,[],true, fun, '1023.99900 ')
chk(10239.99,1,[],true, fun, '10 Ki')
chk(10239.99,2,[],true, fun, '10 Ki')
chk(10239.99,3,[],true, fun, '10.0 Ki')
chk(10239.99,4,[],true, fun, '10.00 Ki')
chk(10239.99,5,[],true, fun, '10.000 Ki')
chk(10239.99,6,[],true, fun, '9.99999 Ki')
chk(10239.99,7,[],true, fun, '9.999990 Ki')
chk(10239.99,8,[],true, fun, '9.9999902 Ki')
chk(10239.99,9,[],true, fun, '9.99999023 Ki')
chk(102399.9,1,[],true, fun, '100 Ki')
chk(102399.9,2,[],true, fun, '100 Ki')
chk(102399.9,3,[],true, fun, '100 Ki')
chk(102399.9,4,[],true, fun, '100.0 Ki')
chk(102399.9,5,[],true, fun, '100.00 Ki')
chk(102399.9,6,[],true, fun, '99.9999 Ki')
chk(102399.9,7,[],true, fun, '99.99990 Ki')
chk(102399.9,8,[],true, fun, '99.999902 Ki')
chk(102399.9,9,[],true, fun, '99.9999023 Ki')
chk(1023999, 1,[],true, fun, '1 Mi')
chk(1023999, 2,[],true, fun, '1000 Ki')
chk(1023999, 3,[],true, fun, '1000 Ki')
chk(1023999, 4,[],true, fun, '1000 Ki')
chk(1023999, 5,[],true, fun, '1000.0 Ki')
chk(1023999, 6,[],true, fun, '999.999 Ki')
chk(1023999, 7,[],true, fun, '999.9990 Ki')
chk(1023999, 8,[],true, fun, '999.99902 Ki')
chk(1023999, 9,[],true, fun, '999.999023 Ki')
chk(pow2(20)-1,1,[],true, fun, '1 Mi')
chk(pow2(20)-1,2,[],true, fun, '1.0 Mi')
chk(pow2(20)-1,3,[],true, fun, '1.00 Mi')
chk(pow2(20)-1,4,[],true, fun, '1.000 Mi')
chk(pow2(20)-1,5,[],true, fun, '1.0000 Mi')
chk(pow2(20)-1,6,[],true, fun, '0.999999 Mi')
chk(pow2(20)-1,7,[],true, fun, '1023.999 Ki')
chk(pow2(20)-1,8,[],true, fun, '1023.9990 Ki')
chk(pow2(20)-1,9,[],true, fun, '1023.99902 Ki')
%
%% One Less Than %%
%
% 1024^2 == pow2(20)
chk(pow2(1e0,20)-1,1, fun, '1 Mi')
chk(pow2(1e0,20)-1,2, fun, '1 Mi')
chk(pow2(1e0,20)-1,3, fun, '1 Mi')
chk(pow2(1e0,20)-1,4, fun, '1 Mi')
chk(pow2(1e0,20)-1,5, fun, '1 Mi')
chk(pow2(1e0,20)-1,6, fun, '0.999999 Mi')
chk(pow2(1e0,20)-1,7, fun, '1023.999 Ki')
chk(pow2(1e0,20)-1,8, fun, '1023.999 Ki')
chk(pow2(1e0,20)-1,9, fun, '1023.99902 Ki')
chk(pow2(1e1,20)-1,1, fun, '10 Mi')
chk(pow2(1e1,20)-1,2, fun, '10 Mi')
chk(pow2(1e1,20)-1,3, fun, '10 Mi')
chk(pow2(1e1,20)-1,4, fun, '10 Mi')
chk(pow2(1e1,20)-1,5, fun, '10 Mi')
chk(pow2(1e1,20)-1,6, fun, '10 Mi')
chk(pow2(1e1,20)-1,7, fun, '9.999999 Mi')
chk(pow2(1e1,20)-1,8, fun, '9.999999 Mi')
chk(pow2(1e1,20)-1,9, fun, '9.99999905 Mi')
chk(pow2(1e2,20)-1,1, fun, '100 Mi')
chk(pow2(1e2,20)-1,2, fun, '100 Mi')
chk(pow2(1e2,20)-1,3, fun, '100 Mi')
chk(pow2(1e2,20)-1,4, fun, '100 Mi')
chk(pow2(1e2,20)-1,5, fun, '100 Mi')
chk(pow2(1e2,20)-1,6, fun, '100 Mi')
chk(pow2(1e2,20)-1,7, fun, '100 Mi')
chk(pow2(1e2,20)-1,8, fun, '99.999999 Mi')
chk(pow2(1e2,20)-1,9, fun, '99.999999 Mi')
chk(pow2(1e3,20)-1,1, fun, '1 Gi')
chk(pow2(1e3,20)-1,2, fun, '1000 Mi')
chk(pow2(1e3,20)-1,3, fun, '1000 Mi')
chk(pow2(1e3,20)-1,4, fun, '1000 Mi')
chk(pow2(1e3,20)-1,5, fun, '1000 Mi')
chk(pow2(1e3,20)-1,6, fun, '1000 Mi')
chk(pow2(1e3,20)-1,7, fun, '1000 Mi')
chk(pow2(1e3,20)-1,8, fun, '1000 Mi')
chk(pow2(1e3,20)-1,9, fun, '999.999999 Mi')
% 1024^3 == pow2(30)
chk(pow2(1e0,30)-1,1, fun, '1 Gi')
chk(pow2(1e0,30)-1,2, fun, '1 Gi')
chk(pow2(1e0,30)-1,3, fun, '1 Gi')
chk(pow2(1e0,30)-1,4, fun, '1 Gi')
chk(pow2(1e0,30)-1,5, fun, '1 Gi')
chk(pow2(1e0,30)-1,6, fun, '1 Gi')
chk(pow2(1e0,30)-1,7, fun, '1 Gi')
chk(pow2(1e0,30)-1,8, fun, '1 Gi')
chk(pow2(1e0,30)-1,9, fun, '0.999999999 Gi')
chk(pow2(1e1,30)-1, 1, fun, '10 Gi')
chk(pow2(1e1,30)-1, 2, fun, '10 Gi')
chk(pow2(1e1,30)-1, 3, fun, '10 Gi')
chk(pow2(1e1,30)-1, 4, fun, '10 Gi')
chk(pow2(1e1,30)-1, 5, fun, '10 Gi')
chk(pow2(1e1,30)-1, 6, fun, '10 Gi')
chk(pow2(1e1,30)-1, 7, fun, '10 Gi')
chk(pow2(1e1,30)-1, 8, fun, '10 Gi')
chk(pow2(1e1,30)-1, 9, fun, '10 Gi')
chk(pow2(1e1,30)-1,10, fun, '9.999999999 Gi')
%
%% Negative %%
chk(-1,     fun, '-1 ')
chk(-999,   fun, '-999 ')
chk(-999,1, fun, '-1 Ki')
chk(-999,2, fun, '-1000 ')
chk(-1000,     6, fun, '-1000 ')
chk(-1023,     6, fun, '-1023 ')
chk(-1023.9,   6, fun, '-1023.9 ')
chk(-1023.99,  6, fun, '-1023.99 ')
chk(-1023.999, 6, fun, '-0.999999 Ki')
chk(-1023.9999,6, fun, '-1 Ki')
chk(-1024,     6, fun, '-1 Ki')
%
%% Significant Figures %%
%
% All Prefixes:
chk(pow2(00), fun, '1 ')
chk(pow2(10), fun, '1 Ki')
chk(pow2(20), fun, '1 Mi')
chk(pow2(30), fun, '1 Gi')
chk(pow2(40), fun, '1 Ti')
chk(pow2(50), fun, '1 Pi')
chk(pow2(60), fun, '1 Ei')
chk(pow2(70), fun, '1 Zi')
chk(pow2(80), fun, '1 Yi')
% Fixed Prefix:
chk(1023,1,'Ki',true, fun, '1 Ki' )
chk(1023,2,'Ki',true, fun, '1.0 Ki')
chk(1023,3,'Ki',true, fun, '0.999 Ki')
chk(1023,4,'Ki',true, fun, '0.9990 Ki')
chk(1023,5,'Ki',true, fun, '0.99902 Ki')
chk(1023,6,'Ki',true, fun, '0.999023 Ki')
chk(1023,7,'Ki',true, fun, '0.9990234 Ki')
chk(1023,8,'Ki',true, fun, '0.99902344 Ki')
chk(1023,9,'Ki',true, fun, '0.999023438 Ki')
%
%% https://physics.nist.gov/cuu/Units/binary.html %%
%
chk(1024,       fun, '1 Ki')
chk(1048576,    fun, '1 Mi')
chk(1073741824, fun, '1 Gi')
%
%% http://wolfprojects.altervista.org/articles/binary-and-decimal-prefixes/ %%
%
chk(29131, 3, fun, '28.4 Ki')
chk(20971520, fun, '20 Mi')
%
%% https://en.wikipedia.org/wiki/Binary_prefix %%
%
chk(536870912,    fun, '512 Mi')
chk(500e9,     3, fun, '466 Gi')
chk(18613795,  3, fun, '17.8 Mi') % source: 17.7
chk(45708,     3, fun, '44.6 Ki')
chk(16e3,      3, fun, '15.6 Ki')
chk(125000,    3, fun, '122 Ki')
chk(125000000, 3, fun, '119 Mi')
chk(56000/8,   2, fun, '6.8 Ki')
chk(3200000000,2,false,true, fun, '3.0 Gi')
%
%% Display Results %%
%
chk()
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%num2bip_test