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
module damon.monad;

import std.traits : TemplateArgsOf, ReturnType, ParameterTypeTuple;
import std.stdio;
import damon.functional;

template isMonadicOperation(F, alias T) {
	alias ArgList = ParameterTypeTuple!F;
	enum bool isMonadicOperation = isCallable!F
			&& ArgList.length == 1 && is(ArgList[0] == T);
}

template FirstArg(F) {
	alias FirstArg = ParameterTypeTuple!F[0];
}

mixin template dispatch() {
	auto opDispatch(string s)() {
		return bind((T v) => fromValue(__traits(getMember, v, s)));
	}

	auto opDispatch(string s, Args...)(Args args) {
		return bind((T v) => fromValue(__traits(getMember, v, s)(args)));
	}
}

mixin template monadicOperations(alias M) {
	M!R bindF(F, R = ReturnType!F, T = FirstArg!F)(F callback)
			if (isMonadicOperation!(F, T)) {
		return bind((T t) => (M!Object).fromValue(callback(t)));
	}

	auto opBinary(string op, A, T = FirstArg!A)(A rhs)
			if (op == ">>" && isMonadicOperation!(A, T)) {
		return bind(rhs);
	}

	auto opBinary(string op, A, T = FirstArg!A)(A rhs)
			if (op == ">>>" && isMonadicOperation!(A, T)) {
		return bindF(rhs);
	}
}
