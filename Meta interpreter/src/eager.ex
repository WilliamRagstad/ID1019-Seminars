defmodule Eager do
	@moduledoc """
		This is an eager evaluator for simple pattern matching and expressions.

		Run using: iex -r env.ex -r translator.ex -r eager.ex
	"""
	def debug(), do: false


	def eval_expr({:atm, id}, _env, _prg), do: {:ok, id}
	def eval_expr({:int, val}, _env, _prg), do: {:ok, val}

	def eval_expr({:var, id}, env, _prg) do
		case Env.lookup(id, env) do
			nil -> :error
			{_, str} -> {:ok, str}
		end
	end

	def eval_expr({:cons, head, tail}, env, prg) do
		case eval_expr(head, env, prg) do
			:error -> :error
			{:ok, hd} ->
				case eval_expr(tail, env, prg) do
					:error -> :error
					{:ok, ts} -> {:ok, {hd, ts}}
				end
		end
	end

	def eval_expr({:case, expr, cls}, env, prg) do
		case eval_expr(expr, env, prg) do
			:error -> :error
			{:ok, str} -> eval_cls(cls, str, env, prg)
		end
	end

	def eval_expr({:lambda, par, free, seq}, env, _prg) do
		case Env.closure(free, env) do
			:error -> :error
			closure -> {:ok, {:closure, par, seq, closure}}
		end
	end

	def eval_expr({:apply, expr, args}, env, prg) do
		case eval_expr(expr, env, prg) do
			:error -> :error
			{:ok, {:closure, par, seq, closure}} ->
				case eval_args(args, env, prg) do
					:error -> :error # :foo ???
					strs ->
						env = Env.args(par, strs, closure)
						eval_seq(seq, env, prg)
				end
		end
	end

	def eval_expr({:call, id, args}, env, prg) when is_atom(id) do
		case List.keyfind(prg, id, 0) do								# TODO: Change default to nil instead of 0?
			nil -> :error
			{_, par, seq} ->
			case eval_args(args, env, prg) do
				:error -> :error
				strs ->
					env = Env.args(par, strs, env)
					eval_seq(seq, env, prg)
			end
		end
	end

	# --------------------------------------------------

	def eval_args([], _env, _prg), do: []
	def eval_args([expr | rest], env, prg) do
		case eval_expr(expr, env, prg) do
			:error -> :error
			{:ok, str} -> [str | eval_args(rest, env, prg)]
		end
	end

	# --------------------------------------------------

	def eval_match(:ignore, _str, env), do: {:ok, env}
	def eval_match({:atm, id}, str, env) do
		cond do
			id == str -> {:ok, env}
			true -> :fail
		end
	end
	def eval_match({:int, val}, str, env) do
		cond do
			val == str -> {:ok, env}
			true -> :fail
		end
	end

	def eval_match({:var, id}, str, env) do
		case Env.lookup(id, env) do
			nil -> {:ok, Env.add(id, str, env)}
			{_, ^str} -> {:ok, env}
			{_, _} -> :fail
		end
	end


	def eval_match({:cons, hp, tp}, {hs, ts}, env) do
		case eval_match(hp, hs, env) do
			:fail -> :fail
			{:ok, env} -> eval_match(tp, ts, env)
		end
	end

	def eval_match(_, _, _), do: :fail

	# --------------------------------------------------

	def eval_cls([], _, _, _), do: :error
	def eval_cls([{:clause, ptr, seq} | cls], str, env, prg) do
		if debug(), do: IO.puts("Eval Clause: #{inspect ptr} == #{inspect str}?")
		vars = extract_vars(ptr)
		c_env = Env.remove(vars, env)
		case eval_match(ptr, str, c_env) do
			:fail ->
				if debug(), do: IO.puts("Clause failed")
				eval_cls(cls, str, env, prg)
			{:ok, env} ->
				if debug(), do: IO.puts("Clause matched! Executing: #{inspect seq}")
				eval_seq(seq, env, prg)
		end
	end

	# --------------------------------------------------

	def extract_vars(:ignore), do: []
	def extract_vars({:int, _}), do: []
	def extract_vars({:atm, _}), do: []
	def extract_vars({:var, v}), do: [v]
	def extract_vars({:cons, h, t}), do: extract_vars(h) ++ extract_vars(t)

	def eval_seq_expr(expr, env, prg, onDone, root) do
		if debug(), do: IO.puts("In Eval Seq Expr: #{inspect expr} in #{inspect env}")
		case eval_expr(expr, env, prg) do
			:error -> :error
			{:ok, result} ->
				# IO.puts("#{inspect expr} == #{inspect result}")
				cond do
					root && onDone != nil -> onDone.(result)
					root -> {result, env}
					true -> {:ok, result}
				end
		end
	end

	def eval_seq_match({:match, lhs, rhs}, env, prg, onDone, root) do
		# IO.puts("#{inspect lhs} := #{inspect rhs}")
		case eval_expr(rhs, env, prg) do
			:error -> :error
			{:ok, str} ->
				# IO.puts("  -> #{inspect lhs} := #{inspect str}")
				vars = extract_vars(lhs)
				env = Env.remove(vars, env)
				case eval_match(lhs, str, env) do
					:fail -> :error
					{:ok, env} ->
						cond do
							root && onDone != nil -> onDone.(env)
							root -> {str, env}
							true -> env
						end
				end
		end
	end

	def eval_seq(exprs, env, prg), do: eval_seq(exprs, env, prg, false)
	def eval_seq([{:match, _, _} = m], env, prg, root), do: eval_seq_match(m, env, prg, nil, root)										# Return the environment from the last match in the sequence
	def eval_seq([{:match, _, _} = m | rest], env, prg, root), do: eval_seq_match(m, env, prg, fn env -> eval_seq(rest, env, prg, root) end, root)
	def eval_seq([expr], env, prg, root), do: eval_seq_expr(expr, env, prg, nil, root) 													# Return the result of the last expression in the sequence
	def eval_seq([expr | rest], env, prg, root), do: eval_seq_expr(expr, env, prg, fn res ->
		if debug(), do: IO.puts("Seq Expr: #{res}") # This will print all but the last expression values.
		eval_seq(rest, env, prg, root)
	end, root)

	# --------------------------------------------------

	def eval(seq, prg), do: eval_seq(seq, Env.new, prg, true)

	@doc """
		Usage: Eager.eval_elixir(quote do: <EXPRESSION/SEQUENCE>)
		Wrap sequence of expressions in (parentheses; separated; by; colons)
	"""
	def eval_elixir(expr, prg), do: Translator.translate(expr) |> eval(prg)
end
