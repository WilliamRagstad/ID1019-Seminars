defmodule Env do
	def new, do: []

	def add(var, val, env), do: [{var, val} | env]

	def remove([], env), do: env
	def remove([var | rest], env), do: remove(rest, remove(var, env))
	def remove(var, [{var, _}]), do: []
	def remove(var, [{var, _} | rest]), do: rest
	def remove(var, [other | rest]), do: [other | remove(var, rest)]
	def remove(_, []), do: []

	def lookup(_var, []), do: :nil # throw "Variable #{var} is not defined in the current environment." end
	def lookup(var, [t = {var, _} | _rest]), do: t
	def lookup(var, [_ | rest]), do: lookup(var, rest)

	def closure([], _env), do: []
	def closure([var | rest], env) do
		case lookup(var, env) do
			nil -> :error
			{^var, _val} = bnd -> [bnd | closure(rest, env)]
		end
	end

	def args([], [], closure), do: closure
	def args([par | prest], [str | srest], closure) do
		[{par, str} | args(prest, srest, closure)]
	end
end
