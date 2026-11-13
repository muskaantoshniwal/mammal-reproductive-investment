# Week 11 add-on: femur data + t-tests
# Put this script, mammals.db and femur_data.csv in the same folder, hit Source,
# and pick mammals.db when the Finder window pops up.
# Saves: graph5_mass_check.png, graph6_femur_litter.png, ttest_results.csv

if (!require(RSQLite)) install.packages("RSQLite")
if (!require(ggplot2)) install.packages("ggplot2")
library(RSQLite)
library(ggplot2)

db_file <- file.choose()
setwd(dirname(db_file))

my_theme <- theme_classic(base_size = 16, base_family = "Times") +
  theme(legend.position = "bottom")
diet_colors <- c("Herbivores" = "#2a7f62", "Omnivores" = "#c9a227",
                 "Invertebrate-eaters" = "#4f74b8", "Vertebrate-eaters" = "#b23a48")

# ---------- load data ----------
con <- dbConnect(SQLite(), db_file)
mydata <- dbGetQuery(con, "
  SELECT t.*, d.diet_detailed, d.diet_interpolated
  FROM species_traits t
  JOIN species_diet d ON t.species_id = d.species_id
  WHERE d.diet_detailed != 'carnivore_unknown'
")
dbDisconnect(con)

mydata$group <- factor(mydata$diet_detailed,
  levels = c("herbivore", "omnivore", "carnivore_invertebrate", "carnivore_vertebrate"),
  labels = c("Herbivores", "Omnivores", "Invertebrate-eaters", "Vertebrate-eaters"))
mydata$log_litter <- log10(mydata$litter_size_n)

# femur measurements (Campione & Evans 2012), already matched to species_id
femur <- read.csv("femur_data.csv")
fem <- merge(femur, mydata, by = c("species_id", "species_name"))
cat("species with femur data:", nrow(fem), "\n")
print(table(fem$group))

results <- data.frame()   # collects every t-test for the csv
add_result <- function(test_name, groups, r) {
  results <<- rbind(results, data.frame(
    test = test_name, comparison = groups,
    mean_difference = round(unname(r$estimate[1] - ifelse(length(r$estimate) > 1, r$estimate[2], 0)), 3),
    t = round(unname(r$statistic), 2), df = round(unname(r$parameter), 1),
    p_value = signif(r$p.value, 2)))
}

# ---------- PART 1: is my body mass data right? ----------
# compare database adult mass (COMBINE) with the mass of the measured museum specimen
# paired t-test on log10 mass: same species, 2 sources
fem$log_db_mass <- log10(fem$adult_mass_g)
fem$log_specimen_mass <- log10(fem$specimen_mass_g)
check <- t.test(fem$log_db_mass, fem$log_specimen_mass, paired = TRUE)
print(check)
print(cor.test(fem$log_db_mass, fem$log_specimen_mass))
cat("database mass is on average", round(10^mean(fem$log_db_mass - fem$log_specimen_mass), 2),
    "x the specimen mass\n")
add_result("Paired t-test: body mass check", "COMBINE mass vs specimen mass (log10)", check)

graph5 <- ggplot(fem, aes(log_specimen_mass, log_db_mass)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey40") +
  geom_point(alpha = 0.6, size = 2) +
  labs(x = "log10 specimen body mass (g), Campione & Evans 2012",
       y = "log10 adult body mass (g), my database",
       caption = "Dashed line = perfect agreement") +
  my_theme
ggsave("graph5_mass_check.png", graph5, width = 7, height = 5.5, dpi = 200)

# ---------- PART 2: does the result hold with femur size instead of body mass? ----------
fem3 <- subset(fem, group %in% c("Herbivores", "Omnivores", "Vertebrate-eaters"))
fem3$group <- droplevels(fem3$group)
fem3$log_fc <- log10(fem3$femur_circumference_mm)

# how well does femur circumference predict body mass?
print(summary(lm(log_db_mass ~ log_fc, data = fem3)))

# slopes of litter size vs femur circumference by diet
for (g in levels(fem3$group)) {
  fit <- lm(log_litter ~ log_fc, data = subset(fem3, group == g))
  cat(g, ": n =", sum(fem3$group == g), " slope =", round(coef(fit)[2], 3), "\n")
}
# do slopes differ? (interaction)
print(anova(lm(log_litter ~ log_fc + group, data = fem3),
            lm(log_litter ~ log_fc * group, data = fem3)))
print(summary(lm(log_litter ~ log_fc * group, data = fem3)))
# difference in litter size at the same femur size
same_slope <- lm(log_litter ~ log_fc + group, data = fem3)
print(summary(same_slope))
cat("vertebrate-eaters vs herbivores at same femur size:",
    round(10^coef(same_slope)["groupVertebrate-eaters"], 2), "x litter size\n")

graph6 <- ggplot(fem3, aes(log_fc, log_litter, color = group)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.4) +
  scale_color_manual(values = diet_colors) +
  labs(x = "log10 femur circumference (mm)", y = "log10 litter size", color = NULL,
       subtitle = paste0(nrow(fem3), " species with femur data")) +
  my_theme
ggsave("graph6_femur_litter.png", graph6, width = 8, height = 5.5, dpi = 200)

# ---------- PART 3: t-tests on size-corrected traits (all species) ----------
# step 1: remove the effect of body mass (residuals from one line through all species)
# step 2: Welch t-test on those residuals between two groups
mydata$res_litter <- resid(lm(log_litter ~ log10_mass, data = mydata))
welch <- function(g1, g2, label) {
  r <- t.test(mydata$res_litter[mydata$group == g1], mydata$res_litter[mydata$group == g2])
  print(r); add_result("Welch t-test: size-corrected litter size", label, r)
}
welch("Vertebrate-eaters", "Herbivores", "Vertebrate-eaters vs herbivores")
welch("Invertebrate-eaters", "Herbivores", "Invertebrate-eaters vs herbivores")
welch("Omnivores", "Herbivores", "Omnivores vs herbivores")

plac <- subset(mydata, placental == "Y" & !is.na(log10_prop_investment))
plac$res_rel <- resid(lm(log10_prop_investment ~ log10_mass, data = plac))
r <- t.test(plac$res_rel[plac$group == "Vertebrate-eaters"], plac$res_rel[plac$group == "Herbivores"])
print(r); add_result("Welch t-test: size-corrected relative litter mass", "Vertebrate-eaters vs herbivores", r)

# ---------- PART 4: do my estimated values bias things? ----------
r <- t.test(mydata$res_litter[mydata$litter_measured == "N"], mydata$res_litter[mydata$litter_measured == "Y"])
print(r); add_result("Welch t-test: data check", "Litter size not measured vs measured", r)
r <- t.test(mydata$res_litter[mydata$diet_interpolated %in% "Y"], mydata$res_litter[mydata$diet_interpolated %in% "N"])
print(r); add_result("Welch t-test: data check", "Diet estimated vs observed", r)

# same vertebrate-eater vs herbivore test, leaving out estimated diets
obs <- subset(mydata, diet_interpolated %in% "N")
r <- t.test(obs$res_litter[obs$group == "Vertebrate-eaters"], obs$res_litter[obs$group == "Herbivores"])
print(r); add_result("Welch t-test: size-corrected litter size (observed diets only)", "Vertebrate-eaters vs herbivores", r)

write.csv(results, "ttest_results.csv", row.names = FALSE)
print(results)
cat("done - files saved in:", getwd(), "\n")
