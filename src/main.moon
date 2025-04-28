class TokenKind
	-- Special characters
	OPEN_PAREN    = '('
	CLOSE_PAREN   = ')'
	OPEN_BRACKET  = '['
	CLOSE_BRACKET = ']'
	OPEN_CURLY    = '{'
	CLOSE_CURLY   = '}'
	COLON         = ':'
	-- Literals
	ID     = "id"     -- [a-zA-Z_][a-zA-Z_9-9]*
	STRING = "string" -- ".*"
	NUMBER = "number" -- [0-9]+(\.[0-9]+)?
	LINK   = "link"   -- \<.*\>

class Token
	new: (line, column, kind, text) =>
		@line = line
		@column = column
		@kind = kind
		@text = text

tokenize = (source) ->
	tokens = {}
	prev = nil

	for c in source\gmatch '.'
		io.write c
		prev = c

f = io.open 'emmasite/index.seal'
tokenize f\read 'a'
f\close!

-- {
-- 	:Token,
-- 	:tokenize
-- }
