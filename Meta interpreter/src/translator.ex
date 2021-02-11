defmodule Translator do

  def is_ignore_atom(atm), do: is_atom(atm) && (<<start, _::binary>> = Atom.to_string(atm); start == ?_)

	def translate_expr(atom) when is_atom(atom), do: {:atm, atom}
	def translate_expr(int) when is_integer(int), do: {:int, int}
  def translate_expr({atom, _meta, _env}) when is_atom(atom) do
    cond do
      is_ignore_atom(atom) -> :ignore
      true -> {:var, atom}
    end
  end
	def translate_expr({hd, tl}), do: {:cons, translate_expr(hd), translate_expr(tl)}

	def translate_match({:=, _meta, [lhs, rhs]}), do: {:match, translate_expr(lhs), translate_expr(rhs)}

	def translate_sequence({:__block__, _meta, []}), do: []
	def translate_sequence({:__block__, _meta, [elem | rest]}), do: translate_sequence(elem) ++ translate_sequence({:__block__, [], rest})
	def translate_sequence({:=, _meta, _expr} = t), do: [translate_match(t)]
	def translate_sequence(t), do: [translate_expr(t)]

	@doc """
	Usage: Translator.translate(quote do: <EXPRESSION/SEQUENCE>)
	Wrap sequence of expressions in (parentheses; separated; by; colons)
	"""
	def translate(e), do: translate_sequence(e)

end
