options(stringsAsFactors = F)
library("magrittr")

# https://www.nature.com/nature/for-authors/formatting-guide
# Nature’s standard figure sizes are 89 mm (single column) and 183 mm (double column) and the full depth of the page is 247 mm.

# single_column_width <- 89
# single_column_height <- 89
double_column_width <- 183
double_column_height <- 183
full_page_height <- 247
full_page_width <- 247
small_golden_rectangle_height <- 45
small_golden_rectangle_width <- 27.8

large_golden_rectangle_height <- 72.8
large_golden_rectangle_width <- 45

# ---------------------------------------------------------------------------

intermediate_directory <- here::here("intermediate_directory") %T>%
    dir.create(., showWarnings = F, recursive = T)

graph_output_directory <- file.path(getwd(), "graph_output_directory")  %T>%
    dir.create(., showWarnings = F, recursive = T)
text_output_directory <- file.path(getwd(), "text_output_directory")  %T>%
    dir.create(., showWarnings = F, recursive = T)


# Determine the target directory
target_directory <- file.path(
    "..",
    "merged_both_therapy",
    "03_report_files",
    "MAPKi_microarray_analysis"
)
