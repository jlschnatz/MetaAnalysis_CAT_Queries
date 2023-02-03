if (!"pacman" %in% installed.packages()) {
  install.packages("pacman")
}
pacman::p_load(tidyverse, here, revtools, fs, furrr, tictoc)

ms_cores <- availableCores() - 2
plan(multisession, workers = ms_cores)


tic()
list_ris <- dir_ls(
  path = here("data"),
  recurse = TRUE,
  regexp = "\\.ris$"
) %>%
  future_map(
    ~ read_bibliography(.x) %>%
      find_duplicates(to_lower = TRUE) %>%
      as.integer() %>%
      as_tibble() 
    ) %>%
  enframe(name = "id_path", value = "id_entry") %>% 
  unnest(id_entry) %>%
  rename(id_entry = value) %>%
  mutate(id_path = basename(id_path)) 
toc()



count_database_entries <- list_ris %>%
  group_by(id_path) %>%
  count()

duplicates_sum <- list_ris %>%
  group_by(id_path) %>%
  summarise(n = sum(duplicated(id_entry)))

duplicates_ids <- list_ris %>%
  group_by(id_path) %>%
  mutate(is_duplicated = duplicated(id_entry)) %>% 
  filter(is_duplicated)  %>%
  ungroup()

