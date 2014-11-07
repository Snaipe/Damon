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
import std.variant;
import damon.functional;

template isMonadicOperation(F, alias T) {
	alias ArgList = ParameterTypeTuple!F;
	enum bool isMonadicOperation = isCallable!F
			&& ArgList.length == 1 && is(ArgList[0] == T);
}

template FirstArg(F) {
	alias FirstArg = ParameterTypeTuple!F[0];
}

abstract class Monad(T) {
	R bind(F, R = ReturnType!F, T = FirstArg!F)(F callback)
			if (isMonadicOperation!(F, T)) {

		Variant v = this.bindImpl((Variant arg) => Variant(callback(arg.get!T)));
		if (v.convertsTo!R)
			return v.get!R;

		// if the value is a pointer, force its conversion to the proper
		// pointer type. This exists to overcome the impossibility to
		// convert Nothing!A to Nothing!B, even though the template
		// parameter is not used to store anything.
		return * cast (R *) v.get!(void *);
	}

	protected abstract Variant bindImpl(Variant delegate(Variant) callback);
}

mixin template monadicOperations(alias M) {
	M!R bindF(F, R = ReturnType!F, T = FirstArg!F)(F callback)
			if (isMonadicOperation!(F, T)) {
		return bind((T t) => (M!Object).from_value(callback(t)));
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

mixin template dispatch() {
	auto opDispatch(string s)() {
		return bind((T v) => from_value(__traits(getMember, v, s)));
	}

	auto opDispatch(string s, Args...)(Args args) {
		return bind((T v) => from_value(__traits(getMember, v, s)(args)));
	}
}

abstract class Maybe(T) : Monad!T {
	static Maybe!V from_value(V)(V val) {
		return val is null ? new Nothing!V : new Just!V(val);
	}

	abstract @property T value();

	abstract bool hasValue();

	mixin dispatch;
	mixin monadicOperations!(Maybe);
}

class Just(T) : Maybe!T {
	private T val;

	this(T val ...) { this.val = val; }

	override @property T value() { return this.val; }
	override bool hasValue() { return true; }

	protected override Variant bindImpl(Variant delegate(Variant) callback) {
		return callback(Variant(this.val));
	}
}

class Nothing(T) : Maybe!T {
	override @property T value() { return null; }
	override bool hasValue() { return false; }

	protected override Variant bindImpl(Variant delegate(Variant) callback) {
		return Variant(&this);
	}
}

unittest {
	class C { }
	class B {
		C c;
		this(C c ...) { this.c = c; }
	}
	class A {
		B b;
		this(B b ...) { this.b = b; }
	}

	C c = new C;
	Just!A a1 = new Just!A(c);
	Maybe!A a2 = new Just!A(new A(null));

	auto getB = delegate (A a) => Maybe!Object.from_value(a.b);
	auto getC = (B b) => b.c;

	auto v1 = a1.b.c;
	auto v2 = a1.bind(getB).bindF(getC);
	auto v3 = a1 >> getB >>> getC;
	auto v4 = a2.b.c;

	assert (v1.hasValue && v1.value is c);
	assert (v2.hasValue && v2.value is c);
	assert (v3.hasValue && v3.value is c);
	assert (!v4.hasValue && v3.value is null);
}
