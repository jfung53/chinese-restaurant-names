# ------ chinese restaurant name analysis project
# ------ text categorization


# ------ setup and libraries

setwd("/Users/jocelyn/Documents/Pratt/Projects/chinese-restaurant-names")

library(dplyr)      # for data cleaning
library(tidytext)   # for text analysis
library(lexicon)    # for english dictionary
library(stringr)    # for string operations

restaurants <- readRDS("data/restaurants_clean.rds")

# ------ isolate non-english words

# use lexicon library's grady_augmented list of english words and names
non_english <- restaurants %>%
  select(fsq_place_id, corrected_name) %>%
  mutate(name_clean = tolower(corrected_name),
         # there are a lot of words with apostrophe-s (andy's, for example)
         # need to remove these possessives before tokenizing
         # \b only matches 's at the end of a word
         name_clean = str_remove_all(name_clean, "'s\\b")) %>%
  unnest_tokens(word, name_clean) %>%
  anti_join(data.frame(word = grady_augmented), by = "word")

# export to categorize the romanizations
non_english %>%
  count(word, sort = TRUE) %>%
  write.csv(file = "data/non_english_words.csv", row.names = FALSE)

# bring categorized romanizations back in
# too large and messy to include so i separated them into their own file
source("romanization-vectors.R")

# add a flag to identify restaurant names that contain any romanized words
restaurants <- restaurants %>%
  mutate(
    name_for_romanization = str_remove_all(
      corrected_name,
      regex(str_c(exceptions, collapse = "|"), ignore_case = TRUE)
    ),
    romanized = str_detect(
      tolower(name_for_romanization),
      str_c("\\b(", str_c(romanized_all, collapse = "|"), ")\\b")
    )
  )

# double check a sample of the results
# this is where i decided to add the exception list, which excluded about 2000
# exceptions live in the romanization-vectors.R file
restaurants %>%
  filter(romanized == TRUE) %>%
  select(corrected_name) %>%
  sample_n(100) %>%
  print()



# ------ category flags

# bring in category lists
source("03a-category-lists.R")

# apply category flags to restaurants
restaurants <- restaurants %>%
  mutate(
    cat_places  = str_detect(tolower(corrected_name),
                             str_c("\\b(", str_c(cat_places,  collapse = "|"), ")\\b")),
    cat_symbols = str_detect(tolower(corrected_name),
                             str_c("\\b(", str_c(cat_symbols, collapse = "|"), ")\\b")),
    cat_names   = str_detect(tolower(corrected_name),
                             str_c("\\b(", str_c(cat_names,   collapse = "|"), ")\\b")),
    cat_nature  = str_detect(tolower(corrected_name),
                             str_c("\\b(", str_c(cat_nature,  collapse = "|"), ")\\b")),
    cat_food    = str_detect(tolower(corrected_name),
                             str_c("\\b(", str_c(cat_food,    collapse = "|"), ")\\b")),
    cat_format  = str_detect(tolower(corrected_name),
                             str_c("\\b(", str_c(cat_format,  collapse = "|"), ")\\b")),
    cat_chain   = str_detect(tolower(corrected_name),
                             str_c("\\b(", str_c(cat_chain,   collapse = "|"), ")\\b"))
  )


# ------ export

saveRDS(restaurants, "data/restaurants_features.rds")
