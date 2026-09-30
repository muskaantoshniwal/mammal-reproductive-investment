# mammal-reproductive-investment
Body size, litter size, newborn mass, and diet for mammal species

This database has information on body size, litter size, newborn mass, and diet for 3443 mammal species. I built it for BIOLOGY 590S.

Author: Muskaan Toshniwal
Last updated: September 2026
Main file: mammal_reproductive_investment.csv
Each row represents one species.

## Project question

I am looking at how body size and diet relate to how much mammals invest in each litter.

Larger mammals generally have fewer, more developed offspring, so I expect the amount they invest in each litter relative to their own body size to decrease as body size increases.

I am especially interested in whether this relationship is different for animals that mainly eat vertebrates compared with herbivores of the same body size.

There are two possible predictions:

Vertebrate eating carnivores may invest less in each litter because hunting prey takes a lot of energy, especially for larger carnivores.

Vertebrate eating carnivores may invest more in each litter because vertebrate prey provides a lot of energy and may support greater reproductive investment.

## Data sources

I combined data from four main sources:

COMBINE: adult body mass, litter size, taxonomy, and broad diet category

PanTHERIA: newborn body mass and whether litter size was directly measured

EltonTraits 1.0: more detailed information on what each species eats

PHYLACINE 1.2: species name matching and the mammal phylogenetic tree

## How I built the database

I started with COMBINE, which had 3733 species with body mass, litter size, and broad diet information.

I matched these species to EltonTraits to get more detailed diet information. I first matched species names directly, then used the PHYLACINE synonym table and manually checked species whose names had changed. I was able to get detailed diet data for 3322 species.

I used the EltonTraits diet percentages to split carnivores into species that mainly eat invertebrates and species that mainly eat vertebrates.

I matched the species to the PHYLACINE 1.2 phylogenetic tree and removed duplicates and species that were not in the tree. This left 3443 species.

I added newborn mass from PanTHERIA where it was available. Newborn mass was available for 1044 species.

I then calculated total litter mass and the amount invested in a litter relative to the adult's body mass.

## What each column means

Missing data are shown as NA.

species_name: Scientific name of the species.

tree_tip: Species name exactly as it appears in the PHYLACINE tree. This is also the unique ID for each row.

order, family: The taxonomic order and family of the species.

adult_mass_g: Average adult body mass in grams.

log10_mass: Log-transformed adult body mass.

litter_size_n: Average number of offspring in one litter.

litter_measured: Y if PanTHERIA reports a measured litter size for the species and N if it does not.

neonate_mass_g: Average body mass of one newborn, in grams.

litter_mass_g: Total newborn mass of one litter. This is calculated as litter size × newborn mass.

prop_investment: Total litter mass divided by adult body mass. This gives the amount invested in one litter relative to the adult's size.

log10_neonate_mass: Log-transformed newborn mass.

log10_prop_investment: Log-transformed proportional investment.

placental: Y for placental mammals and N for marsupials and monotremes. Species marked N should be excluded from analyses using newborn mass.

diet: Broad diet category from COMBINE: herbivore, omnivore, or carnivore.

diet_detailed: More specific diet category: herbivore, omnivore, carnivore_invertebrate, carnivore_vertebrate, or carnivore_unknown.

pct_animal: % of the diet that comes from animal sources.

pct_invert: % of the diet that comes from invertebrates.

pct_vertebrate: % of the diet that comes from vertebrates such as mammals, birds, reptiles, amphibians, and fish.

pct_fruit: % of the diet that comes from fruit.

diet_interpolated: Y if EltonTraits estimated the species diet using information from related species instead of species specific data.

## Important things to keep in mind

For 422 species, EltonTraits estimated diet based on related species rather than species-specific data. These species are marked Y under diet_interpolated.

Adult body mass is the average mass for the species and is not specifically female body mass.

## References

Carbone C, Teacher A, Rowcliffe JM (2007). The costs of carnivory. PLoS Biology 5: e22.

Derrickson EM (1992). Comparative reproductive strategies of altricial and precocial eutherian mammals. Functional Ecology 6: 57–65.

Faurby S et al. (2018). PHYLACINE 1.2: The Phylogenetic Atlas of Mammal Macroecology. Ecology 99: 2626.

Jones KE et al. (2009). PanTHERIA: a species-level database of life history, ecology, and geography of extant and recently extinct mammals. Ecology 90: 2648.

McNab BK (2019). What determines the basal rate of metabolism? Journal of Experimental Biology 222: jeb205591.

Sibly RM, Brown JH (2007). Effects of body size and lifestyle on evolution of mammal life histories. PNAS 104: 17707–17712.

Soria CD et al. (2021). COMBINE: a coalesced mammal database of intrinsic and extrinsic traits. Ecology 102: e03344.

Wilman H et al. (2014). EltonTraits 1.0: Species-level foraging attributes of the world's birds and mammals. Ecology 95: 2027.
