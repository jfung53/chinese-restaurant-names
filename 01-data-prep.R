# ------ chinese restaurant name analysis project
# ------ data prep


# ------ setup and libraries

setwd("/Users/jocelyn/Documents/Pratt/Projects/chinese-restaurant-names")

library(dplyr)      # for data cleaning
library(ggplot2)    # for visualizing
library(stringr)    # for string operations

# ------ bring in data

restaurants <- read.csv("data/us_restaurants_with_pop.csv")
glimpse(restaurants)
summary(restaurants)


# ------ clean the data

# take a look at the distribution of urban/rural locale types
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
hist(restaurants$pct_chinese,
     main = "Raw",
     xlab = "pct_chinese")
hist(restaurants$log_pct_chinese,
     main = "Log transformed",
     xlab = "log_pct_chinese")


# ------ handle misspellings with the help of an LLM
# note: try stringdist next time

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
  "szechuwan" = "szechuan",
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


# ------ export cleaned data

write.csv(restaurants, "data/restaurants_clean.csv", row.names = FALSE)
saveRDS(restaurants, file = "data/restaurants_clean.rds")
