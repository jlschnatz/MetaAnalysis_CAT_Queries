# load packages

if(!"pacman" %in% installed.packages()) {install.packages("pacman")}
pacman::p_load(tidyverse, here, rbibutils, rentrez, wosr, rscopus, glue)

query <- read_lines(here("search_string.txt"))


# PubMed ----
pubmed_search <- entrez_search(db = "pubmed", term = query, use_history = TRUE)
pubmed_fetch <- entrez_fetch(
  db = "pubmed",
  web_history = pubmed_search$web_history, 
  rettype = "xml"
  )

write_lines(pubmed_fetch, here("data/pubmed/pubmed_query.txt"))
bibConvert(
  infile = here("data/pubmed/pubmed_query.txt"),
  outfile = here("data/pubmed/pubmed_query"), 
  outformat = "bib", 
  informat = "med"
  )

pubmed_fetch <- entrez_fetch(
  db = "pubmed",
  web_history = pubmed_search$web_history, 
  rettype = "medline"
)
write_lines(pubmed_fetch, here("data/pubmed/pubmed_query.txt"))

bibConvert(
  infile = here("data/pubmed/pubmed_query.txt"),
  outfile = here("data/pubmed/pubmed_query"), 
  outformat = "bib", 
  informat = "med"
)


# WOS ----

wosr::auth(
  username = "60fa4740-9903-11ed-9279-1d5d02ae1cf8",
  password = "20IwmbWOSe21#*"
)

# Scopus ----
# Scopus arbeitet mit AND NOT (statt NOT)

have_api_key()
search_restraint <- "TITLE"
query_scopus <- glue("{search_restraint}({query})") %>%
  str_replace(., "NOT", "AND NOT")


cat(query_scopus)
scopus_fetch <- scopus_search(
  query = query_scopus,
  count = 25,
  view = "STANDARD",
  wait_time = 0.1
)


pluck(scopus_fetch, "entries", 1, "pubmed-id")
scopus_fetch$entries



test <- abstract_retrieval(
  id = pluck(scopus_fetch, "entries", 1, "pubmed-id"),
  identifier = "pubmed_id"
  ) 
  


library(revtools)
library(tidyverse)
library(here)
library(bibliometrix)

read_bibliography(here("data/pubmed/pubmed_query"))

test <- convert2df(
  file = here("data/pubmed/pubmed_query.txt"),
  dbsource = "pubmed",
  format = "plaintext"
) %>%
  as_tibble()

write_csv(test, "test_csv.csv")

revtools::read_bibliography("test_csv.csv")

screen_topics()
