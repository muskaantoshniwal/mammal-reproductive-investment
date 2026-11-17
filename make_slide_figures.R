# makes the 4 graphs for the slides
# hit Source -> a Finder window pops up -> pick mammals.db
# the png files save in the same folder as mammals.db

if (!require(RSQLite)) install.packages("RSQLite")
if (!require(ggplot2)) install.packages("ggplot2")
library(RSQLite)
library(ggplot2)

# colors for each diet group (same on every graph)
diet_colors <- c("Herbivores" = "#2a7f62", "Omnivores" = "#c9a227", "Carnivores" = "#b23a48",
                 "Vertebrate-eaters" = "#b23a48")

# simple black-and-white style with Times font to match the slides
my_theme <- theme_classic(base_size = 16, base_family = "Times") +
  theme(legend.position = "bottom")

# pick the database, and save pictures next to it
db_file <- file.choose()
setwd(dirname(db_file))

# ---------- GRAPH 1 (slide 2): H1 vs H2, made-up lines ----------
x <- seq(0, 6, length.out = 50)
make_lines <- function(hyp, slopes, starts) {
  data.frame(hyp = hyp,
             diet = rep(c("Herbivores", "Omnivores", "Carnivores"), each = length(x)),
             mass = rep(x, 3),
             litter = c(starts[1] + slopes[1] * x, starts[2] + slopes[2] * x, starts[3] + slopes[3] * x))
}
hyp <- rbind(
  # H1: carnivores steepest, then omnivores, then herbivores
  make_lines("H1: Hunting costs", slopes = c(-0.08, -0.13, -0.19), starts = c(0.75, 0.8, 0.85)),
  # H2: herbivores highest (reliable food), carnivores lowest, same slope (parallel)
  make_lines("H2: Food availability", slopes = c(-0.12, -0.12, -0.12), starts = c(1.0, 0.8, 0.6))
)
hyp$diet <- factor(hyp$diet, levels = c("Herbivores", "Omnivores", "Carnivores"))

graph1 <- ggplot(hyp, aes(mass, litter, color = diet)) +
  geom_line(linewidth = 1.6) +
  facet_wrap(~hyp) +
  scale_color_manual(values = diet_colors) +
  labs(x = "log body mass", y = "log litter size", color = NULL,
       caption = "Hypothetical predictions, not real data") +
  my_theme +
  theme(strip.background = element_blank(), strip.text = element_text(face = "bold", size = 16),
        axis.text = element_blank(), axis.ticks = element_blank())
ggsave("graph1_hypotheses.png", graph1, width = 10, height = 4.5, dpi = 200)

# ---------- pull real data out of the database with a JOIN ----------
con <- dbConnect(SQLite(), db_file)
mydata <- dbGetQuery(con, "
  SELECT t.species_name, d.diet, t.adult_mass_g, t.litter_size_n, t.neonate_mass_g,
         t.prop_investment, t.log10_mass, t.log10_prop_investment, t.placental, d.diet_detailed
  FROM species_traits t
  JOIN species_diet d ON t.species_id = d.species_id
")
dbDisconnect(con)

# ---------- GRAPH 2 (slide 4): two species, two different stories ----------
two <- subset(mydata, species_name %in% c("Ursus americanus", "Odocoileus virginianus"))
two$common <- ifelse(two$species_name == "Ursus americanus", "American black bear", "White-tailed deer")
print(two[, c("common", "adult_mass_g", "litter_size_n", "neonate_mass_g", "prop_investment")])

bars <- rbind(
  data.frame(common = two$common, measure = "Litter size (babies per litter)", value = two$litter_size_n),
  data.frame(common = two$common, measure = "Relative litter mass (% of mother's mass)", value = two$prop_investment * 100)
)
graph2 <- ggplot(bars, aes(common, value)) +
  geom_col(fill = "grey40", width = 0.6) +
  geom_text(aes(label = round(value, 1)), vjust = -0.4, size = 6, family = "Times") +
  facet_wrap(~measure, scales = "free_y") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = NULL, y = NULL) +
  my_theme +
  theme(strip.background = element_blank(), strip.text = element_text(face = "bold", size = 15))
