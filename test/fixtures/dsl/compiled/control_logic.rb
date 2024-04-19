->() {
  __buffer__ << "<body><p>foo</p>"
    if true
      __buffer__ << "<p>bar</p>"
    end
  __buffer__ << "</body>"
}
