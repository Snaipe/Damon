/* The MIT License (MIT)
 *
 * Copyright (c) 2014 Snaipe
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

import std.traits;
import std.typecons: TypeTuple;

auto fmap(F, T = ParameterTypeTuple!F[0])(T array, F fun) if (isCallable!F) {
	ReturnType!F result[] = new ReturnType!F [array.length];
	for (size_t i = 0; i < array.length; ++i)
		result[i] = fun(array[i]);
	return result;
}

template compose(alias F, alias G) if (isCallable!F && isCallable!G) {
	enum compose = (ParameterTypeTuple!F args) => G(F(args));
}

mixin template functionOperations() {
	auto opBinary(string op, F)(F f) if (op == "~" && isCallable!F) {
		return compose!(this, f);
	}
	auto opBinaryRight(string op, F)(F f) if (op == "~" && isCallable!F) {
		return compose!(f, this);
	}
}

unittest {
	long ten() { return 10; }
	long two_power(long x) { return 2 ^^ x; }
	assert (compose!(ten, two_power)() == two_power(ten()));

	auto f_ten = new Function!ten;
	auto f_two_power = new Function!two_power;
	assert ((f_ten ~ f_two_power)() == two_power(ten()));
	assert ((f_ten ~ &two_power)() == two_power(ten()));
	assert ((&ten ~ f_two_power)() == two_power(ten()));
}

class Function(alias F) if (isSomeFunction!F) {
	ReturnType!F opCall(ParameterTypeTuple!F args) {
		return F(args);
	}

	mixin functionOperations;
}

private template __Range(int length) {
    static if (length <= 0)
        alias TypeTuple!() __Range;
    else
        alias TypeTuple!(__Range!(length - 1), length - 1) __Range;
}

template curry(alias F) {
	class CurryiedFunction(int provided) {
		private ParameterTypeTuple!F args;

		this(ParameterTypeTuple!F args) { this.args = args; }

		auto opCall(T...)(T params) {
			static assert (provided + T.length <= ParameterTypeTuple!F.length,
					"Curryied function cannot be called with more"
					"arguments than its original definition");

			foreach (i; __Range!(T.length))
				args[provided + i] = params[i];

			static if (provided + T.length == ParameterTypeTuple!F.length)
				return F(args);
			else
				return new CurryiedFunction!(provided + T.length)(args);
		}

		mixin functionOperations;
	}
	auto curry() {
		ParameterTypeTuple!F empty;
		return new CurryiedFunction!0(empty);
	}
}

unittest {
	long test(int i, long j) {
		return i * i + j;
	}
	auto partial = curry!test;
	assert (partial(7)(2) == test(7, 2));
	assert (partial(7, 2) == test(7, 2));
	assert (partial()(7)()(2) == test(7, 2));
	assert (!__traits(compiles, partial(7, 2, 3)));
}
