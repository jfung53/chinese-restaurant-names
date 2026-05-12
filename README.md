# Chinese Restaurant Names

An analysis of naming patterns in Chinese restaurants across the United States, examining whether phonetically romanized names (e.g. *Jade Wok*, *Golden Phoenix*) cluster in areas with higher Chinese population concentration and in urban versus rural locales.

**[View the interactive map →](https://www.jocelynfung.com/data/chinese-restaurants)**

---

## Research question

How do restaurant names signal to different audiences in different places? 

Do Chinese restaurants in areas with larger proportions of Chinese residents use more culturally specific naming strategies (phonetic romanizations, cultural symbols, place names, or the food itself) compared to restaurants in areas with smaller Chinese populations? 

How do restaurant names change from the most urban to the most rural locales? 

---

## Data sources

- **Restaurant data:** Foursquare Open Source Places
- **Population data:** U.S. Census ACS 2023, county-level general population and Chinese population estimates
- **Locale classification:** National Center for Education Statistics urban-rural locale classifications
- **Romanization/Transliteration systems:** Pinyin, Wade-Giles, Yale Cantonese, Jyutping

---

## Pipeline

Created using **R version:** 4.5.2 

| File | Purpose |
|------|---------|
| `00-setup.R` | Set libraries and paths |
| `01-data-prep.R` | Load and prepare data, group locale codes, log-transform Chinese population %, correct misspellings |
| `02-words.R` | Tokenize restaurant names, extract bigrams, calculate phrase ratios to determine bigram meaning threshold |
| `03-text-features.R` | Flag non-english words, categorize romanizations, apply category flags to restaurant names |
| `04-descriptives.R` | Descriptive statistics, ANOVA, chi-square tests, category frequency charts |
| `03a-category-lists.R` | Create category lookup lists from token/bigram CSVs |
| `05-logistic-regressions.R` | Logistic regression: romanized name ~ Chinese population + locale group |
| `06-poisson.R` | Poisson regression: name complexity score ~ Chinese population + locale group |
| `07-radar-data.R` | Export per-restaurant and per-locale category data as JSON for making radar charts |

Supporting files:
- `romanization-vectors.R` - Romanization vectors (run this before `03-text-features.R`)
- `02-words.R` - only needs to be re-run if source data changes

---

## Word categories

Restaurant names were tokenized into unigrams and bigrams which were then categorized into 6 categories both manually and with help from an LLM. Categories aren't mutually exclusive: each token can contribute to multiple categories.  

| Category | Examples |
|----------|---------|
| **Places** | China, Chinese, Shanghai, Mandarin, Canton, Szechuan, East, Asian |
| **Symbols** | Lucky, Dynasty, Fortune, 888, Silk, Rickshaw, Golden |
| **Names** | Lee, Chen, Peter, Amy, Uncle, Mama, Master |
| **Nature** | Garden, Panda, Dragon, Lotus, Bamboo, Golden, Jade |
| **Food** | Noodle, Dumpling, Wok, Dim Sum, Spicy, Ginger, Fried, Chopstick |
| **Format** | Buffet, Express, Kitchen, Bistro, Fast, Chef, Gourmet, Fusion |
| **Romanized** | Transliterated words such as Chen, Sun, Chow, Ling, Zhao, Liang |

---

This was my final project for INFO 640: Data Analysis at the Pratt Institute School of Information Spring 2026 semester
