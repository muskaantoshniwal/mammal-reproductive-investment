# mammal-reproductive-investment
Body size, litter size, newborn mass, and diet for mammal species

This database has information on body size, litter size, newborn mass, and diet for 3443 mammal species. I built it for BIOLOGY 590S. I also added femur (thigh bone) measurements for 188 of these species to check my body size data.

* Author: Muskaan Toshniwal
* Last updated: November 2026
* Main file: mammal_reproductive_investment.csv
* Each row represents one species.

## Project question

I am looking at how body size and diet relate to how much mammals invest in each litter.

Larger mammals generally have fewer, more developed offspring, so I expect the amount they invest in each litter relative to their own body size to decrease as body size increases.

I am especially interested in whether this relationship is different for animals that mainly eat vertebrates compared with herbivores of the same body size.

My main question is: land carnivores heavier than about 21.5–25 kg have to hunt prey close to their own size to meet their energy needs (Carbone et al. 1999). Does this cause litter size to decline more steeply with adult body mass in carnivores than in omnivores and herbivores?

There are two possible predictions:

Vertebrate eating carnivores may invest less in each litter because hunting prey takes a lot of energy, especially for larger carnivores. If this is true, litter size should decline most steeply with body mass in carnivores, then omnivores, then herbivores.

Herbivores may have more reliable food, so diet may change how much a species invests at every body size without changing how fast investment declines with body size (Sibly & Brown 2007). If this is true, the diet groups should have different average litter sizes but similar slopes.

## Data sources

I combined data from five main sources:

COMBINE: adult body mass, litter size, taxonomy, and broad diet category

PanTHERIA: newborn body mass and whether litter size was directly measured

EltonTraits 1.0: more detailed information on what each species eats

PHYLACINE 1.2: species name matching and the mammal phylogenetic tree

Campione & Evans (2012): femur and humerus (upper arm bone) length and circumference measured on museum skeletons, along with the body mass of each animal, which was weighed on a scale before it died or before it was turned into a skeleton. I downloaded these from the extants dataset in the MASSTIMATE R package, which was made by the first author of the paper.

PHYLACINE 1.2 phylogeny (Faurby et al. 2018): the mammal family tree I used for PGLS. I used tree 1 of the 1000 trees in Complete_phylogeny.nex. This file is too large for GitHub (132 MB), so download it here and put it in the same folder as mammals.db: https://github.com/MegaPast2Future/PHYLACINE_1.2/blob/master/Data/Phylogenies/Complete_phylogeny.nex

## How I searched for data

I looked for published, peer-reviewed mammal trait databases that cover most living mammals. I started with COMBINE because it already combines several earlier mammal databases and has body mass, litter size, and diet together. Then I added one source for each variable COMBINE did not have: EltonTraits for detailed diet, PanTHERIA for newborn mass, and PHYLACINE for species name matching and the phylogeny.

Later I searched for a published dataset of limb bone measurements for living mammals. I used Campione & Evans (2012) because the bones were measured on real museum skeletons, every animal was weighed, and it covers a wide range of mammal sizes and orders.

## Files

| File | What it is |
|---|---|
| mammal_reproductive_investment.csv | The main dataset. One row per species, with the columns from species_traits and species_diet together. |
| mammals.db | SQLite database with 2 tables, species_traits and species_diet, linked by species_id. species_id is the primary key in species_traits and a foreign key in species_diet. |
| species_traits.csv | The species_traits table as a CSV (from COMBINE and PanTHERIA). |
| species_diet.csv | The species_diet table as a CSV (from COMBINE and EltonTraits). |
| femur_data.csv | Femur and humerus measurements for 188 species, linked to the database by species_id. |
| make_plots.R, make_slide_figures.R | Pull data from mammals.db with a JOIN and make the figures. |
| make_femur_ttests.R | Compares my body mass data with the femur dataset, repeats the litter size analysis using femur size, and runs all the t-tests. |
| ttest_results.csv | The results of every t-test. |
| make_confounder_ttests.R | Tests whether vertebrate-eaters and herbivores of the same body size differ in young per year, pregnancy length, and nursing length (Welch t-tests). Uses litters per year, gestation length, and weaning age from COMBINE (PNC R package). |
| confounder_ttests.csv | Results of the confounder t-tests. |
| make_pgls.R | Repeats the litter size and relative litter mass analyses with PGLS, which accounts for relatedness between species. Needs Complete_phylogeny.nex (see Data sources). |
| pgls_results.csv | Results of the PGLS models. |

## How I built the database

