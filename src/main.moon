is_term = (str) -> return str\match('^[%(%)%[%]{}:]$') != nil

is_alnum = (str) -> return str\match('^[%l%w%d_]+$') != nil

class TokenKind
	TERM   = 'term'     -- any of: []{}():
	ID     = 'id'     -- [a-zA-Z_][a-zA-Z_9-9]*
	STRING = 'string' -- ".*"
	NUMBER = 'number' -- [0-9]+(\.[0-9]+)?
	LINK   = 'link'   -- \<.*\>

class Token
	new: (line, column, kind, text) =>
		@line = line
		@column = column
		@kind = kind
		@text = text

class Tokenizer
	new: (source) =>
		@source = source
		@pos = 0
		@line = 1
		@column = 1
		@ch = self\peek!
		@start = 1

	is_done: =>
		return @pos >= #@source

	advance: =>
		@pos += 1
		@column += 1
		@ch = self\peek!

	peek: =>
		if self\is_done!
			return '\0'
		else
			return @source\sub @pos+1, @pos+1

	skip_whitespace: =>
		while true
			if @ch == ' ' or @ch == '\t' or @ch == '\r'
				self\advance!
			elseif @ch == '\n'
				self\advance!
				@line += 1
				@column = 1
			else
				break

	make_token_with_offset: (kind, offset) =>
			return Token @line, @column, kind, @source\sub(@start, @pos + offset)

	make_token: (kind) =>
		return Token @line, @column, kind, @source\sub(@start, @pos)

	lex_str: =>
		self\advance!
		@start = @pos
		while @ch != '"'
			if @ch == '\\'
				self\advance!
			elseif @ch == '\0'
				print 'error: unterminated string'
				os.exit 1
			elseif @ch == '\n'
				@line += 1
				@column = 1
			self\advance!
		self\advance!
		-- slice the quotes at the start and end
		self.start += 1
		return self\make_token_with_offset 'string', -1

	lex_id: =>
		self\advance!
		@start = @pos
		while is_alnum @ch
			self\advance!
		return self\make_token 'id'

	lex_link: =>
		self\advance!
		@start = @pos
		while @ch != '>'
			if @ch == '\0'
				print 'error: unterminated link'
				os.exit 1
			self\advance!
		self\advance!
		-- slice the `<` and `>`
		@start += 1
		return self\make_token_with_offset 'link', -1

	get_next_token: =>
		self\skip_whitespace!

		@start = @pos

		if self\is_done!
			return nil

		if is_term @ch
			self\advance!
			@start = @pos
			return self\make_token @source\sub(@start, @pos)
		elseif is_alnum @ch
			return self\lex_id!

		switch @ch
			when '\0'
				return nil
			when '"'
				return self\lex_str!
			when '<'
				return self\lex_link!
			else
				print "error: unexpected character `" .. @ch .. "` (at " .. @line .. ":" .. @column .. ")"
				os.exit 1

class Statement
	new: (id, params) =>
		@id = id
		@params = params

class Parser
	new: (tokenizer) =>
		@tokenizer = tokenizer
		@token = nil
		@prev = nil

	advance: =>
		@prev = @token
		@token = @tokenizer\get_next_token!

	accept: (kind) =>
		if @token == nil
			return false

		if @token.kind == kind
			self\advance!
			return true

		return false

	expect: (kind, msg) =>
		unless self\accept kind
			print 'error: ' .. msg
			os.exit 1

	parse: =>
		statements = {}

		self\advance!

		while self\accept '['
			self\expect 'id', 'expected identifier for macro invoke'
			id = @prev.text
			self\expect ':', 'expected colon (`:`) after macro name'
			params = {}
			depth = 1
			while true
				if @token.kind == '['
					depth += 1
				elseif @token.kind == ']'
					depth -= 1
					break if depth == 0
				table.insert params, @token
				self\advance!
			self\expect ']', 'expected closed bracket (`]`) to end statement'
			table.insert statements, Statement(id, params)

		return statements

simple_element = (el, tokens) ->
	html = '<' .. el .. '>'
	for _, token in ipairs tokens
		html ..= token.text
	html ..= '</' .. el .. '>'
	return html

get_builtin_macros = -> return {
	raw: (t) -> return t[1].text
	h1: (t) -> return simple_element 'h1', t
	h2: (t) -> return simple_element 'h2', t
	h3: (t) -> return simple_element 'h3', t
	h4: (t) -> return simple_element 'h4', t
	h5: (t) -> return simple_element 'h5', t
	h6: (t) -> return simple_element 'h6', t
	p: (t) -> return simple_element 'p', t
}

compile = (file, print_statements) ->
	require 'conf'

	file = io.open file
	source = file\read '*all'
	file\close!
	parser = Parser Tokenizer(source)
	macros = get_builtin_macros!
	html = ''

	for _, statement in ipairs parser\parse!
		if print_statements
			print '[' .. i .. '] ' .. statement.id .. ': ' .. #statement.params .. ' params'
		if macros[statement.id] == nil
			it = require 'macros.' .. statement.id
			macros[statement.id] = it
			if it == nil
				print 'error: unknown macro: ' .. statement.id
				os.exit 1
		html ..= macros[statement.id](statement.params)

	return html

text = compile('index.seal')
if text
	f = io.open 'output.html', 'w'
	f\write text
	f\close!
