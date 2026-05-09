# ------ romanization vectors

# --- MANDARIN

# --- Hanyu Pinyin (ISO 7098, PRC standard 1958) --------------------------
# All entries are valid Pinyin syllables verified against the complete
# Pinyin syllable table. Note: "sun" and "he" are also English words and
# will be partially filtered by grady_augmented; "sun" retained as it
# also appears as the surname 孫 in romanized form. "he" removed.

pinyin <- c(
  # x-, zh-, q-, z- initials: unambiguously Pinyin (not in Wade-Giles)
  "xing", "jing", "xiang", "xin", "xiao", "xian", "xi",
  "zheng", "zhang", "zhou", "zhu", "zhen",
  "jiang", "qing", "zeng", "zhao",
  # standard Pinyin forms
  "wei", "cheng", "hua", "feng", "yan", "chuan",
  "shang", "yi", "hao", "liu", "lu", "tian",
  "chu", "lao", "huang", "chun", "ji", "sheng", "bei",
  "jia", "shan", "chao", "hui", "lan", "du",
  "ming", "bao", "yang", "wu", "shi",
  "hai", "yu", "fu", "zhu", "wang", "tang", "lin",
  "mei", "jun", "hong", "nan", "dong", "tai",
  "ping", "long", "yun", "zhen", "ren", "sun", "guo",
  "liang", "chen", "ling", "peng", "shen", "gao", "bai", "deng"
)


# --- Wade-Giles (dominant English system until ~1979) --------------------
# Words specifically in Wade-Giles form rather than Pinyin equivalent.
# Geographic Wade-Giles forms (peking, szechuan, canton, nanking,
# formosa, yangtze, tsingtao) are treated as place names rather than
# romanizations and are handled in the "places" category.
# Note: tsang is listed under informal Cantonese rather than Wade-Giles
# since its primary use in this corpus is as a Cantonese surname.

wade_giles <- c(
  "tung",   # Pinyin: dong/zhong (東/董)
  "kung",   # Pinyin: gong/kong (龔/孔)
  "chiang"  # Pinyin: jiang (蔣/江)
)


# --- CANTONESE

# --- Yale Cantonese (Huang & Kok 1952/1999; Matthews & Yip 1994) --------
# Valid Yale romanization syllables verified against the complete Yale
# syllable table (Chinese University of Hong Kong / Unihan database,
# converted by Burgmer 2009: http://cburgmer.nfshost.com/content/
# cantonese-yale-syllable-table).

yale_cantonese <- c(
  "wong", "hing", "fong", "cheung", "kwong", "kwok", "kwai", "kwan",
  "lok", "fung", "leung", "yeung", "heung", "chau", "heng",
  "wai", "sai", "pak", "mui", "tak", "kok", "wun", "lai",
  "yat", "hoi", "yip", "lim", "pang", "sing", "chung", "hung", "bok"
)


# --- Informal Cantonese --------------------------------------------------
# Cantonese sounds romanized in non-standard spellings common in
# Chinese-American naming conventions, particularly pre-dating the
# standardization of Jyutping in 1993. These are valid Cantonese
# sounds but do not appear in the formal Yale syllable table.
# Yale equivalents noted for each entry.

informal_cantonese <- c(
  "wah",   # Yale: wa (華)
  "yuen",  # Yale: yun (元/院) — very common in restaurant names
  "shing", # Yale: sing (城/勝) — doubled vowel variant
  "moy",   # Yale: moi (梅)
  "choy",  # Yale: choi (菜/蔡) — very common Cantonese surname, also vegetable
  "loong", # Yale: lung (龍) — informal "dragon" spelling
  "chee",  # Yale: chi
  "kee",   # Yale: ki/gei — common suffix (Sing Kee, Wah Kee)
  "yee",   # Yale: yi (義/二)
  "foo",   # Yale: fu (富/虎) — very common
  "suey",  # Yale: sui (水) — as in "chop suey"
  "fook",  # Yale: fuk (福) — luck character
  "luen"   # Yale: leun — minor variant
)


# --- Jyutping (LSHK standard 1993) --------------------------------------
# Only two entries in the corpus are classified as Jyutping rather than
# Yale, and both are approximations — they are likely pre-standardization
# informal Cantonese romanizations rather than deliberate Jyutping usage.
# Retained because they represent common Cantonese surname romanizations.

jyutping <- c(
  "tsang",  # approx. Jyutping: cang (曾) — common Cantonese surname
  "tsui"    # approx. Jyutping: zeoi (徐/崔) — common Cantonese surname
)


# --- combined vectors for flagging ---------------------------------------

# all Mandarin romanizations (Pinyin + Wade-Giles)
mandarin_romanized <- c(pinyin, wade_giles)

# all Cantonese romanizations (Yale + informal + Jyutping)
cantonese_romanized <- c(yale_cantonese, informal_cantonese, jyutping)

# all romanized Chinese words — used for the "romanized" flag
romanized_all <- c(mandarin_romanized, cantonese_romanized)


# --- exceptions ----------------------------------------------------------
# Chinese bigrams that have entered common English usage and should NOT
# be flagged as romanized restaurant names
# exception: Asian Chao is a chain restaurant

exceptions <- c(
  "Hong Kong", "Chop Suey", "Asian Chao",
  "Kung Fu", "Dim Sum", "Won Ton", "Wonton", "Chow Mein"
)
