# ------ INFO 640 model results check-in
#
# ------ research question (part 1):
# ------ does urbanicity and/or the proportion of Chinese residents predict
# ------ whether a Chinese restaurant name includes Chinese words? 


# ------ setup and libraries

setwd("/Users/jocelyn/Documents/Pratt/Projects/chinese-restaurant-names")

library(dplyr)      # for data cleaning
library(ggplot2)    # for visualizing
library(tidytext)   # for text analysis
library(lexicon)    # for english dictionary
library(stringr)    # for string operations
library(car)        # for regression diagnostics


# ------ bring in data

restaurants <- read.csv("us_restaurants_with_pop.csv")
glimpse(restaurants)
summary(restaurants)


# ------ clean the data

# take a look at the distribution of urba/rural locale types
restaurants %>%
  count(LOCALE, LOC_NAME) %>%
  arrange(LOCALE)

# group the 12 locales into 4
restaurants <- restaurants %>%
  mutate(locale_group = case_when(
    LOCALE %in% 11:13 ~ "City",
    LOCALE %in% 21:23 ~ "Suburban",
    LOCALE %in% 31:33 ~ "Town",
    LOCALE %in% 41:43 ~ "Rural"
  ) %>% factor(levels = c("City", "Suburban", "Town", "Rural")))

# count per group
restaurants %>% count(locale_group)

# remove the NA's (there were 59)
restaurants <- restaurants %>%
  filter(!is.na(locale_group), !is.na(population), !is.na(chinese))


# --- calculate proportion of chinese people
# population data is per county
# i already know that it's extremely right-skewed so i'll log transform it
restaurants <- restaurants %>%
  mutate(
    pct_chinese = chinese / population,
    log_pct_chinese = log(pct_chinese + 0.001)
  )

# plot before and after log transform
par(mfrow = c(1, 2))
hist(restaurants$pct_chinese, main = "Raw", xlab = "pct_chinese")
hist(restaurants$log_pct_chinese, main = "Log transformed", xlab = "log_pct_chinese")


# ------ isolate non-english words

# use lexicon library's grady_augmented list of english words and names
non_english <- restaurants %>%
  select(fsq_place_id, name) %>%
  mutate(name_clean = tolower(name),
         # there are a lot of words with apostrophe-s (andy's, for example)
         # need to remove these possessives before tokenizing
         # \b only matches 's at the end of a word
         name_clean = str_remove_all(name_clean, "'s\\b")) %>%
  unnest_tokens(word, name_clean) %>%
  anti_join(data.frame(word = grady_augmented), by = "word")

# hand off non-english df to an LLM to categorize
non_english %>%
  count(word, sort = TRUE) %>%
  write.csv(file = "non_english_words.csv", row.names = FALSE)

# paste in the phonetically romanized chinese words from LLM
mandarin_romanized <- c(
  "wei", "cheng", "xing", "jing", "hua", "feng", "yan", "chuan",
  "shang", "xiang", "yi", "xin", "hao", "liu", "lu", "tian",
  "chu", "lao", "huang", "chun", "ji", "sheng", "bei", "zheng",
  "jia", "shan", "chao", "hui", "zhang", "lan", "qing", "du",
  "ming", "bao", "xiao", "xian", "zhou", "yang", "wu", "shi",
  "hai", "yu", "fu", "jiang", "zhu", "wang", "tang", "lin",
  "mei", "jun", "hong", "feng", "nan", "dong", "xi", "tai",
  "ping", "long", "yun", "zhen", "ren", "sun", "guo", "he"
)

cantonese_romanized <- c(
  "wah", "wong", "hing", "fong", "yuen", "cheung", "kwong",
  "kwok", "kwai", "kwan", "lok", "shing", "fung", "moy", "choy",
  "leung", "loong", "yeung", "tsang", "tsui", "luen", "heung",
  "chau", "chee", "heng", "kee", "wai", "sai", "pak", "mui",
  "tak", "kok", "yee", "foo", "shing", "wun", "suey", "lai",
  "fook", "yat", "kwan", "hoi", "yip", "lim", "pang", "sing"
)

# generous of the LLM to give me both dialects, let's combine them
romanized_all <- c(mandarin_romanized, cantonese_romanized)

# exceptions to romanized words
exceptions <- c("Hong Kong", "Chop Suey", "Asian Chao", 
                "Kung Fu", "Dim Sum", "Won Ton", "Wonton", "Chow Mein")

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
restaurants %>%
  filter(romanized == TRUE) %>%
  select(corrected_name) %>%
  sample_n(100) %>%
  print()



# ------ identify large chain restaurants

# look at top 80 (arbitrary number)
restaurants %>%
  count(name, sort = TRUE) %>%
  head(80) %>%
  as.data.frame() %>%
  print()

# names of chain restaurants (gathered from googling, nothing fancy)
chain_names <- c(
  "Panda Express", "P.F. Chang's", "Manchu Wok", "Wow Bao",
  "Asian Chao", "Pei Wei", "Leeann Chin", "Pick Up Stix",
  "Chinese Gourmet Express"
)

# add chain flag via partial match
restaurants <- restaurants %>%
  mutate(chain = str_detect(name, str_c(chain_names, collapse = "|")))

# examine results
chain_restaurants <- restaurants %>%
  filter(chain == TRUE) %>%
  count(name, sort = TRUE)

