package = "seal"
version = "dev-1"

source = {
   url = "git+https://github.com/EmmaTheMartian/seal.git"
}

description = {
   summary = "A metaprogrammable markup language designed for making simple websites.",
   homepage = "https://github.com/EmmaTheMartian/seal",
   maintainer = "EmmaTheMartian <emmathemartian@gmail.com>",
   license = "MIT",
   labels = {
      "seal",
      "html",
      "moonscript"
   }
}

dependencies = {
   "lua >= 5.1",
   "moonscript"
}

build = {
   type = "command",
   build_command = "moonc src/main.moon"
   modules = {
      ["seal"] = "src/main.lua"
   },
   install = {
      bin = { "bin/seal" }
   }
}