I started with COMBINE, which had 3733 species with body mass, litter size, and broad diet information.

I matched these species to EltonTraits to get more detailed diet information. I first matched species names directly, then used the PHYLACINE synonym table and manually checked species whose names had changed. I was able to get detailed diet data for 3322 species.

I used the EltonTraits diet percentages to split carnivores into species that mainly eat invertebrates and species that mainly eat vertebrates. If a carnivore got a larger percentage of its diet from vertebrates than from invertebrates, I classified it as a vertebrate-eater. Otherwise I classified it as an invertebrate-eater.

I matched the species to the PHYLACINE 1.2 phylogenetic tree and removed duplicates and species that were not in the tree. This left 3443 species.

I added newborn mass from PanTHERIA where it was available. Newborn mass was available for 1044 species.

I then calculated total litter mass and the amount invested in a litter relative to the adult's body mass.

Finally, I matched the Campione & Evans (2012) femur data to my species (see "Femur data" below).

## Why I split carnivores

My hypothesis is about how costly it is to hunt large vertebrate prey. Carnivores that mainly eat invertebrates (like shrews, bats, and anteaters) are mostly small, because invertebrate prey cannot support carnivores larger than about 21.5 kg (Carbone et al. 1999). They do not hunt large prey, so they do not face the same cost. If I kept all carnivores together, the 784 invertebrate-eaters would hide what is happening in the 145 vertebrate-eaters.

## Why I added femur measurements

Body mass is on the x-axis of every graph in this project, so if body mass is wrong, every result could be wrong. I added femur measurements to check this. There are three specific problems with using only the body mass in my database.

**Problem 1: The body mass in my database was not measured on the animals I am studying.**
COMBINE gives one body mass number per species. This number was copied from earlier datasets and includes both males and females. Nobody weighed the mothers whose litters were counted. If a number was copied wrong, nothing in my database would show it. For example, COMBINE lists the murine mouse opossum (Marmosa murina) at 518 g, but the animal Campione & Evans actually weighed was 59 g. That is about 9 times heavier, which is probably a mistake in COMBINE.

**Problem 2: Diet and body size go together in my data.**
The vertebrate-eaters with newborn data are much heavier than the herbivores (median about 10 kg vs about 1 kg). Because of this, a mistake in body mass could look like a difference between diet groups. I need a second way to measure body size to check that the diet differences are real.

**Problem 3: Relative litter mass uses body mass twice.**
Relative litter mass = litter mass ÷ adult body mass, and I plot it against adult body mass. So the same number is on both axes. If a species' body mass is entered too high, its point moves right on the x-axis and down on the y-axis at the same time. Mistakes like this create a downward trend by themselves, even if there is no real relationship. This is called a spurious correlation, and it happens with ratios like this (Kronmal 1993). A body size measure that does not come from the same body mass number does not have this problem.

**Why femur circumference?**
Campione & Evans (2012) found that the circumference of the humerus and femur is the best skeletal predictor of body mass. They also found that it depends mostly on how heavy the animal is, and stays the same across animals with different postures, ways of walking, and evolutionary histories. This means one measurement works for all the mammal groups I compare. In my 188 species, femur circumference predicts database body mass very well (R² = 0.97).

## Inclusion and exclusion criteria

**Included in the main dataset:** species that had adult body mass, litter size, and diet in COMBINE and were in the PHYLACINE tree (3443 species).

**Included in the relative litter mass analysis:** only placental mammals with newborn mass data (991 species).

**Included in the femur analysis:** species that matched the Campione & Evans (2012) dataset (188 species).

**Excluded from diet comparisons:** the 38 carnivores that EltonTraits had no diet data for (carnivore_unknown), because I could not tell if they mainly eat vertebrates or invertebrates.

**Excluded from newborn mass analyses:** marsupials and monotremes (placental = N), because their newborns are tiny by design.

**Excluded from the femur slopes:** the 12 invertebrate-eaters with femur data, because 12 species are too few to fit a reliable line.

**Excluded from the femur data:** 9 of the 198 mammals in Campione & Evans (2012) that were not in my database. These were domestic animals (like sheep and guinea pigs), one specimen only identified to genus, and species without litter size data.

## Femur data

Campione & Evans (2012) measured the femur and humerus of museum skeletons, mostly from the Royal Ontario Museum. Every animal was weighed on a scale before it died or before it was turned into a skeleton.

