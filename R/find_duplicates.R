# Load packages and plan parallel multisession ----
if (!"pacman" %in% installed.packages()) install.packages("pacman")
pacman::p_load(tidyverse, here, revtools, fs, furrr, lubridate, rbibutils, glue)

ms_cores <- availableCores() - 2
plan(multisession, workers = ms_cores)

# Filter files for newest searches (most updated) ----
newest_search_path <- dir_ls(
  path = here("data"),
  recurse = TRUE,
  regexp = "complete_[0-9]{6}(\\.ris)|(\\.nbib)$"
) %>%
  tibble(filepath = .) %>%
  mutate(db_source = str_remove(basename(filepath), "_[0-9]{6}((\\.ris)|(\\.nbib))")) %>%
  mutate(date = ymd(str_extract(filepath, "[0-9]{6}"))) %>%
  slice_max(date, by = db_source)

# Deduplication all files combined -----
df_combined_raw <- newest_search_path %>%
  pull(filepath) %>%
  future_map_dfr(read_bibliography, .id = "id_path")

find_dups <- df_combined_raw %>%
  find_duplicates(match_variable = "title", to_lower = TRUE)

find_dups %>%
  as.integer() %>%
  duplicated() %>%
  sum() # 185 Duplicates

df_combined_clean <- extract_unique_references(
  x = df_combined_raw,
  matches = find_dups
) %>%
  # build 4 groups (for screening)
  mutate(id_row = row_number() %% 4, .before = everything()) 
  
# format helpers
format_numbers <- str_pad(string = glue("{1:4}"), width = 2, pad = "0", side = "left") 
format_outfiles <- glue(here("data/db_combined/db_dedup_query_{format_numbers}.ris"))


# Save output to .ris format ----

df_combined_clean %>%
  group_split(id_row) %>%
  walk2(
    .x = ., 
    .y = format_outfiles,
    .f = ~write_bibliography(as.data.frame(..1), ..2, format = "ris")
    )
  
# convert to utf16 encoding
walk(
  .x = format_outfiles,
  .f = ~bibConvert(
    infile = .x,
    outfile = .x,
    encoding = rep("utf16", 2)
  ))
