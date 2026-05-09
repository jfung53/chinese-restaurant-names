# ------ chinese restaurant name analysis project
# ------ category lookup lists
# ------ sourced by 03-text-features.R


unigrams <- read.csv(here("data", "vocabulary_unigrams.csv"))
bigrams  <- read.csv(here("data", "vocabulary_bigrams.csv"))


# ------ build category lookup vectors from vocabulary CSVs

# --- categories aren't mutually exclusive, restaurants may have multiple
# --- most of this was done manually with some help from an LLM

# place names, cities, cardinal directions, geographic features
cat_places <- c(
  unigrams$word[unigrams$places == TRUE],
  bigrams$bigram[bigrams$places == TRUE]
)

# culturally coded symbols like dynasties, auspicious symbols, lucky numbers,
# historical figures and place, and things that are obviously chinese in origin
# like rickshaw, zen, and tao
cat_symbols <- c(
  unigrams$word[unigrams$symbols == TRUE],
  bigrams$bigram[bigrams$symbols == TRUE]
)

# proper nouns, family words, honourifics
cat_names <- c(
  unigrams$word[unigrams$names == TRUE],
  bigrams$bigram[bigrams$names == TRUE]
)

# plants, animals, mythological creatures, weather
cat_nature <- c(
  unigrams$word[unigrams$nature == TRUE],
  bigrams$bigram[bigrams$nature == TRUE]
)

# food items (may include ethnicities other than chinese that showed up
# in the foursquare data)
# includes spicy
cat_food <- c(
  unigrams$word[unigrams$food == TRUE],
  bigrams$bigram[bigrams$food == TRUE]
)

# format and descriptors like buffet, takeout, cafe, gourmet, fusion, express
cat_format <- c(
  unigrams$word[unigrams$format == TRUE],
  bigrams$bigram[bigrams$format == TRUE]
)

# chain restaurants (probably not exhaustive, i did my best by googling)
cat_chain <- c(
  unigrams$word[unigrams$chain == TRUE],
  bigrams$bigram[bigrams$chain == TRUE]
)

