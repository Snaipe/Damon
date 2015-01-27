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
module damon.currying;

import std.traits: ParameterTypeTuple;
import std.typecons: TypeTuple;

import damon.functional : functionOperations;

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
					"Curryied function cannot be called with more "
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
	auto test = (int i, long j) => i * i + j;
	auto partial = curry!test;
	assert (partial(7)(2) == test(7, 2));
	assert (partial(7, 2) == test(7, 2));
	assert (partial()(7)()(2) == test(7, 2));
	assert (!__traits(compiles, partial(7, 2, 3)));
}
