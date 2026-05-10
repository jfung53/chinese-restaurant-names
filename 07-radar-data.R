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


# ------ asked an LLM for help previewing a radar chart in R
# ------ this turned out TERRIBLY, i need to reconsider

library(purrr)

reference_levels <- c(0.25, 0.5, 0.75, 1.0)

reference_df <- map_dfr(reference_levels, function(r) {
  angle_df %>%
    mutate(x = r * cos(angle), y = r * sin(angle), level = r) %>%
    bind_rows(slice(., 1))
})

ggplot() +
  geom_polygon(data = reference_df,
               aes(x = x, y = y, group = level),
               fill = NA, color = "grey80", linewidth = 0.4) +
  geom_polygon(data = locale_cart,
               aes(x = x, y = y),
               fill = "steelblue", alpha = 0.4, color = "steelblue") +
  geom_polygon(data = single_cart,
               aes(x = x, y = y),
               fill = "black", alpha = 0.5, color = "black") +
  geom_text(data = label_df,
            aes(x = x, y = y, label = category), size = 3) +
  coord_fixed() +
  theme_void() +
  labs(title = paste("Radar preview —", restaurant_locale, "average vs. single restaurant"))

ggsave(here("images", "radar_preview.png"), width = 7, height = 7)


# ------ export

radar_data <- list(
  restaurants   = restaurant_data,
  locale_averages = locale_averages
)

write_json(radar_data, here("data", "radar_data.json"), pretty = TRUE, auto_unbox = TRUE)
