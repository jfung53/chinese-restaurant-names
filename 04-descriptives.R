# ------ chinese restaurant name analysis project
# ------ descriptive statistics

# ------ setup

library(here)
source(here("00-setup.R"))


# ------ load data

# load text data
# fix GEOIDs (cast as string, add leading 0 if under 5 digits)
restaurants <- readRDS(here("data", "text_features.rds")) %>%
  mutate(GEOID = str_pad(as.character(GEOID), width = 5, pad = "0"))

# load county data and fix GEOIDs
county_pop <- read.csv(here("data", "county-population.csv")) %>%
  mutate(GEOID = str_pad(as.character(GEOID), width = 5, pad = "0"))


# define category columns for later
category_cols <- c("cat_places", "cat_symbols", "cat_names",
                   "cat_nature", "cat_food", "cat_format", "romanized")



# ------ exploratory data analysis

# restaurants per grouped urban/rural locale type
restaurants %>%
  count(locale_group) %>%
  mutate(pct = n / sum(n) * 100)

# counties with 0 chinese restaurants
county_pop %>%
  anti_join(restaurants, by = "GEOID") %>%
  nrow()
# 769 out of 3221 (23.87457%)


# romanized names per locale group
restaurants %>%
  group_by(locale_group) %>%
  summarise(pct_romanized = mean(romanized) * 100) %>%
  ggplot(aes(x = locale_group, y = pct_romanized)) +
  geom_col() +
  labs(title = "Romanized restaurant names by locale group",
       x = "Locale group", y = "% romanized") +
  theme_minimal()


# ------ pct_chinese distribution
# already did plot in another file, probably don't need this here

p_raw <- ggplot(restaurants, aes(x = pct_chinese)) +
  geom_histogram(bins = 50) +
  labs(title = "Raw", x = "% Chinese", y = "Count") +
  theme_minimal()

p_log <- ggplot(restaurants, aes(x = log_pct_chinese)) +
  geom_histogram(bins = 50) +
  labs(title = "Log-transformed", x = "log(% Chinese)", y = "Count") +
  theme_minimal()

# use patchwork library to put the ggplots together
p_raw + p_log

ggsave(here("images", "pct_chinese_distribution.png"), width = 8, height = 4)

# ------ ANOVA: log_pct_chinese ~ locale_group
# making sure chinese populations and locale types are different enough

# test for equal variance before doing ANOVA
fligner.test(log_pct_chinese ~ locale_group, data = restaurants)

# ANOVA
anova_model <- aov(log_pct_chinese ~ locale_group, data = restaurants)
summary(anova_model)

# effect size
eta_squared(anova_model)

# post-hoc: which locale pairs differ?
TukeyHSD(anova_model)


# plot the ANOVA variables

# how does chinese population vary across locale types?
county_locale <- restaurants %>%
  distinct(GEOID, locale_group, log_pct_chinese)

ggplot(county_locale, aes(x = locale_group, y = log_pct_chinese)) +
  geom_boxplot() +
  labs(title = "Chinese population (county-level) by locale group",
       x = "Locale group", y = "log(% Chinese)") +
  theme_minimal()

ggsave(here("images", "log_pct_chinese_by_locale_county.png"), width = 6, height = 4)

# ------ plot word category data

restaurants %>%
  summarize(across(all_of(category_cols), mean)) %>%
  pivot_longer(everything(), names_to = "category", values_to = "pct") %>%
  mutate(pct = pct * 100,
         category = str_remove(category, "cat_")) %>%
  ggplot(aes(x = reorder(category, -pct), y = pct, fill = category)) +
  geom_col() +
  labs(title = "Word category prevalence",
       x = NULL,
       y = "% of restaurants") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(here("images", "category_prevalence.png"), width = 6, height = 4)

# exclude "chinese" from places to see what it looks like
restaurants %>%
  mutate(cat_places = cat_places & !str_detect(tolower(corrected_name), "\\bchinese\\b")) %>%
  summarize(across(all_of(category_cols), mean)) %>%
  pivot_longer(everything(), names_to = "category", values_to = "pct") %>%
  mutate(pct = pct * 100,
         category = str_remove(category, "cat_")) %>%
  ggplot(aes(x = reorder(category, -pct), y = pct, fill = category)) +
  geom_col() +
  labs(title = "Word category prevalence (excluding 'Chinese' from places)",
       x = NULL,
       y = "% of restaurants") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(here("images", "category_prevalence_no_chinese.png"), width = 6, height = 4)

# ------ category prevalence by locale group

restaurants %>%
  group_by(locale_group) %>%
  summarise(across(all_of(category_cols), mean)) %>%
  pivot_longer(-locale_group, names_to = "category", values_to = "pct") %>%
  mutate(pct = pct * 100,
         category = str_remove(category, "cat_")) %>%
  ggplot(aes(x = pct, y = reorder(category, pct), fill = category)) +
  geom_col() +
  facet_wrap(~ locale_group) +
  labs(title = "Category prevalence by locale group",
       x = "% of restaurants", y = NULL,
       fill = "Category") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(here("images", "category_by_locale.png"), width = 8, height = 6)


# exclude chinese from places again to see the difference
restaurants %>%
  mutate(cat_places = cat_places & !str_detect(tolower(corrected_name), "\\bchinese\\b")) %>%
  group_by(locale_group) %>%
  summarise(across(all_of(category_cols), mean)) %>%
  pivot_longer(-locale_group, names_to = "category", values_to = "pct") %>%
  mutate(pct = pct * 100,
         category = str_remove(category, "cat_")) %>%
  ggplot(aes(x = pct, y = reorder(category, pct), fill = category)) +
  geom_col() +
  facet_wrap(~ locale_group) +
  labs(title = "Category prevalence by locale group (excluding 'chinese' from places)",
       x = "% of restaurants", y = NULL) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(here("images", "category_by_locale_no_chinese.png"), width = 8, height = 6)



# ------ correlation matrices

restaurants %>%
  select(all_of(category_cols)) %>%
  rename_with(~ str_remove(., "cat_")) %>%
  cor() %>%
  as.data.frame() %>%
  rownames_to_column("cat1") %>%
  pivot_longer(-cat1, names_to = "cat2", values_to = "phi") %>%
  ggplot(aes(x = cat1, y = cat2, fill = phi)) +
  geom_tile() +
  geom_text(aes(label = round(phi, 2)), size = 3) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
  labs(title = "Category correlations (phi coefficients)",
       x = NULL, y = NULL, fill = "φ") +
  theme_minimal()

ggsave(here("images", "category_correlations.png"), width = 6, height = 5)


# another correlation plot

#png("images/category_correlations.png", width = 600, height = 500)
restaurants %>%
  select(all_of(category_cols)) %>%
  rename_with(~ str_remove(., "cat_")) %>%
  cor() %>%
  corrplot(method = "color", type = "upper",
           addCoef.col = "black", number.cex = 0.7,
           tl.col = "black", tl.srt = 45)
#dev.off()

# how much overlap is there between the romanized and names categories?
table(restaurants$romanized, restaurants$cat_names)
# 55% of names category are romanized chinese words
# 35% of romanized category are in names category (aka 65% are not)


# chi-square test of each category x locale_group

category_cols %>%
  lapply(function(col) {
    test <- chisq.test(table(restaurants[[col]], restaurants$locale_group))
    data.frame(category = str_remove(col, "cat_"),
               chi_sq   = test$statistic,
               df       = test$parameter,
               p_value  = test$p.value)
  }) %>%
  bind_rows()
