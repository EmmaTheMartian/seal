return function(tokens)
	local html = "<div class='thingy'>"
	for _, token in ipairs(tokens) do
		html = html .. token.text
	end
	html = html .. "</div>"
	return html
end