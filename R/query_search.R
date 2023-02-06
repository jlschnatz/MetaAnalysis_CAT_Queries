# Load package ----

if(!"pacman" %in% installed.packages()) {install.packages("pacman")}
pacman::p_load(tidyverse, here, rbibutils, rentrez, glue, lubridate)

query <- read_lines(here("search_string.txt"))
cat(query)
# PubMed ----

pubmed_search <- entrez_search(db = "pubmed", term = query, use_history = TRUE)
pubmed_fetch <- entrez_fetch(
  db = "pubmed",
  web_history = pubmed_search$web_history, 
  rettype = "medline"
)

format_today <- format(today(), "%y%m%d")
format_file_pubmed <- as.character(glue(here("data/pubmed/pubmed_query_complete_{format_today}.txt")))

write_lines(pubmed_fetch, format_file_pubmed)


file_txt <- list.files(here("data/pubmed/"), pattern = "*.txt", full.names = TRUE) 
file_ris <- str_replace(file_txt, ".txt$", ".ris")

# covert to .ris file
file.rename(from = file_txt, to = file_ris)

