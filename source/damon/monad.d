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

template isMonadicOperation(F, alias T) {
	alias ArgList = ParameterTypeTuple!F;
	enum bool isMonadicOperation = isCallable!F
			&& ArgList.length == 1 && is(ArgList[0] == T);
}

abstract class Monad(T) {
	R bind(F, R = ReturnType!F)(F callback) if (isMonadicOperation!(F, T)) {
		R container;
		R *res = &container;
		void *wrapper(T *arg) {
			*res = callback(* arg);
			return res;
		}
		container = * cast(R *) this.bindImpl(&wrapper);
		return container;
	}

	protected abstract void *bindImpl(void *delegate(T *) callback);
	mixin monadicOperations!(Monad);
}

mixin template monadicOperations(M) {
	M!R bindF(F, R = ReturnType!F)(F callback) if (isMonadicOperation!(F, T)) {
		return bind((T t) => (M!void).from_value(callback(t)));
	}

	auto opBinary(string op, A)(A rhs)
			if (op == ">>" && isMonadicOperation!(A, T)) {
		return bind(rhs);
	}

	auto opBinary(string op, A)(A rhs)
			if (op == ">>>" && isMonadicOperation!(A, T)) {
		return bindF(rhs);
	}
}

mixin template dispatch(alias M) {
	auto opDispatch(string s)() {
		return bind((T v) => from_value(__traits(getMember, v, s)));
	}

	auto opDispatch(string s, Args...)(Args args) {
		return bind((T v) => from_value(__traits(getMember, v, s)(args)));
	}
}

abstract class Maybe(T) : Monad!T {
	@property abstract T value();

	static Maybe!V from_value(V)(V val) {
		return val is null ? new Nothing!V : new Just!V(val);
	}

	mixin dispatch!(Maybe);
	mixin monadicOperations!(Maybe);
}

class Just(T) : Maybe!T {
	private T val;

	this(T val) { this.val = val; }

	@property override T value() { return this.val; }

	protected override void *bindImpl(void *delegate(T *) callback) {
		return callback(&this.val);
	}
}

class Nothing(T) : Maybe!T {
	@property override T value() { return null; }

	protected override void *bindImpl(void *delegate(T *) callback) {
		return &this;
	}
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
	Just!A a1 = new Just!A(new A(new B(c)));
	Maybe!A a2 = new Just!A(new A(null));

	auto getB = delegate (A a) => (Maybe!void).from_value(a.b);
	auto getC = (B b) => b.c;

	assert (a1.b.c.value is c);
	assert (a1.bind(getB).bindF(getC).value is c);
	assert ((a1 >> getB >>> getC).value is c);
	assert (a2.b.c.value is null);
}
