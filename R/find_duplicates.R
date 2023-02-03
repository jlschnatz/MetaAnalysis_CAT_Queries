# Load packages and plan parallel multisession ----

if (!"pacman" %in% installed.packages()) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, revtools, fs, furrr, lubridate)

ms_cores <- availableCores() - 2
plan(multisession, workers = ms_cores)

list.files("data", recursive = TRUE, full.names = TRUE) %>%
  file_info() %>% view()

newest_search_path <- dir_ls(
  path = here("data"),
  recurse = TRUE,
  regexp = "complete_[0-9]{6}(\\.ris)|(\\.nbib)$"
) %>%
  tibble(filepath = .) %>%
  mutate(db_source = str_remove(basename(filepath), "_[0-9]{6}((\\.ris)|(\\.nbib))")) %>%
  mutate(date = ymd(str_extract(filepath, "[0-9]{6}"))) %>%
  slice_max(date, by = db_source)



<# Deduplication all files combined -----

df_combined_raw <- dir_ls(
  path = here("data"),
  recurse = TRUE,
  regexp = "(\\.ris$)|(\\.nbib$)"
) %>%
  future_map_dfr(read_bibliography, .id = "id_path")

find_dups <- df_combined_raw %>%
  find_duplicates()

df_combined_clean <- extract_unique_references(
  x = df_combined_raw, 
  matches = find_dups
  )

# save to .ris
write_bibliography(
  x = df_combined_clean,
  filename = here("data/complete_cleaned_query.ris"),
  format = "ris"
  )

# Count entries per file ----

list_bib <- dir_ls(
  path = here("data"),
  recurse = TRUE,
  regexp = "(\\.ris$)|(\\.nbib$)"
) %>%
  future_map(read_bibliography)

df_bib <- list_bib %>%
  future_map(
    ~find_duplicates(.x, to_lower = TRUE) %>%
      as.integer() %>%
      as_tibble() 
  ) %>%
  enframe(name = "id_path", value = "id_entry") %>% 
  unnest(id_entry) %>%
  rename(id_entry = value) %>%
  mutate(id_path = basename(id_path)) 


count_database_entries <- df_bib %>%
  group_by(id_path) %>%
  count() %>% 
  ungroup()

duplicates_sum <- df_bib %>%
  group_by(id_path) %>%
  summarise(n = sum(duplicated(id_entry)))

duplicates_ids <- df_ris %>%
  group_by(id_path) %>%
  mutate(is_duplicated = duplicated(id_entry)) %>% 
  filter(is_duplicated)  %>%
  ungroup()






