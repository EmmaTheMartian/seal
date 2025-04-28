(fn [tokens]
  "Creates a navigation bar. Syntax:
  [nav: \"Link Text\" </link/url> \"Another link text\" </another/link/url>]"

  (var html "<nav>")
  (var i 0)
  (var token nil)

  (while (~= i (# tokens))
    (set token (. tokens i))
    (if (= token.kind "string")
      (let [text token.text]
        (set i (+ i 1)) ; increment index so we can get the link token
        (set token (. tokens i))
        (if (= token.kind "link")
          (set html (.. html "<a href=\"" token.text "\">" text "</a>"))))
      (print (.. "error: expected string but got " token.kind " (text: " token.text ")"))))

  (.. html "</nav>")

  html)
