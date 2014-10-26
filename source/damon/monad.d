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
