# week 9 plots - pulls data straight out of mammals.db with a JOIN, then plots it
# just hit Source (top right). a Finder window pops up -> pick mammals.db

# install packages if missing (only happens the first time)
if (!require(RSQLite)) install.packages("RSQLite")
if (!require(ggplot2)) install.packages("ggplot2")
library(RSQLite)
library(ggplot2)

# pick the database file
db_file <- file.choose()
con <- dbConnect(SQLite(), db_file)

# check the tables are there - should say species_diet, species_traits
print(dbListTables(con))

# JOIN the two tables on species_id so every species has body size + diet together
mydata <- dbGetQuery(con, "
  SELECT t.species_name, t.taxon_order, t.log10_mass, t.litter_size_n,
         t.log10_prop_investment, t.placental, d.diet_detailed
  FROM species_traits t
  JOIN species_diet d ON t.species_id = d.species_id
")
dbDisconnect(con)

# should say 3443 7
print(dim(mydata))

# drop the 38 carnivores with unknown prey type, and put diets in a sensible order
mydata <- subset(mydata, diet_detailed != "carnivore_unknown")
mydata$diet_detailed <- factor(mydata$diet_detailed,
  levels = c("herbivore", "omnivore", "carnivore_invertebrate", "carnivore_vertebrate"),
  labels = c("Herbivore", "Omnivore", "Invertebrate-eating carnivore", "Vertebrate-eating carnivore"))

# colors for each diet group
diet_colors <- c("Herbivore" = "#2a7f62", "Omnivore" = "#c9a227",
                 "Invertebrate-eating carnivore" = "#5b7fbf",
                 "Vertebrate-eating carnivore" = "#b23a48")

# ---- PLOT 1: the key plot - proportional investment vs body size ----
# only placental species with newborn mass (marsupials have tiny newborns, so they'd skew it)
invest <- subset(mydata, placental == "Y" & !is.na(log10_prop_investment))
print(table(invest$diet_detailed))   # how many species per diet group

plot1 <- ggplot(invest, aes(x = log10_mass, y = log10_prop_investment, color = diet_detailed)) +
  geom_point(alpha = 0.35, size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.2) +   # one regression line per diet
  scale_color_manual(values = diet_colors) +
  labs(x = "log10 adult body mass (g)",
       y = "log10 proportional litter investment\n(litter size x newborn mass / adult mass)",
       color = "Diet",
       title = "Does diet change how litter investment scales with body size?",
       subtitle = paste0("Placental mammals with newborn mass data (n = ", nrow(invest), ")")) +
  theme_classic()
print(plot1)
ggsave("plot1_prop_investment.png", plot1, width = 8, height = 5, dpi = 300)

# ---- PLOT 2: backup plot - litter size vs body size, all species ----
plot2 <- ggplot(mydata, aes(x = log10_mass, y = log10(litter_size_n), color = diet_detailed)) +
  geom_point(alpha = 0.25, size = 1.2) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.2) +
  scale_color_manual(values = diet_colors) +
  labs(x = "log10 adult body mass (g)",
       y = "log10 litter size",
       color = "Diet",
       title = "Litter size vs body size across mammals",
       subtitle = paste0("All species (n = ", nrow(mydata), ")")) +
  theme_classic()
print(plot2)
ggsave("plot2_litter_size.png", plot2, width = 8, height = 5, dpi = 300)

# quick check of the slopes for each diet (the steepness of each line)
for (g in levels(invest$diet_detailed)) {
  fit <- lm(log10_prop_investment ~ log10_mass, data = subset(invest, diet_detailed == g))
  cat(g, ": slope =", round(coef(fit)[2], 3), "\n")
}

# the two png files save in whatever folder R is currently pointed at:
cat("plots saved in:", getwd(), "\n")
