is_term = (str) -> return str\match('^[%(%)%[%]{}:]$') != nil

is_alnum = (str) -> return str\match('^[%l%w%d_]+$') != nil

class TokenKind
	NONE   = '\0'
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

	advance: =>
		@ch = self\peek!
		@pos += 1
		@column += 1

	peek: =>
		return @source\sub @pos+1, @pos+1

	skip_whitespace: =>
		print 'skip whitespace'
		while true
			print '  `' .. @ch .. '`'
			if @ch == ' ' or @ch == '\t' or @ch == '\r'
				self\advance!
			elseif @ch == '\n'
				self\advance!
				@line += 1
				@column = 1
			else
				print '  done'
				break

	make_token: (kind) =>
		print 'make_token: ' .. @line .. ':' .. @column .. ' (' .. kind .. ')=`' .. @source\sub(@start, @pos) .. '`'
		return Token @line, @column, kind, @source\sub(@start, @pos)

	lex_str: =>
		print 'str:'
		self\advance!
		print @ch
		while self\peek! != '"'
			print '  `' .. @ch .. '`'
			if @ch == '\\'
				self\advance!
			elseif @ch == '\0'
				print 'error: unterminated string'
				os.exit 1
			elseif @ch == '\n'
				@line += 1
				@column = 1
			self\advance!
		print '  done'
		self\advance!
		return self\make_token 'string'

	-- tokenize_id: =>
	-- 	while is_alnum @ch
	-- 		self\advance!
	-- 	return self\make_token 'id'

	-- tokenize_link: =>
	-- 	while self\peek! != '>'
	-- 		self\advance!
	-- 		if @ch == '\0'
	-- 			print 'error: unterminated link'
	-- 			os.exit 1
	-- 	return self\make_token 'link'

	get_next_token: =>
		self\skip_whitespace!

		@start = @pos

		print "start: " .. @start

		print 'ch: ' .. @ch .. ' t=' .. tostring(is_term(@ch)) .. ' a=' .. tostring(is_alnum(@ch))

		if is_term @ch
			self\advance!
			return self\make_token @ch
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
			self\expect 'colon', 'expected colon (`:`) after macro name'
			params = {}
			depth = 1
			while true
				params\insert #params, @token
				if @token.kind == '['
					depth -= 1
				elseif @token.kind == ']'
					depth += 1
					break if depth == 0
				self\advance!
			self\expect ']', 'expected closed bracket (`]`) to end statement'
			statements\insert #statements, Statement(id, param)
			print 'stat'

		return statements

f = io.open 'test.seal'
s = f\read '*all'
t = Tokenizer s
tok = t\get_next_token!
while tok != nil
	print tok
	tok = t\get_next_token!
f\close!
-- p = Parser t
-- for i, statement in ipairs p\parse!
-- 	print '[' .. i .. '] ' .. statement.id .. ': ' .. statement.params
