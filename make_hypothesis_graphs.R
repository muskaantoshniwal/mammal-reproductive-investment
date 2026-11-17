# 3 separate prediction graphs for the Hypotheses slide (H1, H2, Null)
# Hit Source. Saves graph_H1.png, graph_H2.png, graph_null.png in the same folder as this script
# (or your working directory). These are made-up lines showing each prediction, not real data.

if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)

diet_colors <- c("Herbivores" = "#2a7f62", "Omnivores" = "#c9a227", "Vertebrate-eaters" = "#b23a48")
x <- seq(0, 1, length.out = 50)

# each prediction = a start (intercept) and a slope for each diet group
make_lines <- function(starts, slopes) {
  do.call(rbind, lapply(names(diet_colors), function(g)
    data.frame(x = x, y = starts[g] + slopes[g] * x, group = g)))
}

draw <- function(d, title, file, linetypes = c("solid", "solid", "solid")) {
  d$group <- factor(d$group, levels = names(diet_colors))
  p <- ggplot(d, aes(x, y, color = group, linetype = group)) +
    geom_line(linewidth = 1.8) +
    scale_color_manual(values = diet_colors) +
    scale_linetype_manual(values = setNames(linetypes, names(diet_colors))) +
    coord_cartesian(ylim = c(0, 1.15)) +
    labs(title = title, x = "Body mass (log scale)", y = "Litter size (log scale)",
         color = NULL, linetype = NULL) +
    theme_classic(base_size = 17) +
    theme(axis.text = element_blank(), axis.ticks = element_blank(),
          plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
          legend.position = "bottom", legend.text = element_text(size = 12), legend.margin = margin(0, 0, 0, 0),
          legend.key.width = unit(0.9, "cm"), plot.title.position = "plot")
  ggsave(file, p, width = 6, height = 4.6, dpi = 250, bg = "white")
}

# H1: lines start together, vertebrate-eaters drop fastest (steeper slope)
draw(make_lines(starts = c(Herbivores = 0.95, Omnivores = 0.97, `Vertebrate-eaters` = 1.0),
                slopes = c(Herbivores = -0.40, Omnivores = -0.60, `Vertebrate-eaters` = -0.90)),
     "H1: Steeper slope in vertebrate-eaters", "graph_H1.png")

# H2: same slope (parallel), herbivores highest
draw(make_lines(starts = c(Herbivores = 1.05, Omnivores = 0.85, `Vertebrate-eaters` = 0.65),
                slopes = c(Herbivores = -0.55, Omnivores = -0.55, `Vertebrate-eaters` = -0.55)),
     "H2: Same slope, herbivores higher", "graph_H2.png")

# Null: one shared line (dashed lines so all 3 colors stay visible on top of each other)
draw(make_lines(starts = c(Herbivores = 0.85, Omnivores = 0.85, `Vertebrate-eaters` = 0.85),
                slopes = c(Herbivores = -0.55, Omnivores = -0.55, `Vertebrate-eaters` = -0.55)),
     "Null: Same slope, same height", "graph_null.png",
     linetypes = c("solid", "42", "12"))

cat("done - saved graph_H1.png, graph_H2.png, graph_null.png in:", getwd(), "\n")
