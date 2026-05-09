# ------ chinese restaurant name analysis project
# ------ poisson regression on name complexity score


# ------ setup

library(here)
source(here("00-setup.R"))


# ------ load text data
restaurants <- readRDS(here("data", "text_features.rds"))

# romanized is back because it's not an outcome variable
# (it was omitted from the vector for the logistic regression)
category_cols <- c("cat_places", "cat_symbols", "cat_names",
                   "cat_nature", "cat_food", "cat_format", "romanized")


# ------ calculate the complexity score (it's just a category count)

# count of category matches for each restaurant
restaurants <- restaurants %>%
  mutate(complexity = rowSums(across(all_of(category_cols))))

# inspect the distribution
restaurants %>%
  count(complexity) %>%
  mutate(pct = n / sum(n) * 100)

# distribution of complexity scores
ggplot(restaurants, aes(x = complexity)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Distribution of name complexity scores",
       x = "Complexity score", y = "Count") +
  theme_minimal()

ggsave(here("images", "complexity_distribution.png"), width = 6, height = 4)

# faceted by locale group
ggplot(restaurants, aes(x = complexity)) +
  geom_histogram(aes(y = after_stat(count / sum(count))), binwidth = 1) +
  facet_wrap(~ locale_group) +
  labs(title = "Name complexity by locale group",
       x = "Complexity score", y = "Proportion of restaurants") +
  theme_minimal()

ggsave(here("images", "complexity_distribution_by_locale.png"), width = 8, height = 6)

# check for overdispersion: variance should roughly equal mean for Poisson
mean(restaurants$complexity)
var(restaurants$complexity)

restaurants %>%
  group_by(locale_group) %>%
  summarise(mean_complexity = mean(complexity),
            sd_complexity = sd(complexity))



# ------ poisson models

# model 1: chinese population concentration only
poisson1 <- glm(complexity ~ log_pct_chinese,
                data = restaurants,
                family = poisson())

summary(poisson1)

# model 2: add locale group
poisson2 <- glm(complexity ~ log_pct_chinese + locale_group,
                data = restaurants,
                family = poisson())

summary(poisson2)

# convert to incident rate ratios
broom::tidy(poisson2, exponentiate = TRUE, conf.int = TRUE)

# does locale group add explanatory power?
anova(poisson1, poisson2, test = "Chisq")



# ------ export the data and models

saveRDS(restaurants, here("data", "restaurants_scored.rds"))
saveRDS(list(poisson1 = poisson1, poisson2 = poisson2), here("data", "models_poisson.rds"))