The source has 198 mammal specimens. I matched 155 to my database by exact name and 34 after updating old names to the names used in my database (for example, Mustela vison is now Neovison vison). The tiger had 2 specimens (2 subspecies), so I averaged them. This left 188 species: 84 herbivores, 62 omnivores, 30 vertebrate-eaters, and 12 invertebrate-eaters.

Femur length is missing for 12 species and humerus length is missing for 13. Femur circumference is there for all 188.

## t-tests

A t-test checks whether the averages of two sets of numbers are different, or whether the difference could just be chance. A p-value below 0.05 means the difference is probably real. All results are in ttest_results.csv.

### Test 1: Is the body mass in my database correct? (paired t-test)

For the 188 species with femur data, I have 2 body masses: the one in my database (COMBINE) and the one Campione & Evans measured on a scale. A paired t-test compares the two numbers for the same species.

Result: the two body masses are very close (correlation r = 0.99). My database values are on average about 7% lower. This difference is small but statistically significant (p = 0.036). So my body mass data are reliable, but slightly low.

### Tests 2–5: Do diet groups differ at the same body size? (Welch t-tests)

Heavier mammals have fewer young, so I cannot compare litter sizes between diet groups directly. Vertebrate-eaters are heavier, so they would look like they have fewer young just because of their size. To fix this, I did 2 steps:

1. I fit one line of litter size against body mass through all species (both log-transformed). For each species, I calculated how far above or below the line it is. This is called a residual. A positive residual means the species has more young than expected for its body size, and a negative residual means fewer.
2. I used a Welch t-test to compare the average residual of two diet groups. A Welch t-test is a t-test that does not assume the two groups have the same spread.

Results:
- Vertebrate-eaters have more young per litter than herbivores of the same body size (p < 0.001).
- Omnivores have more young per litter than herbivores of the same body size (p < 0.001).
- Invertebrate-eaters have fewer young per litter than herbivores of the same body size (p < 0.001).
- For relative litter mass (placental mammals only), vertebrate-eaters invest less relative to their body size than herbivores of the same body size (p < 0.001).

### Tests 6–8: Do my estimated values change the results? (Welch t-tests)

Some values in my database were estimated instead of measured. I used the same residuals to check whether this matters.

- Litter size not measured vs measured: no difference (p = 0.36). The estimated litter sizes do not bias my results.
- Diet estimated from related species vs observed: there is a small difference (p < 0.001), so I repeated the vertebrate-eater vs herbivore test using only species with observed diets. The result was the same (p < 0.001), so the estimated diets do not change my main result.

## What each column means

Missing data are shown as NA. Columns are listed by file.

### File 1: species_traits (table in mammals.db, also species_traits.csv)

Body size and reproduction for each species. Sources: COMBINE and PanTHERIA.

| Column | What it means |
|---|---|
| species_id | Unique ID for each species (SP0001 to SP3443). This links all the tables. Primary key. |
| species_name | Scientific name of the species. |
| tree_tip | Species name exactly as it appears in the PHYLACINE tree. |
| taxon_order | The taxonomic order of the species. It is called taxon_order because ORDER is a reserved word in SQL. |
| family | The taxonomic family of the species. |
| adult_mass_g | Average adult body mass in grams. |
| log10_mass | Log-transformed adult body mass. |
| litter_size_n | Average number of offspring in one litter. |
| litter_measured | Y if PanTHERIA reports a measured litter size for the species and N if it does not. |
| neonate_mass_g | Average body mass of one newborn, in grams. |
| litter_mass_g | Total newborn mass of one litter. This is calculated as litter size × newborn mass. |
| prop_investment | Total litter mass divided by adult body mass. This gives the amount invested in one litter relative to the adult's size. |
| log10_neonate_mass | Log-transformed newborn mass. |
| log10_prop_investment | Log-transformed proportional investment. |
| placental | Y for placental mammals and N for marsupials and monotremes. Species marked N should be excluded from analyses using newborn mass. |

### File 2: species_diet (table in mammals.db, also species_diet.csv)

What each species eats. Sources: COMBINE (diet column) and EltonTraits (all other diet columns).

| Column | What it means |
|---|---|
| species_id | Links each row to species_traits. Foreign key. |
| diet | Broad diet category from COMBINE: herbivore, omnivore, or carnivore. |
| diet_detailed | More specific diet category: herbivore, omnivore, carnivore_invertebrate, carnivore_vertebrate, or carnivore_unknown. |
| pct_animal | % of the diet that comes from animal sources. |
| pct_invert | % of the diet that comes from invertebrates. |
| pct_vertebrate | % of the diet that comes from vertebrates such as mammals, birds, reptiles, amphibians, and fish. |
| pct_fruit | % of the diet that comes from fruit. |
| diet_interpolated | Y if EltonTraits estimated the species diet using information from related species instead of species specific data. |

