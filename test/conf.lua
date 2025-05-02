-- Add searchers so that we can use Fennel and Moonscript with Seal
require("fennel").install()
require("moonscript")

-- Return a table of pages to compile
return {
	["index.seal"] = "index.html",
	["other.seal"] = "other/index.html",
}
