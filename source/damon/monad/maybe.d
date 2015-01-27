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
module damon.monad.maybe;

import damon.monad;

abstract class Maybe(T) {
	public abstract @property T value();
	public abstract bool hasValue();

	public static Maybe!Q fromValue(Q)(Q val) {
		return val is null ? new Nothing!Q : new Just!Q(val);
	}

	public M bind(F, M = ReturnType!F, B = TemplateArgsOf!M[0])(F callback) {
		return hasValue() ? callback(value) : new Nothing!B;
	}

	mixin dispatch;
	mixin monadicOperations!Maybe;
}

class Nothing(T) : Maybe!T {
	public override @property T value() {
		throw new Exception("Nothing!" ~ typeid(T).name
				~ " does not have any value.");
	}

	public override bool hasValue() { return false; }
}

class Just(T) : Maybe!T {
	private T val;

	override @property T value() { return this.val; }
	override bool hasValue() { return true; }

	public this(T value ...) {
		this.val = value;
	}
}

private version (unittest) {
	import std.exception;

	class C { }
	class B {
		C c;
		this(C c ...) { this.c = c; }
	}
	class A {
		B b;
		this(B b ...) { this.b = b; }
	}
}

unittest {
	C c = new C;
	Just!A a1 = new Just!A(c);
	Maybe!A a2 = new Just!A(new A(null));

	auto getB = function (A a) => Maybe!Object.fromValue(a.b);
	auto getC = delegate (B b) => b.c;

	Maybe!C v1 = a1.b.c;
	Maybe!C v2 = a1.bind(getB).bindF(getC);
	Maybe!C v3 = a1 >> getB >>> getC;
	Maybe!C v4 = a2.b.c;

	assert (v1.hasValue && v1.value is c, "Expected final value to be unchanged.");
	assert (v2.hasValue && v2.value is c, "Expected final value to be unchanged.");
	assert (v3.hasValue && v3.value is c, "Expected final value to be unchanged.");
	assert (!v4.hasValue, "Expected Nothing to have no value");
	assertThrown!(Exception)(v4.value, "Expected Nothing to throw an exception on value inspection.");
}