ggsave("graph2_two_species.png", graph2, width = 10, height = 4.5, dpi = 200)

# ---------- GRAPH 3 (slide 5): real results ----------
res <- subset(mydata, placental == "Y" & !is.na(log10_prop_investment) &
                diet_detailed %in% c("herbivore", "carnivore_vertebrate"))
res$diet <- ifelse(res$diet_detailed == "herbivore", "Herbivores", "Vertebrate-eaters")
print(table(res$diet))   # should be 393 herbivores, 73 vertebrate-eaters

# axes show real units, on a log10 scale (same data and lines as before)
mass_breaks <- c(1, 10, 100, 1000, 1e4, 1e5, 1e6, 1e7, 1e8)
mass_labels <- c("1 g", "10 g", "100 g", "1 kg", "10 kg", "100 kg", "1,000 kg", "10,000 kg", "100,000 kg")

graph3 <- ggplot(res, aes(adult_mass_g, prop_investment, color = diet)) +
  geom_point(alpha = 0.45, size = 2) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.6, formula = y ~ x) +
  scale_color_manual(values = diet_colors) +
  scale_x_log10(breaks = mass_breaks, labels = mass_labels) +
  scale_y_log10(breaks = c(0.001, 0.01, 0.1, 1), labels = c("0.001", "0.01", "0.1", "1")) +
  labs(x = "Adult body mass (log10 scale)",
       y = "Relative litter mass (log10 scale)", color = NULL) +
  my_theme
ggsave("graph3_results.png", graph3, width = 8, height = 5.5, dpi = 200)


# ---------- GRAPH 4 (results slide): litter size vs body mass, all species ----------
lit <- subset(mydata, diet_detailed %in% c("herbivore", "omnivore", "carnivore_invertebrate", "carnivore_vertebrate"))
lit$group <- factor(lit$diet_detailed,
  levels = c("herbivore", "omnivore", "carnivore_invertebrate", "carnivore_vertebrate"),
  labels = c("Herbivores", "Omnivores", "Invertebrate-eaters", "Vertebrate-eaters"))
lit_colors <- c("Herbivores" = "#2a7f62", "Omnivores" = "#c9a227", "Invertebrate-eaters" = "#4f74b8", "Vertebrate-eaters" = "#b23a48")

# slope of log litter size vs log body mass for each group
for (g in levels(lit$group)) {
  fit <- lm(log10(litter_size_n) ~ log10_mass, data = subset(lit, group == g))
  cat(g, ": n =", sum(lit$group == g), " slope =", round(coef(fit)[2], 3), "\n")
}
# do the slopes differ across the 4 diet groups? (interaction test, not PGLS yet) -> F ~ 25.4
lit$group <- relevel(lit$group, "Herbivores")
print(anova(lm(log10(litter_size_n) ~ log10_mass + group, data = lit),
            lm(log10(litter_size_n) ~ log10_mass * group, data = lit)))

graph4 <- ggplot(lit, aes(adult_mass_g, litter_size_n, color = group)) +
  geom_point(alpha = 0.25, size = 1.4) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.6, formula = y ~ x) +
  scale_color_manual(values = lit_colors) +
  scale_x_log10(breaks = mass_breaks[c(1, 3, 5, 7, 9)], labels = mass_labels[c(1, 3, 5, 7, 9)]) +
  scale_y_log10(breaks = c(1, 2, 4, 8, 16)) +
  labs(x = "Adult body mass (log10 scale)",
       y = "Number of young per litter (log10 scale)", color = NULL) +
  my_theme
ggsave("graph4_litter_size.png", graph4, width = 8, height = 5.5, dpi = 200)

cat("done - 4 graphs saved in:", getwd(), "\n")
