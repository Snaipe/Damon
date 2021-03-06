/* The MIT License (MIT)
 *
 * Copyright (c) 2015 Franklin "Snaipe" Mathieu
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
module damon.functional;

import std.traits: isCallable, ReturnType, ParameterTypeTuple, isSomeFunction;

template isMapApplication(F, T, R) {
	alias Tup = ParameterTypeTuple!F;
	enum bool isMapApplication = Tup.length == 0
		&& is(Tup[0] == T) && is (ReturnType!F == R);
}

interface Functor(T) {
	Functor!R fmap(T, R, F)(F func) if (isCallable!F && isMapApplication!F);
}

auto fmap(F, T = ParameterTypeTuple!F[0])(T[] array, F fun) if (isCallable!F) {
	ReturnType!F result[] = new ReturnType!F [array.length];
	for (size_t i = 0; i < array.length; ++i)
		result[i] = fun(array[i]);
	return result;
}

T[] flatten(T)(T[][] array) {
	size_t len = 0;
	foreach (t; array)
		len += t.length;
	T[] result = new T[len];

	size_t i = 0;
	foreach (t; array)
		foreach (e; t.values)
			result[i++] = e;

	return result;
}

template compose(alias F, alias G) if (isCallable!F && isCallable!G) {
	enum compose = (ParameterTypeTuple!G args) => F(G(args));
}

template pipe(alias F, alias G) if (isCallable!F && isCallable!G) {
	enum pipe = compose!(G, F);
}

mixin template functionOperations() {
	auto opBinary(string op, F)(F f) if (op == "~" && isCallable!F) {
		return compose!(this, f);
	}
	auto opBinaryRight(string op, F)(F f) if (op == "~" && isCallable!F) {
		return compose!(f, this);
	}
	auto opBinary(string op, F)(F f) if (op == "|" && isCallable!F) {
		return pipe!(this, f);
	}
	auto opBinaryRight(string op, F)(F f) if (op == "|" && isCallable!F) {
		return pipe!(f, this);
	}
}

class Function(F...) if (F.length == 1 && isCallable!F) {
	ReturnType!(F[0]) opCall(ParameterTypeTuple!(F[0]) args) {
		return F[0](args);
	}
	mixin functionOperations;
}

unittest {
	long ten() { return 10; }
	auto two_power = (long x) => 2 ^^ x;
	assert (compose!(two_power, ten)() == two_power(ten()));
	assert (pipe!(ten, two_power)() == two_power(ten()));

	auto f_ten = new Function!ten;
	auto f_two_power = new Function!two_power;
	assert ((f_two_power ~ f_ten)() == two_power(ten()));
	assert ((f_two_power ~  &ten)() == two_power(ten()));
	assert ((two_power   ~ f_ten)() == two_power(ten()));

	assert ((f_ten | f_two_power)() == two_power(ten()));
	assert ((f_ten |   two_power)() == two_power(ten()));
	assert ((&ten  | f_two_power)() == two_power(ten()));
}

template binary(string o) {
	class Op {
		auto opCall(T, Q)(T t, Q q) {
			return mixin ("t" ~ o ~ "q");
		}
		mixin functionOperations;
	}
	auto binary() { return new Op; }
}

template unary(string o) {
	class Op {
		auto opCall(T, Q)(T t, Q q) {
			return mixin (o ~ "q");
		}
		mixin functionOperations;
	}
	auto unary() { return new Op; }
}

unittest {
	auto plus = binary!"+";
	assert (plus(1, 2) == 3);

	auto concat = binary!"~";
	assert (concat("hello ", "world") == "hello world");
	assert (!__traits(compiles, concat(1, 2)));
}
