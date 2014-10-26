module damon.functional;

import std.traits;

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
