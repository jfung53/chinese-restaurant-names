# ------ chinese restaurant name analysis project
# ------ radar chart data export


# ------ setup

library(here)
source(here("00-setup.R"))


# --- load data from poisson regression

restaurants <- readRDS(here("data", "restaurants_scored.rds"))

category_cols <- c("cat_places", "cat_symbols", "cat_names",
                   "cat_nature", "cat_food", "cat_format", "romanized")


# prepare per-restaurant data
# changes TRUE/FALSE to 0/1 for to play better with javascript

restaurant_data <- restaurants %>%
  select(fsq_place_id, corrected_name, locale_group, complexity,
         all_of(category_cols)) %>%
  rename_with(~ str_remove(., "cat_"), all_of(category_cols)) %>%
  mutate(across(where(is.logical), as.integer))


# per-locale-group averages (the second blob of the radar chart)

locale_averages <- restaurants %>%
  group_by(locale_group) %>%
  summarise(across(all_of(category_cols), mean),
            mean_complexity = mean(complexity)) %>%
  rename_with(~ str_remove(., "cat_"), all_of(category_cols))


# ------ export

radar_data <- list(
  restaurants   = restaurant_data,
  locale_averages = locale_averages
)

write_json(radar_data, here("data", "radar_data.json"), pretty = TRUE, auto_unbox = TRUE)
