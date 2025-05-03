local is_term
is_term = function(str)
  return str:match('^[%(%)%[%]{}:]$') ~= nil
end
local is_alpha
is_alpha = function(str)
  return str:match('^[%l%w%-_]+$') ~= nil
end
local is_id_char
is_id_char = function(str)
  return str:match('^[%l%w%d%-%._]+$') ~= nil
end
local TokenKind
do
  local _class_0
  local TERM, ID, STRING, NUMBER, LINK
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "TokenKind"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  TERM = 'term'
  ID = 'id'
  STRING = 'string'
  NUMBER = 'number'
  LINK = 'link'
  TokenKind = _class_0
end
local Token
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, line, column, kind, text)
      self.line = line
      self.column = column
      self.kind = kind
      self.text = text
    end,
    __base = _base_0,
    __name = "Token"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Token = _class_0
end
local Tokenizer
do
  local _class_0
  local _base_0 = {
    is_done = function(self)
      return self.pos >= #self.source
    end,
    advance = function(self)
      self.pos = self.pos + 1
      self.column = self.column + 1
      self.prev_prev = self.prev
      self.prev = self.ch
      self.ch = self:peek()
    end,
    peek = function(self)
      if self:is_done() then
        return '\0'
      else
        return self.source:sub(self.pos + 1, self.pos + 1)
      end
    end,
    skip_whitespace = function(self)
      while true do
        if self.ch == ' ' or self.ch == '\t' or self.ch == '\r' then
          self:advance()
        elseif self.ch == '\n' then
          self:advance()
          self.line = self.line + 1
          self.column = 1
        else
          break
        end
      end
    end,
    make_token_with_offset = function(self, kind, offset)
      return Token(self.line, self.column, kind, self.source:sub(self.start, self.pos + offset))
    end,
    make_token = function(self, kind)
      return Token(self.line, self.column, kind, self.source:sub(self.start, self.pos))
    end,
    lex_str = function(self)
      self:advance()
      self.start = self.pos
      local in_expr = false
      while true do
        if self.ch == '"' and not in_expr then
          break
        elseif self.ch == '\\' then
          self:advance()
        elseif self.ch == '\0' then
          print('error: unterminated string')
          os.exit(1)
        elseif self.ch == '\n' then
          self.line = self.line + 1
          self.column = 1
        elseif self.ch == '[' and self.prev == '$' and self.prev_prev ~= '\\' then
          in_expr = true
        elseif self.ch == ']' and self.prev ~= '\\' and in_expr then
          in_expr = false
        end
        self:advance()
      end
      self:advance()
      self.start = self.start + 1
      return self:make_token_with_offset('string', -1)
    end,
    lex_id = function(self)
      self:advance()
      self.start = self.pos
      while is_id_char(self.ch) do
        self:advance()
      end
      return self:make_token('id')
    end,
    lex_link = function(self)
      self:advance()
      self.start = self.pos
      while self.ch ~= '>' do
        if self.ch == '\0' then
          print('error: unterminated link')
          os.exit(1)
        end
        self:advance()
      end
      self:advance()
      self.start = self.start + 1
      return self:make_token_with_offset('link', -1)
    end,
    get_next_token = function(self)
      self:skip_whitespace()
      self.start = self.pos
      if self:is_done() then
        return nil
      end
      if is_term(self.ch) then
        self:advance()
        self.start = self.pos
        return self:make_token(self.source:sub(self.start, self.pos))
      elseif is_alpha(self.ch) then
        return self:lex_id()
      end
      local _exp_0 = self.ch
      if '\0' == _exp_0 then
        return nil
      elseif '"' == _exp_0 then
        return self:lex_str()
      elseif '<' == _exp_0 then
        return self:lex_link()
      else
        print("error: unexpected character `" .. self.ch .. "` (at " .. self.line .. ":" .. self.column .. ")")
        return os.exit(1)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, source)
      self.source = source
      self.pos = 0
      self.line = 1
      self.column = 1
      self.ch = self:peek()
      self.prev = nil
      self.start = 1
    end,
    __base = _base_0,
    __name = "Tokenizer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Tokenizer = _class_0
end
local Statement
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, id, params)
      self.id = id
      self.params = params
    end,
    __base = _base_0,
    __name = "Statement"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Statement = _class_0
end
local Parser
do
  local _class_0
  local _base_0 = {
    advance = function(self)
      self.prev = self.token
      self.token = self.tokenizer:get_next_token()
    end,
    accept = function(self, kind)
      if self.token == nil then
        return false
      end
      if self.token.kind == kind then
        self:advance()
        return true
      end
      return false
    end,
    expect = function(self, kind, msg)
      if not (self:accept(kind)) then
        print('error: ' .. msg)
        return os.exit(1)
      end
    end,
    parse = function(self)
      local statements = { }
      self:advance()
      while self:accept('[') do
        self:expect('id', 'expected identifier for macro invoke')
        local id = self.prev.text
        local params = { }
        if self:accept(':') then
          local depth = 1
          while true do
            if self.token.kind == '[' then
              depth = depth + 1
            elseif self.token.kind == ']' then
              depth = depth - 1
              if depth == 0 then
                break
              end
            end
            table.insert(params, self.token)
            self:advance()
          end
        end
        self:expect(']', 'expected closed bracket (`]`) to end statement')
        table.insert(statements, Statement(id, params))
      end
      return statements
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, tokenizer)
      self.tokenizer = tokenizer
      self.token = nil
      self.prev = nil
    end,
    __base = _base_0,
    __name = "Parser"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Parser = _class_0
