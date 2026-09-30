return (function(...)
	local o, e, O = table, string, bit
	local d, c, t, M, s, r, P, Z, N, f, n = e.byte, e.char, e.sub, o.concat, o.insert, math.ldexp, getfenv and getfenv() or _ENV, setmetatable, select, unpack or o.unpack, tonumber;
	local h = (function(i)
		local e, h, l, n, d, a, f = 1, function(l)
			local e = ""
			for n = 1, # l, 1 do
				e = e .. c(d(l, n) - (7))
			end
			return n(e, 36)
		end, "", "", {}, 256, {}
		for e = 0, a - 1 do
			f[e] = c(e)
		end;
		local function s()
			local l = h(t(i, e, e))
			e = e + 1;
			local n = h(t(i, e, e + l - 1))
			e = e + l;
			return n
		end;
		l = c(s())
		d[1] = l;
		while e < # i do
			local e = s()
			if f[e] then
				n = f[e]
			else
				n = l .. t(l, 1, 1)
			end;
			f[a] = l .. t(n, 1, 1)
			d[# d + 1], l, a = n, n, a + 1
		end;
		return o.concat(d)
	end)("99Z9>;9>;99W9><99\\9979><9>I99Z98999Z99[9>J99Z8N9>O9>;9=@9>R99Z8R9><9>N9>;9>Y99Z9:;9><99]9>>9>;8N8<8=8?8899]99X9><8U8N8T8K8H8:99]99]9><8=8K8N99]99V9?N8[8N9?;9?S9>;8>8J8<8T9?L9?>8O8=9?<9><8>8I8H8>8<9?Q9?=9>;9?I8U888T9?Q9?X99Z8@9@=8J9>_9><8?87888Z8R99]99Y9><8:888N89888H8P9?R9><98U8_98=98L99]99^9?>9@]8@9@]9@=9?89?:9@79>;9@I9?:8>9@>9><8O8H8R8<8>8M99]9:79><8N9@:8O8@8=9@J99]8M9><99S99T98H9I<98;99S99P99N9I?9I<98O9IH99O99R98?99R99Q99R98O99R98P99R9I@99P99P9IN99R98N99R98S99R98J9Ia99R98Q9IK99T98N9IN99S99S98T9I<98I9J>99T98<9IH98L9I<98=9IK99P98X9IH99U9IH98W9J>99P9JV9JS9J;98>9IH8;9JY99O9>R9;;99Q9H89>;8=8Z8I8T9>O9=J98T98799Z879><9:H8K9>M9KQ9>;9:H9>;99\\99Z9KV9KS9>;9?M9?M9>;98^9>;9?S9KV9?S9K^99Z9>>9KV9>>9L89?=9KV9?=9L89@Z9>N9@Z9L89H\\9>N9H\\9KT99Z9:89LQ9><9L89LR9LR9:999Z9LP9LX9::9><9@?9LX99`9KQ9>N99V98U9><9L`9M79M99KY9>N9:H9@Z9L[9>I8<99Z9LX9>N9L?98>9ML99Z9:I9La99Z9M89><9MS9M?9MH99Z9H?9KS9@Z9L\\99_9KN9@Z9H?9L`9M]99Z9M`99a9L]9MP9M`9:O9MT9MV9>;9NH9>N98^8W9N;9KQ9N=9M@99Z9L`9:?9L]9=[99Z9N=9>Z9L99>;99M9><9>`9N]9><9@M99Z9N^9>;9N99Na9>;9@?9O=9KR9LY9=T99Z9NV9:@9>I8Q9NY9KW9OQ9:H9OJ9NV9LP99Z99X9:<99Z9?M99<9OH9NJ99Z9O\\9NM9NO9OM9?M9MS9OX99Z9OM9O`9O79M=9O_9KQ9O^99=9KQ9>@9P<9OH9OS9LY9>\\9>?9>H9MS9KX9OW9NX9>]9?M9>N9>`9O:9MU9>I9P]9NZ9O@9NV9><9P]9OM9Q99KN9NW99Z9OY9?S9P[9O@9Q;9O@9O89P`9P_9><9Q89O@9OV99X9NX9:=9N\\9QI9O99O79QO9>;9Pa9QY9>;9QQ9Q^9PN9Q<9KY9O>9NX9:>9OW9KQ9K\\9P]9>]9R89MR9Q[9LS9?>99Z9:N9PR9R:99Z9NH9LI99Z9H\\9Qa9RH9O@9O?9Qa9Q]9P]9Q`9P]9N`9Qa9QK9Qa9QM9><9@Z9RM9:P9RP9PW99Z9:Q9RU9MT9Qa9M\\9S?9:J9LS9LJ9O@9RX9Qa9OY9RI9R<9RI9NH9RI9MS9RI9QV9RI9SN9RQ9:K9MQ9MN9O@9SH9RI9SL99Z9=O99Z9:L99Z9S`9>J9:M99Z9S^9>I9TJ9T79LT9>U98_9MQ9>J9T?9TR9PV99Z9TJ9>R9T?9TZ9>U9N[9>;9L\\9>=9T]99Z9K99K\\9T]8R9KK9>U9HN99Z9@99@;9@=99[8`9KN9OJ9>N9>[9QT9OQ9N[9K\\98L9>U9UU9T^9>;9UW9UR9LY99N9OZ9U[9LP9K`9>O9R`9PQ9R=9U:9S:9>J9LP9H\\9@M9LU9R=9M?9>;9MM9QZ9SI9MX9NK9M[9>O8U9NP9T`9>;9OO9H?9KV9KX9I:9M^9VQ99V9KV9H\\9M;9S?9LM9PI9O@9TW9UZ9V;9P]9>J9P]9>[99Z8V9RL9>O9LX9RV9>I9VL9>J9LR9KU9>I9?M9WR9OK9Ta9>N9K\\9K^9WV9O>99P9KQ9KK9>N9LR9O^9W`9HO9LS9WN99Z9MK9LR9TO8H9MQ9@Z9LR99X9MP9LX98]9NI9P@9XO9M<9><9P>99Z9XH9?S9XJ9MU9P@99J9KR9VS9LX9V;8S99Z9L\\9V;9>;9H?9U:9LP9M`9>[9LP9Va9>J9L\\9L`9TW9?S9MI99Z9X^9U^9><9Xa9Y89>O9H?9@M9Y=9PO9O;9OH9><9YJ9U[9MQ9YN99?99Z9@Z9?=9LX9><9LX9N`9L89LX9WP9T_9P^9>J9YV9TP9R=9?=9WH9?M9T;9Ta9MI9O89T?9>Y9NH9X79LT9RO9LV9N\\9Z;9Z\\9>I9LW9>O9W\\9>O9>[9PV9@M9Y99>O9K99>R9:J9U=9>J98998799[9ST9LY99K9SJ9V99VY9>O9Y99U`9U[9?X9KV9N=9>Y9VS9ZN9>I98;9Z79>U9W89WQ9>U9Z<9>O9H\\9LX9KV9LL9SI9V;9@Z9[R9>X9R=9@Z9V^9OQ9>>9ZV9OQ9TW9=L9U^9Y?9K_9ZI9>I9Ka9>O9TW9[89>R9WH9[=99Q9RN9>I8_9U79UO9\\Z9Y^9KZ9YQ9>I9?S9[<9M79U79TW9WY9ZL9]:9WH9]L9>J9\\^9>?9Y[9]=9\\[9P^9[<9>>9]X9Z^9L89>>9\\O9\\X9Z^9\\J9WS9]S9[<9\\I9]_9]H9]<9]a9>J9[<9>I9[>9U79>O98799\\98[9UM9OQ9Y?9OJ9?M9PV99`98Q9\\N9O]9P@9]^9O^9>]9>N99`9999OQ9^\\9PI9P@9^a98^9S`9[;99Z9_:9QW9U^99X8X9P^9H?9QI9O^9_K9>;9=?9U^9^S9>;9=Q9R=9\\V98^99:9ZM9]>9[_9QI9LH9[_9?M9L89[R9V;9SP9>R9O?9O89KV9>N99X8;9><9R<9]:9O^9`H9XZ9><9RO9[Z9^>9^^9OQ98a9^X9><9`S9NM9_;9>^9NT9^_9KV9ZU9P^9O^9`]99Z9_P9K[9UR9_T9N`9L79LR9]]9U^98^8O9\\Q9YQ9VS9Ta9K_9P@9`N9>;98I9U^9TW9>W9UX9WT9U79^I9^K9T]99]9T[9OW9MP9KV9PZ9_79`Y9XS9Q_9KQ98^9X\\9a`9>N9:?9>:9aR9_Z9U:9__9\\V9`<9_=9WX9Y[9?S9?S9L<9\\V9QH9WW9P^9\\Y9`Y9?M9L79\\V9a`9QZ:87Z9]?9[V9>I9S`9NM:87<9MT9:?9PY9OQ9K\\9_P9]@9YQ9=N9\\W9?S99X9KK9?M9`K:87Q9P@:88P9P@9SH9M?9OJ:87U9O>9Q@9S@9`T9>;:88U9`L9>;9SN:88V9]W9>I9aQ9Ua9><9aT9]T9aL9[`9[H9>I9:?:89H:89<9889K8:89K9>;9U<99Z9^N9><99R9]9:89>9^:9`Y9PV9L89a89]R9a8:87^9V79>U9?=9O89\\V9L>9>I9]Y9>O9[\\9>J9\\L:89`9\\H9>I9?=9[<:8:I9>J9V?:8:=9SI9TW9@Z9[<9H\\9[<9ZX:8:?9LS9TW9?M9S;9]_9RZ9N[9V89VM:87`:89Z:87T9Y^:89;:87N:898:87K9N\\:87X:8;9:87S9_?9R`:87Q9]`:8;L9>J:8;;9]Q9\\]9aW9\\`9M`9L]:89V9]R:89X9]=9[<:88H:8;Q:8;P:8;@9>J:89X9]P:8;<9]N9>I:8<7:8;`9>U9]R9^=9>J:89O9>V9KK9SV9>;:89M9T]9]::8<<9]V9_R9K]:8;Z:89>:87]9WS9[<9^@9`^9];:8;P:89^:87`9]R9>>:8:89U^9L::8<:9_Z9]_:8<P9ZL9[R9WH9^:9_`9PL9]_9]V:8;Y9^>9>I9VU9K89\\`9>O99?:8<H9;;:8<M9>J99@:8<H99Q:8<H987:8=T9=:9^J9>I9;?9=a:89O9;J9=Q:8<H99J98:99Z99@9>I9=X:8=_9TO9aU:8=99T79LP:87M9^?:89>:88X9V99]^9R9:8:::8>P:8:::89[9_Q9aV:8;[:89>:8>T9V9:8:79Q=9[_:8:`9XX9Y^:8>^:8;V9\\U9[_:8:^9N\\:8:I9Q89>>9@Z9>>98\\9_V9KQ9V?9P@9K^9>N98\\99I9U^:8889SI9O^:8?W9a@9R=9>>9RV9aQ:8>V:88_99Z9>H:897:8>R9PP9V_9P?9><:8@899Z98\\98W9P^9`V9LS9O^:8@K9O^:8@?:8?T9U^9P>:8?P9XT9KQ99J9=K9VI9SI99Z8L:8?\\9ZM9MP9?=99>9XP9><:8@a9>N:8@W9R=9H\\9RV:8@\\9?=9>>9@?:8?_9Y^9NH:8?`99Z98H:8?79ZL:8:O9Z:9O>:8:Q:8;<:8:S9Y79>I:8:I:8:\\9_Y:8H[:8HM:8=99>O:8<a9[S9^J9aX9><9KI9[K9989L]9[M:8<V9O^9a`9O^9WP9NH9]V9MK:87M9KX9aK9U[:8@Q9VK:8H7:8IT:897:89X9aQ:89X:8IL9Y[9=W:87H:8;O:8=:9N\\9]Z9Z=9Ta:8:<9]S:8=89\\J:8=K:8I`:8=L9a_9];9>I9LP:8<]9QZ:8?=:8J:9ZI9?M99;9KR9RS9\\W9N\\9H\\:8:`9XK9WL:89>9L\\9]R9H?:8??9M`:8??9LX:8;U9Z_9]S9LZ:8JU9>;9\\;9>O:8:\\9TW9L?9[_9\\M9?M9S=9\\P:8:[9>I9VS:8;P9=J9U^9O89>T9[<:89=:8<>9>[99]9>[9`S9W\\:8>=9]R9>L9]V:8>?9>[9\\P9\\[9:H:89\\:8H`9>U9]V:8>K:8;Q:8K?:8;S9>R9:7:8<H9U7:8<H:89J9>R9:N:8=T9KK9=`9>I98<:89V9>R:8L@:8KT:8L>9>R:8?;:8HT:8??:8:M9aV9RT9RR:8K<99Z98M9P^:8>J9]`:8>_:89>:8:@9R99[a9ZI:8@`:8JS9Sa:89I:8MP9L\\:8@H9MQ9OY9T79O^:8MV:8?a:8?W:8M:9_N9><9MK9_N9KV:8MT9H?:8KM:8KT9P@:8N99O^:88^99Z9QV:8=O9?Y:8HX9>[9O^9P>:8MT9LX:8?R9aa:8<S:87899Z98Z:8MO9VX9MJ9VQ9TO9VS9L\\9SL:8NL9KQ:8@Q9LX9P>:87Z9P@9XU9NH9Y;:8NX:8M`9X::8N\\9>I9I:9>>9LR9L\\9\\M9?=9NV9\\P:8:>9>;9UL9[\\9KV9Q89_R9?=9LP:8OQ9V<9>R9RT9KV9V>9O]:8HT9=\\:8MO9Z@99Z9>7:8MP9TW:8OL9YU9TS9V99Y>:8>a9YH:8=N9NT9OQ:8?M:8HX9K79]L9O^:8PQ:8?a9NX9\\P:8P>9><99T9VQ:8HS9YX9YW9YZ9]V9Y]9TW9ZK9>J9M`:8P\\9YZ9N`9LP9N=:8??9H?9N=9TW9M`:8<a9L`:8:`9Va9TW9N=:8:`9[Y9Y^9OL9>O9M`9OM:8?S:8@I9L\\98O9R>:8?a:8Q\\:8NS98V:8MO:8QM9>I8Y:8PM9T79Q89M`9KV9O<:8PM:8QN:8=I:8R=9N\\9L`9O89>W:8QY:8HX98Y:8IU99Z:8RR:8NS9M99\\P:8R@9>;9MK:8QO9OK9O\\:8R>:8PM9O^:8RO:8@@:8?U9L\\899W99O^:8S;:8RX9>O:8R[:8=I:87;:8PM9L`9@Z9:?:8R^9OQ:8RM9P@:8S7:8MT9L\\9KP:8MW9P@:8SV:8?a:8S7:8M::8RY:8@@:8R;9OQ9L89L`:8SL:87V:8R_:8R@:8R89>J:8R\\:8RK9>>9N99NH:8RM9>I8]9OP9SL9LP:8OO:8>a:8QX9>O9L`9OM:8Ma9YZ8Z:8RS:8TX:8NS:8TL9Oa:8PM:8QK9>;9XH:8R89NU:8SO9?S:8TH:8R`:8TK:8TM:8>a9NV:8P^9PN:8QL9PN:8TV:8PM9=M:8RS:8UN:8NS9=H:87:9NO9L`:8R_9XV:8RH:8PM:8SN9NP:8R?9VP:8TJ9M::8U>9R99NV9PV9LP:8TU:8TS:8UK:8S^:8PM9=Z:8RS:8V?:8T]:8UU9Z\\:8Ta:8RL:8R]9NP:8T@9>;9I:9>;9LR:8QK:8KI9N^:897:8OZ:8JT9>J9MK:8O]9OI9SI:8NK98@9R=9=^:87:9X\\9LX9X?9VP9L\\9RZ9MK:8J\\9UR9I:9>N9ZS:8KI9=Y9KR9aQ:8<R:89P:8=M9`Y9T]:8I99>I:8<H:8LM9H>9LT9NO9U::8T]9@M9\\=9NO9N`9?M9UQ9O?9`=9O@9W=:8:a9Qa9R`9UZ9>J9UZ9WH9P]9TW:8HJ9aS9^>9>[9[79>J:8WV9>;9;;9=::8K[9`U:8=_9>I:8LM9>U:8<H9:;:8LP:8<H:8LS99Z98S9>I:8PT:8LZ:8<U9^=:8;\\:8>S9YY9R=9]V:8H[:8X[9>U:8XR:8K=9]a9ZW9\\W:8K;9[<:8NH9><9WV9\\=:8VS9SO9WO9>U:8NH9LP:8Q89>I9M`9WV9Y@:8O`9VQ9TR9`=:88N9\\a9>N9N=9O^9aO:8?Y9KR9_T9NV9N=9__:8P79OM:8QS:8UW9OM9H\\9Q;9V[9WW9OM9O^:8NP98^:8P7:8ZM9KR9XH9NV9H\\9Q89I:9L\\9N=:8U@9KV9H?:8MY99Z9_T9H?9LR:8ZO9VQ:8M]:8I=9M`:8R@9XH:8PI9L<:8UT9NP:8?S9V`99Z8^9KQ:8<`9P@:8[Y:8?S98R:8PM:8H9:8NQ99Z:8[a9O^99H:8N_:8@I9L`9^_9]I9O^:8\\?:8?a9X\\9>Y:8KX:8@=9>;98X:8US9OP:8J`9>;9KM9NV:8[::8;<:8ZQ9Y[9OM9L\\9S7:8V79W99><:8\\P:8?S:8?U9L`9W^:8X;9O^:8]:9_=9NO9N=:8\\S99Z9=V9WW:8J89PN9M`9R`9NV:8QU9Y\\9OP:8U@9>I:8\\a:8]>:8\\R9_U:8]J9NV:8]L9OM:8]N:8MQ:8]Q9ZH:8[;:8JU:8]V98\\:8[_9L`8a9KQ9\\L9P@:8^=:8NS9^V:8]7:8PM:8LX9LN:8?a:8^M:8]W:8]@9R=9NN9WW:8]^99Z:8[9:8]S:8?a:8]V:8^T:8^R9@?:8\\U:8HX9N=9L8:8\\Y9WH:8\\[9R7:879:87M9O8:8^9:8]899Z:8@I9Wa:8?a:8_I:8^Q9NP9L@9NO9NV:8^V:8^X:8^79O^:8]V9>V9^>:8Z\\9N\\9^Z9P@:8NU:8\\L:8WS9>;");
	local e, o, l, n = 1, O and O.bxor or function(e, l)
		local n, o = 1, 0
		while e > 0 and l > 0 do
			local d, t = e % 2, l % 2
			if d ~= t then
				o = o + n
			end
			e, l, n = (e - d) / 2, (l - t) / 2, n * 2
		end
		if e < l then
			e = l
		end
		while e > 0 do
			local l = e % 2
			if l > 0 then
				o = o + n
			end
			e, n = (e - l) / 2, n * 2
		end
		return o
	end, 100, function(n, e, l)
		if l then
			local e = (n / 2 ^ (e - 1)) % 2 ^ ((l - 1) - (e - 1) + 1);
			return e - e % 1;
		else
			local e = 2 ^ (e - 1);
			return (n % (e + e) >= e) and 1 or 0;
		end;
	end
	local l, i, a = function()
		local f, t, n, d = d(h, e, e + 3);
		f, t, n, d = o(f, l), o(t, l), o(n, l), o(d, l)
		e = e + 4;
		return (d * 16777216) + (n * 65536) + (t * 256) + f;
	end, function()
		local l = o(d(h, e, e), l);
		e = e + 1;
		return l;
	end, function()
		local t, n = d(h, e, e + 2);
		t, n = o(t, l), o(n, l)
		e = e + 2;
		return (n * 256) + t;
	end;
	local function O()
		local o = l();
		local e = l();
		local t = 1;
		local o = (n(e, 1, 20) * (2 ^ 32)) + o;
		local l = n(e, 21, 31);
		local e = ((- 1) ^ n(e, 32));
		if (l == 0) then
			if (o == 0) then
				return e * 0;
			else
				l = 1;
				t = 0;
			end;
		elseif (l == 2047) then
			return (o == 0) and (e * (1 / 0)) or (e * (0 / 0));
		end;
		return r(e, l - 1023) * (t + (o / (2 ^ 52)));
	end;
	local e, o = l, function(n)
		local f;
		if (not n) then
			n = l();
			if (n == 0) then
				return '';
			end;
		end;
		f = t(h, e, e + n - 1);
		e = e + n;
		local l = {}
		for e = 1, # f do
			l[e] = c(o(d(t(f, e, e)), 100))
		end
		return M(l);
	end;
	local e, c = l, function(...)
		return {
			...
		}, N('#', ...)
	end
	local function R()
		local h, f, e = {}, {}, {};
		local s = {
			h,
			f,
			nil,
			e
		};
		local e, t = l(), {}
		for n = 1, e do
			local l, e = i();
			if (l == 2) then
				e = (i() ~= 0);
			elseif (l == 0) then
				e = O();
			elseif (l == 3) then
				e = o();
			end;
			t[n] = e;
		end;
		s[3] = i();
		for f = 1, l() do
			local e = i();
			if (n(e, 1, 1) == 0) then
				local o, d, e = n(e, 2, 3), n(e, 4, 6), {
					a(),
					a(),
					nil,
					nil
				};
				if (o == 0) then
					e[3] = a();
					e[4] = a();
				elseif (o == 1) then
					e[3] = l();
				elseif (o == 2) then
					e[3] = l() - (2 ^ 16)
				elseif (o == 3) then
					e[3] = l() - (2 ^ 16)
					e[4] = a();
				end;
				if (n(d, 1, 1) == 1) then
					e[2] = t[e[2]]
				end
				if (n(d, 2, 2) == 1) then
					e[3] = t[e[3]]
				end
				if (n(d, 3, 3) == 1) then
					e[4] = t[e[4]]
				end
				h[f] = e;
			end
		end;
		for e = 1, l() do
			f[e - 1] = R();
		end;
		return s;
	end;
	local function O(e, d, h)
		local l, e, n = e[1], e[2], e[3];
		return function(...)
			local o, M, t, i, l, a, c, N, L, r, n = l, e, n, c, 1, - 1, {}, {
				...
			}, N('#', ...) - 1, {}, {};
			for e = 0, L do
				if (e >= t) then
					c[e - t] = N[e + 1];
				else
					n[e] = N[e + 1];
				end;
			end;
			local N = L - t + 1
			local e;
			local t;
			while true do
				e = o[l];
				t = e[1];
				if t <= 78 then
					if t <= 38 then
						if t <= 18 then
							if t <= 8 then
								if t <= 3 then
									if t <= 1 then
										if t > 0 then
											local e = e[2]
											local o, l = i(n[e](f(n, e + 1, a)))
											a = l + e - 1
											local l = 0;
											for e = e, a do
												l = l + 1;
												n[e] = o[l];
											end;
										else
											local i;
											local d;
											local h;
											local t;
											n[e[2]] = e[3];
											l = l + 1;
											e = o[l];
											t = e[2];
											a = t + N - 1;
											for e = t, a do
												h = c[e - t];
												n[e] = h;
											end;
											l = l + 1;
											e = o[l];
											t = e[2]
											n[t] = n[t](f(n, t + 1, a))
											l = l + 1;
											e = o[l];
											n[e[2]] = n[e[3]] - e[4];
											l = l + 1;
											e = o[l];
											n[e[2]] = {};
											l = l + 1;
											e = o[l];
											n[e[2]] = {};
											l = l + 1;
											e = o[l];
											n[e[2]] = e[3];
											l = l + 1;
											e = o[l];
											n[e[2]] = n[e[3]];
											l = l + 1;
											e = o[l];
											n[e[2]] = e[3];
											l = l + 1;
											e = o[l];
											t = e[2];
											d = n[t]
											i = n[t + 2];
											if (i > 0) then
												if (d > n[t + 1]) then
													l = e[3];
												else
													n[t + 3] = d;
												end
											elseif (d < n[t + 1]) then
												l = e[3];
											else
												n[t + 3] = d;
											end
										end;
									elseif t == 2 then
										local o = e[2];
										local d = n[o + 2];
										local t = n[o] + d;
										n[o] = t;
										if (d > 0) then
											if (t <= n[o + 1]) then
												l = e[3];
												n[o + 3] = t;
											end
										elseif (t >= n[o + 1]) then
											l = e[3];
											n[o + 3] = t;
										end
									else
										local d;
										local s, h;
										local O;
										local t;
										n[e[2]] = e[3];
										l = l + 1;
										e = o[l];
										t = e[2];
										a = t + N - 1;
										for e = t, a do
											O = c[e - t];
											n[e] = O;
										end;
										l = l + 1;
										e = o[l];
										t = e[2]
										s, h = i(n[t](f(n, t + 1, a)))
										a = h + t - 1
										d = 0;
										for e = t, a do
											d = d + 1;
											n[e] = s[d];
										end;
										l = l + 1;
										e = o[l];
										t = e[2];
										do
											return f(n, t, a)
										end;
										l = l + 1;
										e = o[l];
										do
											return
										end;
									end;
								elseif t <= 5 then
									if t > 4 then
										local h;
										local c, s;
										local t;
										n[e[2]] = d[e[3]];
										l = l + 1;
										e = o[l];
										n[e[2]] = d[e[3]];
										l = l + 1;
										e = o[l];
										n[e[2]] = d[e[3]];
										l = l + 1;
										e = o[l];
										n[e[2]] = n[e[3]];
										l = l + 1;
										e = o[l];
										n[e[2]] = n[e[3]];
										l = l + 1;
										e = o[l];
										n[e[2]] = n[e[3]];
										l = l + 1;
										e = o[l];
										t = e[2]
										c, s = i(n[t](f(n, t + 1, e[3])))
										a = s + t - 1
										h = 0;
										for e = t, a do
											h = h + 1;
											n[e] = c[h];
										end;
										l = l + 1;
										e = o[l];
										t = e[2]
										n[t] = n[t](f(n, t + 1, a))
										l = l + 1;
										e = o[l];
										n[e[2]] = e[3];
										l = l + 1;
										e = o[l];
										t = e[2]
										c, s = i(n[t](f(n, t + 1, e[3])))
										a = s + t - 1
										h = 0;
										for e = t, a do
											h = h + 1;
											n[e] = c[h];
										end;
										l = l + 1;
										e = o[l];
										t = e[2]
										n[t] = n[t](f(n, t + 1, a))
										l = l + 1;
										e = o[l];
										n[e[2]][n[e[3]]] = n[e[4]];
									else
										local e = e[2]
										n[e] = n[e](f(n, e + 1, a))
									end;
								elseif t <= 6 then
									local t;
									n[e[2]] = d[e[3]];
									l = l + 1;
									e = o[l];
									n[e[2]] = d[e[3]];
									l = l + 1;
									e = o[l];
									n[e[2]] = d[e[3]];
									l = l + 1;
									e = o[l];
									n[e[2]] = d[e[3]];
									l = l + 1;
									e = o[l];
									n[e[2]] = d[e[3]];
									l = l + 1;
									e = o[l];
									t = e[2]
									n[t] = n[t](f(n, t + 1, e[3]))
									l = l + 1;
									e = o[l];
									n[e[2]] = d[e[3]];
									l = l + 1;
									e = o[l];
									t = e[2]
									n[t] = n[t](f(n, t + 1, e[3]))
									l = l + 1;
									e = o[l];
									n[e[2]] = d[e[3]];
									l = l + 1;
									e = o[l];
									n[e[2]] = n[e[3]] + e[4];
									l = l + 1;
									e = o[l];
									d[e[3]] = n[e[2]];
									l = l + 1;
									e = o[l];
									do
										return n[e[2]]
									end
									l = l + 1;
									e = o[l];
									do
										return
									end;
								elseif t == 7 then
									n[e[2]] = h[e[3]];
								else
									if (n[e[2]] <= e[4]) then
										l = l + 1;
									else
										l = e[3];
									end;
								end;
							elseif t <= 13 then
								if t <= 10 then
									if t == 9 then
										n[e[2]] = n[e[3]] / e[4];
									else
										local t;
										n[e[2]] = n[e[3]];
										l = l + 1;
										e = o[l];
										n[e[2]] = e[3];
										l = l + 1;
										e = o[l];
										n[e[2]] = e[3];
										l = l + 1;
										e = o[l];
										t = e[2]
										n[t] = n[t](f(n, t + 1, e[3]))
										l = l + 1;
										e = o[l];
										if (n[e[2]] ~= e[4]) then
											l = l + 1;
										else
											l = e[3];
										end;
									end;
								elseif t <= 11 then
									do
										return n[e[2]]
									end
								elseif t > 12 then
									local l = e[2];
									local o = n[l];
									for e = l + 1, e[3] do
										s(o, n[e])
									end;
								else
									local e = e[2]
									local o, l = i(n[e](f(n, e + 1, a)))
									a = l + e - 1
									local l = 0;
									for e = e, a do
										l = l + 1;
										n[e] = o[l];
									end;
								end;
							elseif t <= 15 then
								if t == 14 then
									local t;
									n[e[2]] = n[e[3]];
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									t = e[2]
									n[t] = n[t](f(n, t + 1, e[3]))
									l = l + 1;
									e = o[l];
									if (n[e[2]] == e[4]) then
										l = l + 1;
									else
										l = e[3];
									end;
								else
									n[e[2]] = n[e[3]] / n[e[4]];
								end;
							elseif t <= 16 then
								local l = e[2]
								local o = {
									n[l]()
								};
								local t = e[4];
								local e = 0;
								for l = l, t do
									e = e + 1;
									n[l] = o[e];
								end
							elseif t == 17 then
								local o = e[2]
								local t, l = {
									n[o](f(n, o + 1, e[3]))
								}, 0;
								for e = o, e[4] do
									l = l + 1;
									n[e] = t[l];
								end
							else
								if (n[e[2]] == e[4]) then
									l = l + 1;
								else
									l = e[3];
								end;
							end;
						elseif t <= 28 then
							if t <= 23 then
								if t <= 20 then
									if t == 19 then
										local e = e[2]
										n[e] = n[e](f(n, e + 1, a))
									else
										n[e[2]] = e[3] ^ n[e[4]];
									end;
								elseif t <= 21 then
									if n[e[2]] then
										l = l + 1;
									else
										l = e[3];
									end;
								elseif t > 22 then
									local o = e[3];
									local l = n[o]
									for e = o + 1, e[4] do
										l = l .. n[e];
									end;
									n[e[2]] = l;
								else
									n[e[2]] = (e[3] ~= 0);
									l = l + 1;
								end;
							elseif t <= 25 then
								if t == 24 then
									local t;
									n[e[2]] = n[e[3]][e[4]];
									l = l + 1;
									e = o[l];
									n[e[2]] = n[e[3]];
									l = l + 1;
									e = o[l];
									t = e[2];
									do
										return n[t](f(n, t + 1, e[3]))
									end;
									l = l + 1;
									e = o[l];
									t = e[2];
									do
										return f(n, t, a)
									end;
									l = l + 1;
									e = o[l];
									do
										return
									end;
								else
									n[e[2]] = d[e[3]];
								end;
							elseif t <= 26 then
								do
									return
								end;
							elseif t > 27 then
								n[e[2]] = {};
							else
								l = e[3];
							end;
						elseif t <= 33 then
							if t <= 30 then
								if t > 29 then
									n[e[2]] = O(M[e[3]], nil, h);
								else
									n[e[2]] = n[e[3]] % e[4];
								end;
							elseif t <= 31 then
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][n[e[4]]];
								l = l + 1;
								e = o[l];
								n[e[2]][n[e[3]]] = n[e[4]];
								l = l + 1;
								e = o[l];
								l = e[3];
							elseif t == 32 then
								n[e[2]] = # n[e[3]];
							else
								n[e[2]] = e[3] / e[4];
							end;
						elseif t <= 35 then
							if t == 34 then
								n[e[2]] = n[e[3]] + e[4];
							else
								local a;
								local i;
								local t;
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t](f(n, t + 1, e[3]))
								l = l + 1;
								e = o[l];
								i = e[3];
								a = n[i]
								for e = i + 1, e[4] do
									a = a .. n[e];
								end;
								n[e[2]] = a;
								l = l + 1;
								e = o[l];
								n[e[2]][n[e[3]]] = n[e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = # n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]][n[e[3]]] = n[e[4]];
								l = l + 1;
								e = o[l];
								l = e[3];
							end;
						elseif t <= 36 then
							local o = e[2]
							local t, l = {
								n[o](f(n, o + 1, e[3]))
							}, 0;
							for e = o, e[4] do
								l = l + 1;
								n[e] = t[l];
							end
						elseif t == 37 then
							if not n[e[2]] then
								l = l + 1;
							else
								l = e[3];
							end;
						else
							local t;
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] - e[4];
							l = l + 1;
							e = o[l];
							n[e[2]][e[3]] = n[e[4]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]][e[3]] = n[e[4]];
						end;
					elseif t <= 58 then
						if t <= 48 then
							if t <= 43 then
								if t <= 40 then
									if t > 39 then
										local o = e[3];
										local l = n[o]
										for e = o + 1, e[4] do
											l = l .. n[e];
										end;
										n[e[2]] = l;
									else
										n[e[2]] = # n[e[3]];
									end;
								elseif t <= 41 then
									n[e[2]][e[3]] = n[e[4]];
								elseif t == 42 then
									local l = e[2]
									local o = {
										n[l]()
									};
									local t = e[4];
									local e = 0;
									for l = l, t do
										e = e + 1;
										n[l] = o[e];
									end
								else
									n[e[2]] = n[e[3]] / n[e[4]];
								end;
							elseif t <= 45 then
								if t == 44 then
									n[e[2]] = O(M[e[3]], nil, h);
								else
									for e = e[2], e[3] do
										n[e] = nil;
									end;
								end;
							elseif t <= 46 then
								if (e[2] < n[e[4]]) then
									l = l + 1;
								else
									l = e[3];
								end;
							elseif t == 47 then
								n[e[2]] = n[e[3]] / e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] - n[e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] / e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] * e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								l = e[3];
							else
								n[e[2]] = n[e[3]] - e[4];
							end;
						elseif t <= 53 then
							if t <= 50 then
								if t > 49 then
									n[e[2]] = n[e[3]][e[4]];
								else
									local f;
									local d;
									local t;
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									n[e[2]] = # n[e[3]];
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									t = e[2];
									d = n[t]
									f = n[t + 2];
									if (f > 0) then
										if (d > n[t + 1]) then
											l = e[3];
										else
											n[t + 3] = d;
										end
									elseif (d < n[t + 1]) then
										l = e[3];
									else
										n[t + 3] = d;
									end
								end;
							elseif t <= 51 then
								n[e[2]] = n[e[3]];
							elseif t == 52 then
								n[e[2]][n[e[3]]] = n[e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = # n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]][n[e[3]]] = n[e[4]];
								l = l + 1;
								e = o[l];
								l = e[3];
							else
								local e = e[2];
								local l = n[e];
								for e = e + 1, a do
									s(l, n[e])
								end;
							end;
						elseif t <= 55 then
							if t > 54 then
								if (n[e[2]] == e[4]) then
									l = l + 1;
								else
									l = e[3];
								end;
							else
								local o = e[2];
								local t = n[o]
								local d = n[o + 2];
								if (d > 0) then
									if (t > n[o + 1]) then
										l = e[3];
									else
										n[o + 3] = t;
									end
								elseif (t < n[o + 1]) then
									l = e[3];
								else
									n[o + 3] = t;
								end
							end;
						elseif t <= 56 then
							local i, a;
							local t;
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + e[4];
							l = l + 1;
							e = o[l];
							t = e[2]
							i, a = {
								n[t](f(n, t + 1, e[3]))
							}, 0;
							for e = t, e[4] do
								a = a + 1;
								n[e] = i[a];
							end
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + e[4];
							l = l + 1;
							e = o[l];
							d[e[3]] = n[e[2]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] * e[4];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] * e[4];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + n[e[4]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] * e[4];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + n[e[4]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + n[e[4]];
							l = l + 1;
							e = o[l];
							do
								return n[e[2]]
							end
							l = l + 1;
							e = o[l];
							do
								return
							end;
						elseif t > 57 then
							local a;
							local t;
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = {};
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							for e = e[2], e[3] do
								n[e] = nil;
							end;
							l = l + 1;
							e = o[l];
							t = e[2];
							a = n[t];
							for e = t + 1, e[3] do
								s(a, n[e])
							end;
						else
							if n[e[2]] then
								l = l + 1;
							else
								l = e[3];
							end;
						end;
					elseif t <= 68 then
						if t <= 63 then
							if t <= 60 then
								if t == 59 then
									n[e[2]] = n[e[3]] * e[4];
								else
									local f;
									local d;
									local t;
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									n[e[2]] = {};
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									n[e[2]] = {};
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									n[e[2]] = n[e[3]] - e[4];
									l = l + 1;
									e = o[l];
									n[e[2]] = e[3];
									l = l + 1;
									e = o[l];
									t = e[2];
									d = n[t]
									f = n[t + 2];
									if (f > 0) then
										if (d > n[t + 1]) then
											l = e[3];
										else
											n[t + 3] = d;
										end
									elseif (d < n[t + 1]) then
										l = e[3];
									else
										n[t + 3] = d;
									end
								end;
							elseif t <= 61 then
								local f;
								local i;
								local t;
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								n[e[2]] = {};
								l = l + 1;
								e = o[l];
								n[e[2]] = {};
								l = l + 1;
								e = o[l];
								t = e[2];
								a = t + N - 1;
								for e = t, a do
									i = c[e - t];
									n[e] = i;
								end;
								l = l + 1;
								e = o[l];
								t = e[2];
								f = n[t];
								for e = t + 1, a do
									s(f, n[e])
								end;
							elseif t > 62 then
								local e = e[2]
								local o, l = i(n[e]())
								a = l + e - 1
								local l = 0;
								for e = e, a do
									l = l + 1;
									n[e] = o[l];
								end;
							else
								if (n[e[2]] < n[e[4]]) then
									l = l + 1;
								else
									l = e[3];
								end;
							end;
						elseif t <= 65 then
							if t == 64 then
								if (n[e[2]] <= n[e[4]]) then
									l = e[3];
								else
									l = l + 1;
								end;
							else
								local i, a;
								local t;
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + e[4];
								l = l + 1;
								e = o[l];
								t = e[2]
								i, a = {
									n[t](f(n, t + 1, e[3]))
								}, 0;
								for e = t, e[4] do
									a = a + 1;
									n[e] = i[a];
								end
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t](f(n, t + 1, e[3]))
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t](f(n, t + 1, e[3]))
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + e[4];
								l = l + 1;
								e = o[l];
								d[e[3]] = n[e[2]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] * e[4];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + n[e[4]];
								l = l + 1;
								e = o[l];
								do
									return n[e[2]]
								end
								l = l + 1;
								e = o[l];
								do
									return
								end;
							end;
						elseif t <= 66 then
							local e = e[2];
							a = e + N - 1;
							for l = e, a do
								local e = c[l - e];
								n[l] = e;
							end;
						elseif t > 67 then
							n[e[2]] = n[e[3]] - n[e[4]];
						else
							n[e[2]] = {};
						end;
					elseif t <= 73 then
						if t <= 70 then
							if t > 69 then
								local a;
								local f;
								local t;
								t = e[2]
								n[t] = n[t]()
								l = l + 1;
								e = o[l];
								n[e[2]][e[3]] = n[e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t]()
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								t = e[2];
								f = n[t]
								a = n[t + 2];
								if (a > 0) then
									if (f > n[t + 1]) then
										l = e[3];
									else
										n[t + 3] = f;
									end
								elseif (f < n[t + 1]) then
									l = e[3];
								else
									n[t + 3] = f;
								end
							else
								local h;
								local c, s;
								local t;
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								t = e[2]
								c, s = i(n[t](f(n, t + 1, e[3])))
								a = s + t - 1
								h = 0;
								for e = t, a do
									h = h + 1;
									n[e] = c[h];
								end;
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t](f(n, t + 1, a))
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + e[4];
								l = l + 1;
								e = o[l];
								d[e[3]] = n[e[2]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + n[e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] - e[4];
								l = l + 1;
								e = o[l];
								t = e[2]
								c, s = i(n[t](f(n, t + 1, e[3])))
								a = s + t - 1
								h = 0;
								for e = t, a do
									h = h + 1;
									n[e] = c[h];
								end;
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t](f(n, t + 1, a))
								l = l + 1;
								e = o[l];
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]] + n[e[4]];
								l = l + 1;
								e = o[l];
								d[e[3]] = n[e[2]];
								l = l + 1;
								e = o[l];
								do
									return n[e[2]]
								end
								l = l + 1;
								e = o[l];
								do
									return
								end;
							end;
						elseif t <= 71 then
							local l = e[2];
							local o = n[l];
							for e = l + 1, e[3] do
								s(o, n[e])
							end;
						elseif t == 72 then
							local e = e[2]
							n[e](n[e + 1])
						else
							local o = e[2];
							local t = n[o]
							local d = n[o + 2];
							if (d > 0) then
								if (t > n[o + 1]) then
									l = e[3];
								else
									n[o + 3] = t;
								end
							elseif (t < n[o + 1]) then
								l = e[3];
							else
								n[o + 3] = t;
							end
						end;
					elseif t <= 75 then
						if t == 74 then
							local t;
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] - e[4];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] / e[4];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + n[e[4]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] * n[e[4]];
							l = l + 1;
							e = o[l];
							do
								return n[e[2]]
							end
							l = l + 1;
							e = o[l];
							do
								return
							end;
						else
							do
								return n[e[2]]
							end
						end;
					elseif t <= 76 then
						local a;
						local i;
						local t;
						n[e[2]] = d[e[3]];
						l = l + 1;
						e = o[l];
						n[e[2]] = d[e[3]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]];
						l = l + 1;
						e = o[l];
						t = e[2]
						n[t] = n[t](f(n, t + 1, e[3]))
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] - e[4];
						l = l + 1;
						e = o[l];
						t = e[2]
						n[t] = n[t](n[t + 1])
						l = l + 1;
						e = o[l];
						i = e[3];
						a = n[i]
						for e = i + 1, e[4] do
							a = a .. n[e];
						end;
						n[e[2]] = a;
					elseif t == 77 then
						local d;
						local t;
						n[e[2]] = {};
						l = l + 1;
						e = o[l];
						n[e[2]] = {};
						l = l + 1;
						e = o[l];
						n[e[2]] = {};
						l = l + 1;
						e = o[l];
						n[e[2]] = {};
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]];
						l = l + 1;
						e = o[l];
						for e = e[2], e[3] do
							n[e] = nil;
						end;
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]];
						l = l + 1;
						e = o[l];
						t = e[2];
						d = n[t];
						for e = t + 1, e[3] do
							s(d, n[e])
						end;
					else
						if (n[e[2]] ~= n[e[4]]) then
							l = l + 1;
						else
							l = e[3];
						end;
					end;
				elseif t <= 118 then
					if t <= 98 then
						if t <= 88 then
							if t <= 83 then
								if t <= 80 then
									if t == 79 then
										if not n[e[2]] then
											l = l + 1;
										else
											l = e[3];
										end;
									else
										n[e[2]] = n[e[3]][n[e[4]]];
									end;
								elseif t <= 81 then
									local e = e[2]
									n[e] = n[e](n[e + 1])
								elseif t == 82 then
									local e = e[2];
									do
										return f(n, e, a)
									end;
								else
									if (e[2] < n[e[4]]) then
										l = e[3];
									else
										l = l + 1;
									end;
								end;
							elseif t <= 85 then
								if t > 84 then
									n[e[2]][e[3]] = n[e[4]];
								else
									d[e[3]] = n[e[2]];
								end;
							elseif t <= 86 then
								n[e[2]] = d[e[3]];
							elseif t == 87 then
								local f;
								local d;
								local t;
								t = e[2]
								n[t] = n[t]()
								l = l + 1;
								e = o[l];
								n[e[2]] = {};
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								t = e[2];
								d = n[t]
								f = n[t + 2];
								if (f > 0) then
									if (d > n[t + 1]) then
										l = e[3];
									else
										n[t + 3] = d;
									end
								elseif (d < n[t + 1]) then
									l = e[3];
								else
									n[t + 3] = d;
								end
							else
								n[e[2]] = e[3] ^ n[e[4]];
							end;
						elseif t <= 93 then
							if t <= 90 then
								if t > 89 then
									local e = e[2]
									n[e] = n[e]()
								else
									if (n[e[2]] ~= e[4]) then
										l = l + 1;
									else
										l = e[3];
									end;
								end;
							elseif t <= 91 then
								if (n[e[2]] <= e[4]) then
									l = e[3];
								else
									l = l + 1;
								end;
							elseif t > 92 then
								local l = e[2]
								local o, e = i(n[l](f(n, l + 1, e[3])))
								a = e + l - 1
								local e = 0;
								for l = l, a do
									e = e + 1;
									n[l] = o[e];
								end;
							else
								if (n[e[2]] <= e[4]) then
									l = e[3];
								else
									l = l + 1;
								end;
							end;
						elseif t <= 95 then
							if t > 94 then
								l = e[3];
							else
								local a = M[e[3]];
								local f;
								local t = {};
								f = Z({}, {
									__index = function(l, e)
										local e = t[e];
										return e[1][e[2]];
									end,
									__newindex = function(n, e, l)
										local e = t[e]
										e[1][e[2]] = l;
									end;
								});
								for f = 1, e[4] do
									l = l + 1;
									local e = o[l];
									if e[1] == 51 then
										t[f - 1] = {
											n,
											e[3]
										};
									else
										t[f - 1] = {
											d,
											e[3]
										};
									end;
									r[# r + 1] = t;
								end;
								n[e[2]] = O(a, f, h);
							end;
						elseif t <= 96 then
							if (n[e[2]] < n[e[4]]) then
								l = e[3];
							else
								l = l + 1;
							end;
						elseif t == 97 then
							local e = e[2]
							n[e] = n[e]()
						else
							n[e[2]] = h[e[3]];
						end;
					elseif t <= 108 then
						if t <= 103 then
							if t <= 100 then
								if t > 99 then
									local t;
									n[e[2]] = n[e[3]][n[e[4]]];
									l = l + 1;
									e = o[l];
									n[e[2]] = n[e[3]] + e[4];
									l = l + 1;
									e = o[l];
									n[e[2]] = n[e[3]][n[e[4]]];
									l = l + 1;
									e = o[l];
									t = e[2]
									n[t](n[t + 1])
									l = l + 1;
									e = o[l];
									l = e[3];
								else
									n[e[2]] = (e[3] ~= 0);
								end;
							elseif t <= 101 then
								local l = e[2];
								do
									return n[l](f(n, l + 1, e[3]))
								end;
							elseif t > 102 then
								if (n[e[2]] <= e[4]) then
									l = l + 1;
								else
									l = e[3];
								end;
							else
								local l = e[2]
								local o, e = i(n[l](f(n, l + 1, e[3])))
								a = e + l - 1
								local e = 0;
								for l = l, a do
									e = e + 1;
									n[l] = o[e];
								end;
							end;
						elseif t <= 105 then
							if t == 104 then
								local l = e[2]
								n[l] = n[l](f(n, l + 1, e[3]))
							else
								n[e[2]] = h[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = h[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = h[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = h[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]][e[4]];
								l = l + 1;
								e = o[l];
								n[e[2]] = h[e[3]];
								l = l + 1;
								e = o[l];
								if not n[e[2]] then
									l = l + 1;
								else
									l = e[3];
								end;
							end;
						elseif t <= 106 then
							n[e[2]] = n[e[3]] * n[e[4]];
						elseif t > 107 then
							n[e[2]] = n[e[3]] % n[e[4]];
						else
							n[e[2]][n[e[3]]] = n[e[4]];
						end;
					elseif t <= 113 then
						if t <= 110 then
							if t > 109 then
								n[e[2]] = n[e[3]][n[e[4]]];
							else
								local e = e[2]
								n[e](n[e + 1])
							end;
						elseif t <= 111 then
							if (n[e[2]] < n[e[4]]) then
								l = e[3];
							else
								l = l + 1;
							end;
						elseif t > 112 then
							local a;
							local i;
							local t;
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							i = e[3];
							a = n[i]
							for e = i + 1, e[4] do
								a = a .. n[e];
							end;
							n[e[2]] = a;
						else
							do
								return
							end;
						end;
					elseif t <= 115 then
						if t == 114 then
							n[e[2]] = (e[3] ~= 0);
						else
							n[e[2]] = n[e[3]];
						end;
					elseif t <= 116 then
						local e = e[2];
						do
							return n[e](f(n, e + 1, a))
						end;
					elseif t == 117 then
						n[e[2]] = n[e[3]] * e[4];
					else
						if (n[e[2]] ~= e[4]) then
							l = l + 1;
						else
							l = e[3];
						end;
					end;
				elseif t <= 138 then
					if t <= 128 then
						if t <= 123 then
							if t <= 120 then
								if t == 119 then
									local e = e[2]
									n[e] = n[e](n[e + 1])
								else
									n[e[2]] = n[e[3]] / e[4];
								end;
							elseif t <= 121 then
								local o = e[2];
								local d = n[o + 2];
								local t = n[o] + d;
								n[o] = t;
								if (d > 0) then
									if (t <= n[o + 1]) then
										l = e[3];
										n[o + 3] = t;
									end
								elseif (t >= n[o + 1]) then
									l = e[3];
									n[o + 3] = t;
								end
							elseif t == 122 then
								n[e[2]][n[e[3]]] = n[e[4]];
							else
								local t;
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t](f(n, t + 1, e[3]))
								l = l + 1;
								e = o[l];
								if (n[e[2]] ~= e[4]) then
									l = l + 1;
								else
									l = e[3];
								end;
							end;
						elseif t <= 125 then
							if t > 124 then
								n[e[2]] = n[e[3]][e[4]];
							else
								local h;
								local s, c;
								local t;
								n[e[2]] = d[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								t = e[2]
								s, c = i(n[t]())
								a = c + t - 1
								h = 0;
								for e = t, a do
									h = h + 1;
									n[e] = s[h];
								end;
								l = l + 1;
								e = o[l];
								t = e[2]
								n[t] = n[t](f(n, t + 1, a))
								l = l + 1;
								e = o[l];
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]][e[3]] = n[e[4]];
							end;
						elseif t <= 126 then
							if (n[e[2]] ~= n[e[4]]) then
								l = l + 1;
							else
								l = e[3];
							end;
						elseif t > 127 then
							local l = e[2];
							do
								return n[l](f(n, l + 1, e[3]))
							end;
						else
							local t;
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]][e[3]] = n[e[4]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]][e[3]] = n[e[4]];
							l = l + 1;
							e = o[l];
							l = e[3];
						end;
					elseif t <= 133 then
						if t <= 130 then
							if t > 129 then
								local t;
								n[e[2]] = n[e[3]];
								l = l + 1;
								e = o[l];
								n[e[2]] = e[3];
								l = l + 1;
								e = o[l];
								t = e[2];
								do
									return n[t](f(n, t + 1, e[3]))
								end;
								l = l + 1;
								e = o[l];
								t = e[2];
								do
									return f(n, t, a)
								end;
								l = l + 1;
								e = o[l];
								do
									return
								end;
							else
								n[e[2]] = e[3] / e[4];
							end;
						elseif t <= 131 then
							local e = e[2];
							do
								return n[e](f(n, e + 1, a))
							end;
						elseif t == 132 then
							n[e[2]] = n[e[3]] + n[e[4]];
						else
							local e = e[2];
							do
								return f(n, e, a)
							end;
						end;
					elseif t <= 135 then
						if t == 134 then
							local t;
							n[e[2]] = n[e[3]][n[e[4]]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + e[4];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]][n[e[4]]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t](n[t + 1])
							l = l + 1;
							e = o[l];
							l = e[3];
						else
							if (n[e[2]] <= n[e[4]]) then
								l = e[3];
							else
								l = l + 1;
							end;
						end;
					elseif t <= 136 then
						n[e[2]] = n[e[3]] * n[e[4]];
					elseif t > 137 then
						n[e[2]] = e[3];
					else
						if (e[2] < n[e[4]]) then
							l = e[3];
						else
							l = l + 1;
						end;
					end;
				elseif t <= 148 then
					if t <= 143 then
						if t <= 140 then
							if t == 139 then
								local e = e[2];
								local l = n[e];
								for e = e + 1, a do
									s(l, n[e])
								end;
							else
								n[e[2]] = n[e[3]] % n[e[4]];
							end;
						elseif t <= 141 then
							local d;
							local t;
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]] = {};
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							t = e[2];
							a = t + N - 1;
							for e = t, a do
								d = c[e - t];
								n[e] = d;
							end;
							l = l + 1;
							e = o[l];
							t = e[2];
							do
								return n[t](f(n, t + 1, a))
							end;
							l = l + 1;
							e = o[l];
							t = e[2];
							do
								return f(n, t, a)
							end;
							l = l + 1;
							e = o[l];
							do
								return
							end;
						elseif t > 142 then
							n[e[2]] = n[e[3]] - n[e[4]];
						else
							d[e[3]] = n[e[2]];
						end;
					elseif t <= 145 then
						if t == 144 then
							if (e[2] < n[e[4]]) then
								l = l + 1;
							else
								l = e[3];
							end;
						else
							local a = M[e[3]];
							local f;
							local t = {};
							f = Z({}, {
								__index = function(l, e)
									local e = t[e];
									return e[1][e[2]];
								end,
								__newindex = function(n, e, l)
									local e = t[e]
									e[1][e[2]] = l;
								end;
							});
							for f = 1, e[4] do
								l = l + 1;
								local e = o[l];
								if e[1] == 51 then
									t[f - 1] = {
										n,
										e[3]
									};
								else
									t[f - 1] = {
										d,
										e[3]
									};
								end;
								r[# r + 1] = t;
							end;
							n[e[2]] = O(a, f, h);
						end;
					elseif t <= 146 then
						n[e[2]] = n[e[3]] + e[4];
					elseif t == 147 then
						local l = e[2]
						local o, e = i(n[l]())
						a = e + l - 1
						local e = 0;
						for l = l, a do
							e = e + 1;
							n[l] = o[e];
						end;
					else
						n[e[2]] = d[e[3]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]][e[4]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]][n[e[4]]];
						l = l + 1;
						e = o[l];
						n[e[2]][n[e[3]]] = n[e[4]];
						l = l + 1;
						e = o[l];
						l = e[3];
					end;
				elseif t <= 153 then
					if t <= 150 then
						if t > 149 then
							local t;
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t]()
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] * e[4];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + n[e[4]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3] ^ n[e[4]];
							l = l + 1;
							e = o[l];
							if (n[e[2]] == e[4]) then
								l = l + 1;
							else
								l = e[3];
							end;
						else
							local i;
							local a;
							local t;
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + n[e[4]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] - e[4];
							l = l + 1;
							e = o[l];
							t = e[2]
							n[t] = n[t](f(n, t + 1, e[3]))
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = d[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = n[e[3]] + n[e[4]];
							l = l + 1;
							e = o[l];
							d[e[3]] = n[e[2]];
							l = l + 1;
							e = o[l];
							n[e[2]] = {};
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							n[e[2]] = # n[e[3]];
							l = l + 1;
							e = o[l];
							n[e[2]] = e[3];
							l = l + 1;
							e = o[l];
							t = e[2];
							a = n[t]
							i = n[t + 2];
							if (i > 0) then
								if (a > n[t + 1]) then
									l = e[3];
								else
									n[t + 3] = a;
								end
							elseif (a < n[t + 1]) then
								l = e[3];
							else
								n[t + 3] = a;
							end
						end;
					elseif t <= 151 then
						for e = e[2], e[3] do
							n[e] = nil;
						end;
					elseif t > 152 then
						n[e[2]] = e[3];
					else
						local t;
						t = e[2]
						n[t] = n[t]()
						l = l + 1;
						e = o[l];
						n[e[2]] = d[e[3]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]];
						l = l + 1;
						e = o[l];
						n[e[2]] = e[3];
						l = l + 1;
						e = o[l];
						n[e[2]] = e[3];
						l = l + 1;
						e = o[l];
						t = e[2]
						n[t] = n[t](f(n, t + 1, e[3]))
						l = l + 1;
						e = o[l];
						if (n[e[2]] ~= e[4]) then
							l = l + 1;
						else
							l = e[3];
						end;
					end;
				elseif t <= 155 then
					if t == 154 then
						local l = e[2]
						n[l] = n[l](f(n, l + 1, e[3]))
					else
						n[e[2]] = e[3] ^ n[e[4]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] / n[e[4]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] - e[4];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] - e[4];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] - n[e[4]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] + e[4];
						l = l + 1;
						e = o[l];
						n[e[2]] = e[3] ^ n[e[4]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] % n[e[4]];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] % e[4];
						l = l + 1;
						e = o[l];
						n[e[2]] = n[e[3]] - n[e[4]];
						l = l + 1;
						e = o[l];
						do
							return n[e[2]]
						end
						l = l + 1;
						e = o[l];
						l = e[3];
					end;
				elseif t <= 156 then
					n[e[2]] = n[e[3]] + n[e[4]];
				elseif t == 157 then
					if (n[e[2]] < n[e[4]]) then
						l = l + 1;
					else
						l = e[3];
					end;
				else
					n[e[2]] = n[e[3]] % e[4];
				end;
				l = l + 1;
			end;
		end;
	end;
	return O(R(), {}, P)(...);
end)(...)