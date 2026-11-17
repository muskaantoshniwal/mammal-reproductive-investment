# Confounder t-tests: young per year, pregnancy length, nursing length
# Question: at the same body size, do vertebrate-eaters and herbivores differ?
# Put this script and mammals.db in the same folder, hit Source,
# and pick mammals.db when the window pops up.
# Saves: confounder_ttests.csv

if (!require(RSQLite)) install.packages("RSQLite")
if (!require(PNC)) install.packages("PNC")
library(RSQLite)
library(PNC)

db_file <- file.choose()
setwd(dirname(db_file))

# ---------- load my database ----------
con <- dbConnect(SQLite(), db_file)
mydata <- dbGetQuery(con, "
  SELECT t.*, d.diet_detailed
  FROM species_traits t
  JOIN species_diet d ON t.species_id = d.species_id
  WHERE d.diet_detailed IN ('herbivore', 'carnivore_vertebrate')
")
dbDisconnect(con)

# ---------- add 3 columns from COMBINE (Soria et al. 2021) ----------
data(COMBINE)
extra <- COMBINE[, c("species", "litters_per_year_n", "gestation_length_d", "weaning_age_d")]
mydata <- merge(mydata, extra, by.x = "species_name", by.y = "species", all.x = TRUE)

# young per year = litter size x litters per year
mydata$young_per_year <- mydata$litter_size_n * mydata$litters_per_year_n

# ---------- the test ----------
# step 1: fit one line of log10(variable) vs log10(body mass) through both groups
# step 2: residual = how far each species is above/below that line
#         (positive = more than expected for its body size)
# step 3: Welch t-test on residuals, vertebrate-eaters vs herbivores
results <- data.frame()
size_corrected_ttest <- function(column, label) {
  d <- mydata[!is.na(mydata[[column]]) & mydata[[column]] > 0, ]
  d$res <- resid(lm(log10(d[[column]]) ~ log10(d$adult_mass_g)))
  vert <- d$res[d$diet_detailed == "carnivore_vertebrate"]
  herb <- d$res[d$diet_detailed == "herbivore"]
  r <- t.test(vert, herb)
  cat("\n=====", label, "=====\n")
  cat("species: vertebrate-eaters =", length(vert), ", herbivores =", length(herb), "\n")
  cat("vertebrate-eaters are", round(10^(mean(vert) - mean(herb)), 2),
      "x herbivores at the same body size\n")
  print(r)
  results <<- rbind(results, data.frame(
    variable = label,
    n_vertebrate_eaters = length(vert), n_herbivores = length(herb),
    times_herbivores = round(10^(mean(vert) - mean(herb)), 2),
    t = round(unname(r$statistic), 2), df = round(unname(r$parameter), 1),
    p_value = signif(r$p.value, 2)))
}

size_corrected_ttest("young_per_year", "Young per year")
size_corrected_ttest("gestation_length_d", "Pregnancy length (days)")
size_corrected_ttest("weaning_age_d", "Nursing length (days to weaning)")

write.csv(results, "confounder_ttests.csv", row.names = FALSE)
print(results)
cat("done - saved in:", getwd(), "\n")