# a handful of names using "panda express" but are not part of the chain
# i'll just ignore them since there's only 5


# ------ handle misspellings with the help of an LLM
# note to self: move this to run first later

# paste in LLM's lookup table
misspelling_lookup <- c(
  # restaurant
  "resturant" = "restaurant", "restaraunt" = "restaurant",
  "restaruant" = "restaurant", "resturaunt" = "restaurant",
  "restuarant" = "restaurant", "restaurnt" = "restaurant",
  "restraunt" = "restaurant", "reaturant" = "restaurant",
  "reataurant" = "restaurant", "resraurant" = "restaurant",
  "restauramt" = "restaurant", "restaurent" = "restaurant",
  "restaurnat" = "restaurant", "restruant" = "restaurant",
  "retaurant" = "restaurant", "resteraunt" = "restaurant",
  "restsurant" = "restaurant", "resteruant" = "restaurant",
  "restarurant" = "restaurant", "restauant" = "restaurant",
  "restauarant" = "restaurant", "restaueant" = "restaurant",
  "restauraunt" = "restaurant", "restaurt" = "restaurant",
  "restaurtant" = "restaurant", "restautant" = "restaurant",
  "restauurant" = "restaurant", "restrauant" = "restaurant",
  "restuarnt" = "restaurant", "restyrant" = "restaurant",
  "returant" = "restaurant", "reaturant" = "restaurant",
  "resaurant" = "restaurant", "resraurant" = "restaurant",
  # chinese
  "chineese" = "chinese", "chinesse" = "chinese",
  "chinease" = "chinese", "chinees" = "chinese",
  # beijing
  "bejing" = "beijing", "beijng" = "beijing",
  "beijang" = "beijing", "beijeng" = "beijing",
  # shanghai
  "shanghi" = "shanghai", "shangnai" = "shanghai",
  # mandarin
  "manderian" = "mandarin", "manderin" = "mandarin",
  "mandrian" = "mandarin", "mandrain" = "mandarin",
  # hibachi
  "habachi" = "hibachi", "hibatchi" = "hibachi",
  "habatchi" = "hibachi", "habichi" = "hibachi",
  "habochi" = "hibachi",
  # teriyaki
  "teryaki" = "teriyaki", "terriyaki" = "teriyaki",
  "teriaki" = "teriyaki",
  # szechuan
  "szechwan" = "szechuan", "szechaun" = "szechuan",
  "szechwuab" = "szechuan", "szecuan" = "szechuan",
  "szechuen" = "szechuan", "szechauan" = "szechuan",
  "szechuen" = "szechuan", "sczechuan" = "szechuan",
  "szeshuan" = "szechuan", "szchewan" = "szechuan",
  "szchuan" = "szechuan", "schezwan" = "szechuan",
  "schezuan" = "szechuan", "schizuan" = "szechuan",
  "sezchuan" = "szechuan", "sezchaun" = "szechuan",
  "sichaun" = "sichuan", "sicuhuan" = "sichuan",
  # cuisine
  "cusine" = "cuisine", "cruisine" = "cuisine",
  "crusine" = "cuisine", "cuisune" = "cuisine",
  # gourmet
  "gormet" = "gourmet", "gourment" = "gourmet",
  "gurmet" = "gourmet", "goumet" = "gourmet",
  "gournet" = "gourmet",
  # pavilion
  "pavillion" = "pavilion",
  # phoenix
  "pheonix" = "phoenix",
  # village
  "villiage" = "village"
)

# function to correct the misspellings
correct_misspellings <- function(name) {
  words <- str_split(tolower(name), "\\s+")[[1]]
  words <- ifelse(words %in% names(misspelling_lookup),
                  misspelling_lookup[words],
                  words)
  str_to_title(str_c(words, collapse = " "))
}

# flag misspellings and correct them
restaurants <- restaurants %>%
  mutate(
    misspelling = str_detect(tolower(name), 
                             str_c(names(misspelling_lookup), collapse = "|")),
    corrected_name = ifelse(misspelling, 
                            sapply(name, correct_misspellings), 
                            name)
  )

# examine the results
restaurants %>%
  filter(misspelling == TRUE) %>%
  select(name, corrected_name) %>%
  head(20)


# ------ logistic regression

# y = romanized words in name, x = log proportion of Chinese population
model1 <- glm(romanized ~ log_pct_chinese, 
              data = restaurants, 
              family = binomial())

summary(model1)
# p < 0.001

# convert to odds ratio
exp(coef(model1))
# each unit increase in X means 33% higher odds of romanized restaurant names


# add urban/rural locale group
model2 <- glm(romanized ~ log_pct_chinese + locale_group,
              data = restaurants,
              family = binomial())

summary(model2)

# convert to odds ratio
exp(coef(model2))

# check for collinearity
vif(model2)

# test with ANOVA to see if locale adds explanatory power to the model
anova(model1, model2, test = "Chisq")



# ------ plot findings

# by locale group
restaurants %>%
  group_by(locale_group) %>%
  summarize(pct_romanized = mean(romanized) * 100) %>%
  ggplot(aes(x = locale_group, y = pct_romanized, fill = locale_group)) +
  geom_col() +
  labs(
    title = "Phonetically Romanized Restaurant Names by Locale",
    x = "Locale Type",
    y = "% Romanized Names",
    fill = "Locale"
  ) +
  theme_minimal()

