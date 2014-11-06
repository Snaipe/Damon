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

import std.traits;
import damon.functional;

template isLesserMonadicOperation(M, alias T, F) {
	alias Monad = TemplateOf!M;
	alias ArgList = ParameterTypeTuple!F;
	enum bool isLesserMonadicOperation = isCallable!F
			&& ArgList.length == 1 && is(ArgList[0] == T);
}

template isMonadicOperation(M, alias T, F) {
	alias Monad = TemplateOf!M;
	enum bool isMonadicOperation = isLesserMonadicOperation!(M, T, F)
			&& __traits(isSame, TemplateOf!(ReturnType!F), Monad);
}

class Monad(T) {
	abstract ReturnType!F bind(F)(F callback)
			if (isMonadicOperation(Monad, T, F));
}

mixin template monadicOperations(M) {
	ReturnType!F bindF(F)(F callback) if (isLesserMonadicOperation(M, T, F)) {
		return bind((T t) => new M!R(callback(t)));
	}

	auto opBinary(string op, A)(A rhs)
			if (op == ">>" && isMonadicOperation!(M, T, A)) {
		return bind(rhs);
	}

	auto opBinary(string op, A)(A rhs)
			if (op == ">>>" && isLesserMonadicOperation(M, T, F)) {
		return bindF(rhs);
	}
}

mixin template dispatch(alias F, alias M) {
	auto opDispatch(string s)() {
		return bind((T v) => F!M(__traits(getMember, v, s)));
	}

	auto opDispatch(string s, Args...)(Args args) {
		return bind((T v) => F!M(__traits(getMember, v, s)(args)));
	}
}

template from_value(alias M) {
	M!V from_value(V)(V val) {
		return new M!V(val);
	}
}

template from_values(alias M) {
	M!V from_values(V)(V[] val) {
		return new M!V(val);
	}
}

class Maybe(T) : Monad!(T) {
	private T val;

	this(T val) { this.val = val; }
	this()      { this(null); }

	@property T value() { return this.val; }

	ReturnType!F bind(F)(F callback) if (isMonadicOperation!(Maybe, T, F)) {
		if (this.val is null)
			return new ReturnType!F();
		else
			return callback(this.val);
	}

	mixin dispatch!(from_value, Maybe);
	mixin monadicOperations!(Maybe);
}

unittest {
	class C { }
	class B {
		C c;
		this(C c) { this.c = c; }
	}
	class A {
		B b;
		this(B b) { this.b = b; }
	}

	C c = new C;
	Maybe!A a1 = from_value!Maybe(new A(new B(c)));
	Maybe!A a2 = from_value!Maybe(new A(null));

	auto getB = delegate (A a) => new Maybe!B(a.b);
	auto getC = (B b) => new Maybe!C(b.c);

	assert (a1.b.c.value is c);
	assert (a1.bind(getB).bind(getC).value is c);
	assert ((a1 >> getB >> getC).value is c);
	assert (a2.b.c.value is null);
}