### File 3: mammal_reproductive_investment.csv

The main dataset. It combines File 1 and File 2 into one table, one row per species, so the columns mean the same thing as above. In this file, the order column is called order instead of taxon_order, and tree_tip is the unique ID for each row.

### File 4: femur_data.csv

Limb bone measurements for 188 species. Source: Campione & Evans (2012).

| Column | What it means |
|---|---|
| species_id | Links each row to species_traits. |
| species_name | Scientific name used in my database. |
| common_name | Common name of the species. |
| name_in_source | The species name exactly as Campione & Evans wrote it. |
| match | exact if the name matched my database directly, renamed if I had to update an old name. |
| specimen | Museum specimen number (ROM = Royal Ontario Museum). |
| n_specimens | Number of specimens measured (1 for every species except the tiger, which has 2). |
| specimen_mass_g | Body mass of the measured animal, weighed on a scale, in grams. |
| femur_length_mm | Length of the femur, in mm. |
| femur_circumference_mm | Distance around the narrowest part of the femur shaft, in mm. |
| humerus_length_mm | Length of the humerus, in mm. |
| humerus_circumference_mm | Distance around the narrowest part of the humerus shaft, in mm. |
| source | Where the measurements came from. |

### File 5: ttest_results.csv

One row per t-test.

| Column | What it means |
|---|---|
| test | Which kind of t-test and what was tested. |
| comparison | The two groups being compared. |
| mean_difference | Difference in averages between the first and second group (log10 scale). A positive number means the first group is higher. |
| t | The t statistic. Larger numbers (positive or negative) mean a bigger difference compared with the spread of the data. |
| df | Degrees of freedom. |
| p_value | Probability of seeing a difference this large by chance. Below 0.05 means the difference is probably real. |

## Important things to keep in mind

For 422 species, EltonTraits estimated diet based on related species rather than species-specific data. These species are marked Y under diet_interpolated.

For 1014 species, litter size was not directly measured in PanTHERIA. These species are marked N under litter_measured.

Adult body mass is the average mass for the species and is not specifically female body mass.

The femur data come from one animal per species, so they describe one individual, not a species average.

COMBINE lists the murine mouse opossum (Marmosa murina) at 518 g, but the animal Campione & Evans weighed was 59 g. This is probably an error in COMBINE.

## References

Campione NE, Evans DC (2012). A universal scaling relationship between body mass and proximal limb bone dimensions in quadrupedal terrestrial tetrapods. BMC Biology 10: 60.

Carbone C, Mace GM, Roberts SC, Macdonald DW (1999). Energetic constraints on the diet of terrestrial carnivores. Nature 402: 286–288.

Carbone C, Teacher A, Rowcliffe JM (2007). The costs of carnivory. PLoS Biology 5: e22.

Church SH, Donoughe S, de Medeiros BAS, Extavour CG (2019). A dataset of egg size and shape from more than 6,700 insect species. Scientific Data 6: 104.

Derrickson EM (1992). Comparative reproductive strategies of altricial and precocial eutherian mammals. Functional Ecology 6: 57–65.

Faurby S et al. (2018). PHYLACINE 1.2: The Phylogenetic Atlas of Mammal Macroecology. Ecology 99: 2626.

Jones KE et al. (2009). PanTHERIA: a species-level database of life history, ecology, and geography of extant and recently extinct mammals. Ecology 90: 2648.

Kronmal RA (1993). Spurious correlation and the fallacy of the ratio standard revisited. Journal of the Royal Statistical Society Series A 156: 379–392.

Martin RD, MacLarnon AM (1985). Gestation period, neonatal size and maternal investment in placental mammals. Nature 313: 220–223.

McNab BK (2019). What determines the basal rate of metabolism? Journal of Experimental Biology 222: jeb205591.

Sibly RM, Brown JH (2007). Effects of body size and lifestyle on evolution of mammal life histories. PNAS 104: 17707–17712.

Soria CD et al. (2021). COMBINE: a coalesced mammal database of intrinsic and extrinsic traits. Ecology 102: e03344.

Tuomi J (1980). Mammalian reproductive strategies: a generalized relation of litter size to body size. Oecologia 45: 39–44.

Wilman H et al. (2014). EltonTraits 1.0: Species-level foraging attributes of the world's birds and mammals. Ecology 95: 2027.
