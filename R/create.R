#' Create fish database
#'
#' Function to create the arrow dataset. Currently hard coded
#' to look at data stored on the KNB. Eventually will look for data
#' on EDI. Only used to generate the datasets in a local cache.
#' 
#' @import arrow
#' @return NULL
#' @export
#'

create_fish_db <- function(){
    
    # set timeout to something high
    timeout <- getOption('timeout')
    options(timeout = 3600)

    
    # set up cache
    if (!(dir.exists(rappdirs::user_cache_dir("deltafish")))){
        dir.create(rappdirs::user_cache_dir("deltafish"), recursive = TRUE)
    } else if (dir.exists(rappdirs::user_cache_dir("deltafish")) &
                          length(dir(rappdirs::user_cache_dir("deltafish"), recursive = TRUE) > 0)){
        message("Fish db already exists in cache.")
        return(rappdirs::user_cache_dir("deltafish"))
    }
    
    fish_pid <- "urn%3Auuid%3A0b5697ac-ee44-42c6-90f3-799eb9e5970e"
    survey_pid <- "urn%3Auuid%3Ade32988a-99e9-4887-bb1f-1bd099314ada"
    l_pid <- "urn%3Auuid%3A0b0f4e85-23b4-423c-83d1-a9005c587b9f"
    base_url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/"
    
    message("Downloading main fish dataset (~5 GB)")
    download.file(paste0(base_url, fish_pid), mode="wb", method="curl", destfile=file.path(tempdir(), "fish.csv"))
    download.file(paste0(base_url, survey_pid), mode="wb", method="curl", destfile=file.path(tempdir(), "survey.csv"))
    download.file(paste0(base_url, l_pid), mode="wb", method="curl", destfile=file.path(tempdir(), "legth_conv.csv"))
    
    message("Reading fish dataset")
    fish <- readr::read_csv(file.path(tempdir(), "fish.csv"), progress = TRUE, show_col_types = FALSE)
    surv <- utils::read.csv(file.path(tempdir(), "survey.csv"))
    lconv <- readr::read_csv(file.path(tempdir(), "legth_conv.csv"), progress = FALSE, show_col_types = FALSE)
    
  
    
    s <- arrow::schema(Source = arrow::string(),
                       Station = arrow::string(),
                       Latitude = arrow::float(),     
                       Longitude = arrow::float(),
                       Date = arrow::string(),
                       Datetime = arrow::string(),
                       Survey  = arrow::int64(),
                       Depth  = arrow::float(),
                       SampleID  = arrow::large_utf8(),
                       Method  = arrow::string(),
                       Tide   = arrow::string(),
                       Sal_surf   = arrow::float(),
                       Temp_surf = arrow::float(),
                       Secchi = arrow::float(),
                       Tow_duration = arrow::float(),
                       Tow_area  =arrow::float(),
                       Tow_volume =arrow::float(),
                       Tow_direction = arrow::string())
    
    message("Setting up arrow tables")
    
    surv <- arrow::arrow_table(surv, schema = s)
    
    

    
    message("Writing arrow tables to cache")
    arrow::write_dataset(surv, file.path(rappdirs::user_cache_dir("deltafish"), "survey"), partitioning = "Source", existing_data_behavior = "overwrite")
    arrow::write_dataset(fish, file.path(rappdirs::user_cache_dir("deltafish"), "fish"), partitioning = "Taxa")
    arrow::write_dataset(lconv, file.path(rappdirs::user_cache_dir("deltafish"), "length_conversion"))
    
    # reset timeout
    options(timeout = timeout)
    gc()
    
    return(rappdirs::user_cache_dir("deltafish"))
}



