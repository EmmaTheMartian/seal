(tokens) ->
	html = '<p class=\'bozo\'>'
	for _, token in ipairs tokens
		html ..= token.text
	html ..= '</p>'
	return html
