rockspec_format = "3.0"
package = "seal"
version = "dev-1"

source = {
   url = "git+https://github.com/EmmaTheMartian/seal.git",
}

description = {
   summary = "A metaprogrammable markup language designed for making simple websites.",
   homepage = "https://github.com/EmmaTheMartian/seal",
   maintainer = "EmmaTheMartian <emmathemartian@gmail.com>",
   license = "MIT",
   labels = {
      "seal",
      "html",
      "moonscript",
   },
}

dependencies = {
   "lua >= 5.1",
   "argparse",
   "moonscript",
}

build = {
   type = "builtin",
   modules = {
      seal = "src/seal.lua",
   },
   install = {
      bin = { "bin/seal" },
   },
}
