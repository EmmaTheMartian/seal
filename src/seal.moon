is_term = (str) -> return str\match('^[%(%)%[%]{}:]$') != nil
is_alpha = (str) -> return str\match('^[%l%w%-_]+$') != nil
is_id_char = (str) -> return str\match('^[%l%w%d%-%._]+$') != nil

class TokenKind
	TERM   = 'term'   -- any of: []{}():
	ID     = 'id'     -- [a-zA-Z_][a-zA-Z0-9\-\._]*
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
		@prev = nil
		@start = 1

	is_done: =>
		return @pos >= #@source

	advance: =>
		@pos += 1
		@column += 1
		@prev_prev = @prev
		@prev = @ch
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
		in_expr = false
		while true
			if @ch == '"' and not in_expr
				break
			elseif @ch == '\\'
				self\advance!
			elseif @ch == '\0'
				print 'error: unterminated string'
				os.exit 1
			elseif @ch == '\n'
				@line += 1
				@column = 1
			elseif @ch == '[' and @prev == '$' and @prev_prev != '\\'
				in_expr = true
			elseif @ch == ']' and @prev != '\\' and in_expr
				in_expr = false
			self\advance!
		self\advance!
		-- slice the quotes at the start and end
		self.start += 1
		tok = self\make_token_with_offset 'string', -1
		-- Handle escape sequences
		tok.text = tok.text\gsub('\\n', '\n')\gsub('\\"', '"')
		return tok

	lex_id: =>
		self\advance!
		@start = @pos
		while is_id_char @ch
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
		elseif is_alpha @ch
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

			params = {}
			if self\accept ':'
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

compile_text = nil -- forward declare or something

compile_str = (str, macros) ->
	compiled_str = ''
	ch = ''
	prev = ''
	prev_prev = ''
	depth = 0
	i = 1
	while i <= #str
		ch = str\sub i, i

		if prev_prev != '\\' and prev == '$' and ch == '['
			compiled_str = compiled_str\sub 0, #compiled_str - 1 -- Remove the `$` from the string
			depth += 1
			e = '['
			i += 1
			while depth > 0 and i <= #str
				ch = str\sub i, i
				if ch == '['
					depth += 1
				elseif ch == ']'
					depth -= 1
				e ..= ch
				i += 1
				prev_prev = prev
				prev = ch
			ch = str\sub i, i
			compiled_str ..= compile_text e, macros
			if ch != nil
				compiled_str ..= ch
		else
			compiled_str ..= ch

		i += 1
		prev_prev = prev
		prev = ch
		ch = str[i]
	return compiled_str

compile_text = (text, macros) ->
	parser = Parser Tokenizer(text)

	html = ''

	for _, statement in ipairs parser\parse!
		if macros[statement.id] == nil
			it = require 'macros.' .. statement.id
			macros[statement.id] = it
			if it == nil
				print 'error: unknown macro: ' .. statement.id
				os.exit 1

		-- process string formatting
		for key, param in pairs statement.params
			if param.kind == 'string'
				statement.params[key].text = compile_str param.text, macros

		m = macros[statement.id](statement.params)
		if not m
			print 'expected string from macro `' .. statement.id .. '` but got `' .. type(m) .. '`'
			os.exit 1

		html ..= m

	return html

config = {
	lang: 'en'
}
vars = {}
element_stack = {}

simple_element = (el, tokens) ->
	html = '<' .. el .. '>'
	for _, token in ipairs tokens
		html ..= token.text
	html ..= '</' .. el .. '>'
	return html

push_block_element = (el) ->
	table.insert element_stack, el
	return '<' .. el .. '>'

get_builtin_macros = -> return {
	-- Misc
	raw: (t) -> return t[1].text
	begin: (t) -> push_block_element t[1].text
	end: (t) ->
		it = element_stack[#element_stack]
		table.remove element_stack, #element_stack
		if t[1] != nil
			return '</' .. t[1].text .. '>'
		return '</' .. it .. '>'

	-- Config
	config: (t) ->
		config[t[1].text] = t[2].text
		return ''

	-- Variables
	set: (t) ->
		vars[t[1].text] = t[2].text
		return ''
	get: (t) -> return vars[t[1].text]

	-- Textual elements
	h1: (t) -> return simple_element 'h1', t
	h2: (t) -> return simple_element 'h2', t
	h3: (t) -> return simple_element 'h3', t
	h4: (t) -> return simple_element 'h4', t
	h5: (t) -> return simple_element 'h5', t
	h6: (t) -> return simple_element 'h6', t
	p: (t) -> return simple_element 'p', t
	span: (t) -> return simple_element 'span', t
	b: (t) -> return simple_element 'b', t
	strong: (t) -> return simple_element 'strong', t
	i: (t) -> return simple_element 'i', t
	em: (t) -> return simple_element 'em', t
	li: (t) -> return simple_element 'li', t
	code: (t) -> return simple_element 'code', t
	summary: (t) -> return simple_element 'summary', t
	th: (t) -> return simple_element 'th', t
	td: (t) -> return simple_element 'td', t
	title: (t) -> return simple_element 'title', t

	-- Links
	a: (t) -> return '<a href="' .. t[2].text .. '">' .. t[1].text .. '</a>'
	link: (t) -> return '<link rel="' .. t[1].text .. '" href="' .. t[2].text .. '" />'
	"link.css": (t) -> return '<link rel="stylesheet" href="' .. t[1].text .. '" />'

	-- Self-closing elements
	hr: (t) -> return '<hr/>'
	br: (t) -> return '<br/>'

	-- Block elements
	html: (_) -> return push_block_element 'html'
	head: (_) -> return push_block_element 'head'
	body: (_) -> return push_block_element 'body'
	div: (_) -> return push_block_element 'div'
	table: (_) -> return push_block_element 'table'
	tr: (_) -> return push_block_element 'tr'
}

compile = (fp) ->
	file = io.open fp
	if file == nil
		print 'error: failed to read file `' .. fp .. '`'
		os.exit 1
	source = file\read '*all'
	file\close!
	macros = get_builtin_macros!

	text = compile_text source, macros

	return '<!DOCTYPE html><html lang="' .. config.lang .. '">' .. text .. '</html>'

{
	:is_term,
	:is_alpha,
	:is_id_char,
	:TokenKind,
	:Token,
	:Tokenizer,
	:Statement,
	:Parser,
	:compile_text,
	:compile_str,
	:config,
	:vars,
	:element_stack,
	:simple_element,
	:push_block_element
	:get_builtin_macros,
	:compile,
}
