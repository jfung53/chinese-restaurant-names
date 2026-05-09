# ------ chinese restaurant name analysis project
# ------ shared setup: libraries and path constants
# ------ source this file at the top of every script


# ------ libraries

library(here)         # for relative file paths
library(dplyr)        # for data manipulation
library(tidyr)        # for data tidying
library(stringr)      # for string operations
library(ggplot2)      # for visualizing
library(patchwork)    # for small multiples
library(tidytext)     # for text tokenization
library(lexicon)      # for english dictionary (grady_augmented)
library(tibble)       # for rownames_to_column()
library(broom)        # for tidy model output
library(car)          # for vif()
library(effectsize)   # for eta_squared()
library(corrplot)     # for correlation matrix
library(modelsummary) # for formatted model tables
library(jsonlite)     # for JSON export


# ------ path constants

path_data   <- here("data")
path_images <- here("images")
path_notes  <- here("notes")
