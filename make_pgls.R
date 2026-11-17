# PGLS: same models as Results 1 and 2, but accounting for relatedness between species
# Why: closely related species have similar traits, so they are not independent data points.
#      PGLS uses the mammal family tree (PHYLACINE 1.2) to correct for this.
#
# Put this script, mammals.db and Complete_phylogeny.nex in the same folder, hit Source,
# and pick mammals.db when the window pops up.
# Download Complete_phylogeny.nex (132 MB) from:
# https://github.com/MegaPast2Future/PHYLACINE_1.2/blob/master/Data/Phylogenies/Complete_phylogeny.nex
# (click the download button on that page)
#
# Saves: pgls_results.csv

if (!require(RSQLite)) install.packages("RSQLite")
if (!require(ape)) install.packages("ape")
if (!require(phylolm)) install.packages("phylolm")
library(RSQLite)
library(ape)
library(phylolm)

db_file <- file.choose()
setwd(dirname(db_file))

# ---------- load data ----------
con <- dbConnect(SQLite(), db_file)
mydata <- dbGetQuery(con, "
  SELECT t.*, d.diet_detailed
  FROM species_traits t
  JOIN species_diet d ON t.species_id = d.species_id
  WHERE d.diet_detailed != 'carnivore_unknown'
")
dbDisconnect(con)

# herbivores first, so every other group is compared with herbivores
mydata$group <- factor(mydata$diet_detailed,
  levels = c("herbivore", "omnivore", "carnivore_invertebrate", "carnivore_vertebrate"),
  labels = c("Herbivores", "Omnivores", "Invertebrate-eaters", "Vertebrate-eaters"))
mydata$log_litter <- log10(mydata$litter_size_n)

# ---------- load the tree ----------
# PHYLACINE gives 1000 possible trees (uncertainty in how species are related); I use tree 1
cat("reading tree file (takes about 10-30 seconds)...\n")
trees <- read.nexus("Complete_phylogeny.nex")
tree <- trees[[1]]

# phylolm matches species by row names = tree tip names
rownames(mydata) <- mydata$tree_tip
cat("species in my data that are on the tree:", sum(mydata$tree_tip %in% tree$tip.label),
    "of", nrow(mydata), "\n")

results <- data.frame()
add_rows <- function(fit, model_name, n) {
  s <- summary(fit)$coefficients
  results <<- rbind(results, data.frame(
    model = model_name, term = rownames(s),
    estimate = round(s[, "Estimate"], 3), p_value = signif(s[, "p.value"], 2),
    lambda = round(fit$optpar, 2), n_species = n, row.names = NULL))
}

# ---------- PGLS 1: litter size (Results 1) ----------
# lambda = how much related species resemble each other (0 = not at all, 1 = fully as expected from the tree)
d1 <- mydata[mydata$tree_tip %in% tree$tip.label, ]
t1 <- keep.tip(tree, d1$tree_tip)

# do slopes differ by diet? (H1) -> compare models with and without the interaction
fit_slopes <- phylolm(log_litter ~ log10_mass * group, data = d1, phy = t1, model = "lambda")
fit_same   <- phylolm(log_litter ~ log10_mass + group, data = d1, phy = t1, model = "lambda")
lr <- 2 * (fit_slopes$logLik - fit_same$logLik)
p_slopes <- pchisq(lr, df = 3, lower.tail = FALSE)

cat("\n===== PGLS 1: litter size =====\n")
cat("lambda =", round(fit_slopes$optpar, 2), "\n")
print(summary(fit_slopes))
cat("Do slopes differ by diet? likelihood ratio test p =", signif(p_slopes, 2), "\n")
print(summary(fit_same))
cat("Vertebrate-eaters vs herbivores at the same body mass:",
    round(10^coef(fit_same)["groupVertebrate-eaters"], 2), "x litter size\n")
add_rows(fit_slopes, "Litter size: different slopes", nrow(d1))
add_rows(fit_same, "Litter size: same slope", nrow(d1))
results <- rbind(results, data.frame(model = "Litter size", term = "Do slopes differ? (likelihood ratio test)",
  estimate = NA, p_value = signif(p_slopes, 2), lambda = NA, n_species = nrow(d1)))

# ---------- PGLS 2: relative litter mass (Results 2), placentals, vertebrate-eaters vs herbivores ----------
d2 <- subset(d1, placental == "Y" & !is.na(log10_prop_investment) &
                 group %in% c("Herbivores", "Vertebrate-eaters"))
d2$group <- droplevels(d2$group)
t2 <- keep.tip(tree, d2$tree_tip)

fit2_slopes <- phylolm(log10_prop_investment ~ log10_mass * group, data = d2, phy = t2, model = "lambda")
fit2_same   <- phylolm(log10_prop_investment ~ log10_mass + group, data = d2, phy = t2, model = "lambda")

cat("\n===== PGLS 2: relative litter mass =====\n")
print(summary(fit2_slopes))
print(summary(fit2_same))
cat("Vertebrate-eaters vs herbivores at the same body mass:",
    round(10^coef(fit2_same)["groupVertebrate-eaters"], 2), "x relative litter mass\n")
add_rows(fit2_slopes, "Relative litter mass: different slopes", nrow(d2))
add_rows(fit2_same, "Relative litter mass: same slope", nrow(d2))

# ---------- check: does the answer depend on which tree I use? ----------
# rerun the vertebrate-eater vs herbivore litter size difference on 10 different trees
cat("\nrunning on 10 trees (takes a minute)...\n")
check <- sapply(1:10, function(i) {
  ti <- keep.tip(trees[[i]], d1$tree_tip)
  f <- phylolm(log_litter ~ log10_mass + group, data = d1, phy = ti, model = "lambda")
  c(times = 10^unname(coef(f)["groupVertebrate-eaters"]),
    p = summary(f)$coefficients["groupVertebrate-eaters", "p.value"])
})
print(round(t(check), 4))
cat("across 10 trees: vertebrate-eaters have", round(min(check["times", ]), 2), "to",
    round(max(check["times", ]), 2), "x more young; largest p =", signif(max(check["p", ]), 2), "\n")

write.csv(results, "pgls_results.csv", row.names = FALSE)
cat("done - saved in:", getwd(), "\n")
