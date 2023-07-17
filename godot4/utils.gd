extends Node


static func text_to_value(text):
	pass
	var intRegex = RegEx.new()
	intRegex.compile("^-?[0-9]+$")
	if intRegex.search(text):
		return int(text)

	var floatRegex = RegEx.new()
	floatRegex.compile("^-?[0-9]*\\.[0-9]+$")
	if floatRegex.search(text):
		return float(text)

	if text.length() > 0:
		# return text as string
		return text
	
	return null
