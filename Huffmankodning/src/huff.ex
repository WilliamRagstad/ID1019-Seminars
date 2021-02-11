defmodule Huffman do

	def sample do
		'the quick brown fox jumps over the lazy dog
		this is a sample text that we will use when we build
		up a table we will only handle lower case letters and
		no punctuation symbols the frequency will of course not
		represent english but it is probably not that far off'
	end

	def text()  do
		'this is something that we should encode'
	end

	def test do
		sample = sample()
		tree = tree(sample)
		encode = encode_table(tree)
		decode = decode_table(tree)
		text = text()
		seq = encode(text, encode)
		decode(seq, decode)
	end

	def tree(sample) do
		freq = freq(sample)
		huffman(freq)
	end

  # --------------------

	def freq(sample) do
		freq(sample, [])
	end

	def freq([], freq) do freq end
	def freq([x|xs], freq) do
		freq(xs, update(x, freq))
  end

  # Use tree structure instead of list for O(log k) instead of O(k)
  def update(x, []) do [{x, 1}] end
  def update(x, [{x, f}|xs]) do [{x, f+1} | xs] end
  def update(x, [l|ls]) do [l | update(x, ls)] end

	def huffman(freq) do
    huff(sort(freq))
  end

  def huff([{tree, _}]) do tree end
  def huff([{t1, f1}, {t2, f2} | rest]) do
    huff
  end

  # -----------

	def encode_table(tree) do encode_table(tree, []) end
	def encode_table({left, right}, path) do
    encode_table(left, [0 | path]) ++ encode_table(right, [1 | path])
  end
  def encode_table(x, path) do [{x, reverse(path)}] end

  def reverse(l) do reverse(l, []) end
  def reverse([], r) do r end
  def reverse([x|xs], r) do
    reverse(xs, [x | r])
  end


  # Use tree structure instead of list for O(log k) instead of O(k)
  def lookup_code(x, [{x, c} | _]) do code end
  def lookup_code(x, [_ | r]) do lookup_code(x, r) end
  def lookup_code(_x,[]) do [] end # FIX

  def decode_table(tree) do encode_table(tree) end

  def lookup_char(_, []) do :nil end
  def lookup_char(x, [{c, x} | _]) do {c, x} end
  def lookup_char(x, [_ | r]) do lookup_char(x, r) end

	def encode(text, table) do
		# To implement...
	end

	def decode(seq, tree) do
		# To implement...
  end


  def better_lookup([0 | s], {l, _}) do better_lookup(s, l) end
  def better_lookup([1 | s], {_, r}) do better_lookup(s, r) end

end
