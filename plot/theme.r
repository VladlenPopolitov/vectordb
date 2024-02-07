theme_black = function(base_size = 12, base_family = "") {
  theme_grey(base_size = base_size, base_family = base_family) %+replace%
    theme(
      # Specify axis options
      axis.line = element_blank(),
      axis.text.x = element_text(size = base_size*0.8, color = "white", lineheight = 0.9),
      axis.text.y = element_text(size = base_size*0.8, color = "white", lineheight = 0.9),
      axis.ticks = element_line(color = "white", size  =  0.2),
      axis.title.x = element_text(size = base_size, color = "white", margin = margin(0, 10, 0, 0)),
      axis.title.y = element_text(size = base_size, color = "white", angle = 90, margin = margin(0, 10, 0, 0)),
      axis.ticks.length = unit(0.3, "lines"),
      # Specify legend options
      legend.background = element_rect(color = NA, fill = "black"),
      legend.key = element_rect(color = "white",  fill = "black"),
      legend.key.size = unit(1.2, "lines"),
      legend.key.height = NULL,
      legend.key.width = NULL,
      legend.text = element_text(size = base_size * 0.8, color = "white"),
      legend.title = element_text(size = base_size * 0.8, face = "bold", hjust = 0, color = "white"),
      legend.position = "right",
      legend.text.align = NULL,
      legend.title.align = NULL,
      legend.direction = "vertical",
      legend.box = NULL,
      # Specify panel options
      panel.background = element_rect(fill = "black", color  =  NA),
      panel.border = element_rect(fill = NA, color = "white"),
      panel.grid.major = element_line(color = "grey35"),
      panel.grid.minor = element_line(color = "grey20"),
      panel.margin = unit(1.0, "lines"),
      # Specify facetting options
      strip.background = element_rect(fill = "grey30", color = "grey10"),
      strip.text.x = element_text(size = base_size * 0.9, color = "white", face = "bold"),
      strip.text.y = element_text(size = base_size * 0.9, color = "white", angle = -90),
      # Specify plot options
      plot.background = element_rect(color = "black", fill = "black"),
      plot.title = element_text(size = base_size*1.2, color = "white",
                                margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "lines")),
      plot.margin = unit(rep(1, 4), "lines")
    )
}

theme_title_mono <-
  theme(plot.title = element_text(family='mono', face="bold", size=20))

theme_legend <-
  theme(legend.text = element_text(size=12),
        axis.text.x = element_text(size=11))

base_size <- 28
point_size <- 6.5
line_size <- 2.0

theme_set(
  #  theme_bw(base_size = base_size) +
  theme_black(base_size = base_size) +
    theme(panel.grid.major = element_line(size = 1),
          legend.text = element_text(size = base_size),
          axis.text.x = element_text(size = base_size * 0.8),
          legend.key.size = unit(1.5, "cm"),          
          legend.key = element_rect(color='#000000', fill = '#444444')))

