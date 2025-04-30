(fn _panic [msg]
  (print (.. "error: " msg))
  (os.exit 1))

(fn [tokens]
  "Creates a navigation bar. Syntax:
  [nav: \"Link Text\" </link/url> \"Another link text\" </another/link/url>]"

  (each [i t (ipairs tokens)]
    (print i " " t.text))

  (var html "<nav>")
  (var i 1)
  (var token tokens.1)

  (while (<= i (# tokens))
    (set token (. tokens i))
    (set i (+ i 1))
    (print token.kind " " token.text)
    (if (= token.kind "string")
      (let [text token.text]
        (set token (. tokens i))
        (set i (+ i 1))
        (print token.kind " " token.text)
        (if (= token.kind "link")
          (set html (.. html "<a href=\"" token.text "\">" text "</a>"))
          (_panic (.. "error: expected link but got " token.kind " (text: `" token.text "`)"))))
      (_panic (.. "error: expected string but got " token.kind " (text: `" token.text "`)"))))

  (.. html "</nav>")

  html)
