module damon.functional;

import std.traits;

auto fmap(F, T = ParameterTypeTuple!F[0])(T array, F fun) if (isCallable!F) {
	ReturnType!F result[] = new ReturnType!F [array.length];
	for (size_t i = 0; i < array.length; ++i)
		result[i] = fun(array[i]);
	return result;
}
