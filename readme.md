<div align='center'>

# Seal

[luarocks](https://luarocks.org/modules/emmathemartian/seal)

---

</div>

A meta-programmable markup language designed for making stylish and simple
static sites.

Seal bases around creating macros which process literal tokens and write HTML.

## Installation

```sh
# Release builds
luarocks install seal

# Development builds
luarocks install --server=https://luarocks.org/dev seal
```

## Developers

Don't edit `src/seal.lua`, this file is compiled by Moonscript.

Make sure to recompile `seal.moon` before committing:

```sh
moonc src/seal.moon
```
