local active_border_color = "rgb(c5c9c5)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
    },
  },
})

-- Kanagawa Dragon backdrop is dark; terminals can breathe a little.
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.92 0.85" })