end
local simple_element
simple_element = function(el, tokens)
  local html = '<' .. el .. '>'
  for _, token in ipairs(tokens) do
    html = html .. token.text
  end
  html = html .. ('</' .. el .. '>')
  return html
end
local compile_text = nil
local compile_str
compile_str = function(str, macros)
  local compiled_str = ''
  local ch = ''
  local prev = ''
  local prev_prev = ''
  local depth = 0
  local i = 1
  while i <= #str do
    ch = str:sub(i, i)
    if prev_prev ~= '\\' and prev == '$' and ch == '[' then
      compiled_str = compiled_str:sub(0, #compiled_str - 1)
      depth = depth + 1
      local e = '['
      i = i + 1
      while depth > 0 and i <= #str do
        ch = str:sub(i, i)
        if ch == '[' then
          depth = depth + 1
        elseif ch == ']' then
          depth = depth - 1
        end
        e = e .. ch
        i = i + 1
        prev_prev = prev
        prev = ch
        ch = str[i]
      end
      print('comp `' .. e .. '`  ch: ' .. ch)
      compiled_str = compiled_str .. compile_text(e, macros)
      compiled_str = compiled_str .. ch
    else
      compiled_str = compiled_str .. ch
    end
    i = i + 1
    prev_prev = prev
    prev = ch
    ch = str[i]
  end
  return compiled_str
end
compile_text = function(text, macros)
  local parser = Parser(Tokenizer(text))
  local html = ''
  for _, statement in ipairs(parser:parse()) do
    if macros[statement.id] == nil then
      local it = require('macros.' .. statement.id)
      macros[statement.id] = it
      if it == nil then
        print('error: unknown macro: ' .. statement.id)
        os.exit(1)
      end
    end
    for key, param in pairs(statement.params) do
      if param.kind == 'string' then
        statement.params[key].text = compile_str(param.text, macros)
      end
    end
    local m = macros[statement.id](statement.params)
    if not m then
      print('expected string from macro `' .. statement.id .. '` but got `' .. type(m) .. '`')
      os.exit(1)
    end
    html = html .. m
  end
  return html
end
local config = {
  lang = 'en'
}
local get_builtin_macros
get_builtin_macros = function()
  return {
    raw = function(t)
      return t[1].text
    end,
    begin = function(t)
      return '<' .. t[1].text .. '>'
    end,
    ["end"] = function(t)
      return '</' .. t[1].text .. '>'
    end,
    config = function(t)
      config[t[1].text] = t[2].text
      return ''
    end,
    h1 = function(t)
      return simple_element('h1', t)
    end,
    h2 = function(t)
      return simple_element('h2', t)
    end,
    h3 = function(t)
      return simple_element('h3', t)
    end,
    h4 = function(t)
      return simple_element('h4', t)
    end,
    h5 = function(t)
      return simple_element('h5', t)
    end,
    h6 = function(t)
      return simple_element('h6', t)
    end,
    p = function(t)
      return simple_element('p', t)
    end,
    span = function(t)
      return simple_element('span', t)
    end,
    b = function(t)
      return simple_element('b', t)
    end,
    strong = function(t)
      return simple_element('strong', t)
    end,
    i = function(t)
      return simple_element('i', t)
    end,
    em = function(t)
      return simple_element('em', t)
    end,
    li = function(t)
      return simple_element('li', t)
    end,
    code = function(t)
      return simple_element('code', t)
    end,
    summary = function(t)
      return simple_element('summary', t)
    end,
    th = function(t)
      return simple_element('th', t)
    end,
    td = function(t)
      return simple_element('td', t)
    end,
    title = function(t)
      return simple_element('title', t)
    end,
    a = function(t)
      return '<a href="' .. t[2].text .. '">' .. t[1].text .. '</a>'
    end,
    hr = function(t)
      return '<hr/>'
    end,
    br = function(t)
      return '<br/>'
    end
  }
end
local compile
compile = function(file)
  require('conf')
  file = io.open(file)
  local source = file:read('*all')
  file:close()
  local macros = get_builtin_macros()
  local text = compile_text(source, macros)
  return '<DOCTYPE html><html lang="' .. config.lang .. '">' .. text .. '</html>'
end
return {
  is_term = is_term,
  is_alpha = is_alpha,
  is_id_char = is_id_char,
  TokenKind = TokenKind,
  Token = Token,
  Tokenizer = Tokenizer,
  Statement = Statement,
  Parser = Parser,
  simple_element = simple_element,
  compile_text = compile_text,
  compile_str = compile_str,
  config = config,
  get_builtin_macros = get_builtin_macros,
  compile = compile
}
