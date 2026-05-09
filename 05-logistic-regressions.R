# ------ chinese restaurant name analysis project
# ------ logistic regressions


# ------ setup

library(here)
source(here("00-setup.R"))


# ------ load data

restaurants <- readRDS(here("data", "text_features.rds"))

# excluding romanized this time because it's the outcome variable
category_cols <- c("cat_places", "cat_symbols", "cat_names",
                   "cat_nature", "cat_food", "cat_format")


# ------ same logistic regression model from the project proposal

# y = romanized words in name, x = log proportion of Chinese population
model1 <- glm(romanized ~ log_pct_chinese,
              data = restaurants,
              family = binomial())

summary(model1)    # p < 0.001
exp(coef(model1))  # convert to odds ratios
# each unit increase in X means 33% higher odds of romanized restaurant names
tidy(model1, exponentiate = TRUE, conf.int = TRUE)


# add urban/rural locale group
model2 <- glm(romanized ~ log_pct_chinese + locale_group,
              data = restaurants,
              family = binomial())

summary(model2)
exp(coef(model2))  # convert to odds ratios
tidy(model2, exponentiate = TRUE, conf.int = TRUE)

# check for collinearity
vif(model2)

# test with ANOVA to see if locale adds explanatory power to the model
anova(model1, model2, test = "Chisq")


# ------ logistic regression per category

# fit the model
models_categories <- category_cols %>%
  setNames(str_remove(., "cat_")) %>%
  lapply(function(col) {
    glm(restaurants[[col]] ~ log_pct_chinese + locale_group,
        data = restaurants,
        family = binomial())
  })

# tidy summary table: one row per category
category_summary <- models_categories %>%
  lapply(broom::tidy) %>%
  bind_rows(.id = "category") %>%
  select(category, term, estimate, p.value) %>%
  mutate(odds_ratio = exp(estimate))

# export as csv because it's long
# maybe i could use modelsummary instead?
write.csv(category_summary, here("data", "category_summary.csv"), row.names = FALSE)

# nicely formatted summary!
# exponentiate adds odds ratios
modelsummary(models_categories, exponentiate = TRUE,
             output = here("data", "category_summary.html"))


# ------ export data

saveRDS(model2, here("data", "model_romanized.rds"))
saveRDS(models_categories, here("data", "models_categories.rds"))
