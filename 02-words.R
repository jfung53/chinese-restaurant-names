# ------ chinese restaurant name analysis project
#
# ------ word prep file
# ------ extract words and bigrams to categorize for
# ------ logistic regression and charts

library(here)
source(here("00-setup.R"))

# ------ bring in the data

restaurants <- readRDS(here("data", "restaurants_clean.rds"))

# define project-specific stop words
corpus_stops <- tibble(word = "restaurant")

# clean up names and use corrected misspellings
clean_names <- restaurants %>%
  select(fsq_place_id, corrected_name) %>%
  mutate(name_clean = tolower(corrected_name),
         name_clean = str_remove_all(name_clean, "'s\\b"))


# ------ turn restaurant names into tokens

# load stop words
data("stop_words")

# unnest into individual words
unigrams <- clean_names %>%
  unnest_tokens(word, name_clean, token = "words") %>%
  anti_join(stop_words, by = "word") %>%
  anti_join(corpus_stops, by = "word") %>%
  filter(nchar(word) >= 3) %>%
  count(word, sort = TRUE) %>%
  filter(n >= 5) # frequency threshold

# unnest into bigrams
# this will catch things like "golden dragon" or "hong kong"
bigrams_raw <- clean_names %>%
  unnest_tokens(bigram, name_clean, token = "ngrams", n = 2) %>%
  filter(!is.na(bigram)) %>% # drop names that are only one word
  separate(bigram, c("word1", "word2"), sep = " ", remove = FALSE) %>%
  # drop bigrams if both words are stop words
  filter(!(word1 %in% stop_words$word & word2 %in% stop_words$word)) %>%
  filter(!word1 %in% corpus_stops$word, !word2 %in% corpus_stops$word) %>%
  filter(nchar(word1) >= 3, nchar(word2) >= 3) %>%
  count(bigram, word1, word2, sort = TRUE) %>%
  filter(n >= 7) # adjusted this after manual review


# ------ calculate word/bigram frequency ratio
# this is to avoid double-counting single words that also appear in
# bigrams that are meaningful for categorization (great wall vs wall)
#
# identifies phrases where one word is uncommon (e.g. how often does
# "manchu" appear outside of "manchu wok"?)

# include all words, no filtering
# this prevents NAs in the join and would break the ratio calculation
all_unigrams <- clean_names %>%
  unnest_tokens(word, name_clean, token = "words") %>%
  count(word, name = "n_total")

# calculate ratio
bigrams <- bigrams_raw %>%
  # get word counts
  left_join(all_unigrams, by = c("word1" = "word")) %>%
  rename(n_word1 = n_total) %>%
  left_join(all_unigrams, by = c("word2" = "word")) %>%
  rename(n_word2 = n_total) %>%
  # use smaller count since it's the limiting factor on a phrase
  mutate(phrase_ratio = n / pmin(n_word1, n_word2),
         is_phrase = phrase_ratio >= 0.5) %>%
  select(bigram, n, phrase_ratio, is_phrase) %>%
  arrange(desc(phrase_ratio))

# bigrams flagged as meaningful according to the phase ratio threshold
phrase_words <- bigrams %>%
  filter(is_phrase) %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>%
  { c(.$word1, .$word2) } %>%
  unique()

# flag words that also appear in a meaningful bigram
unigrams <- unigrams %>%
  mutate(is_phrase_member = word %in% phrase_words)


# ------ export data

write.csv(unigrams, here("data", "vocabulary_unigrams.csv"), row.names = FALSE)
write.csv(bigrams, here("data", "vocabulary_bigrams.csv"), row.names = FALSE)

# next: manual review of bigrams to adjust the phrase ratio threshold and
# flag exceptions on either side of the threshold (0.5)