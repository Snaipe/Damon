module damon.monad;

import std.traits;

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
