####################################################################
#' Frequencies Calculations
#' 
#' This function lets the user group, count and calculate percentages and cumulatives
#' 
#' @export
freqs = function(data, ..., plot=F) {

  suppressMessages(require(dplyr))

  output <- data %>%
    dplyr::group_by_(.dots = lazyeval::lazy_dots(...)) %>%
    dplyr::tally() %>% dplyr::arrange(desc(n)) %>%
    dplyr::mutate(p = round(100*n/sum(n),2), pcum = cumsum(p))
  return(output)
}


####################################################################
#' Convert year month format YYYY-MM
#' 
#' This function lets the user convert a year month format into YYYY-MM
#' 
#' @export
year_month = function(date) {

  suppressMessages(require(lubridate))
  suppressMessages(require(stringr))

  return(paste(
    year(date),
    str_pad(month(date), 2, pad = "0"),
    sep="-"))
}


####################################################################
#' Analyze NAs in a data.frame
#' 
#' This function lets the user analyze NAs in a data.frame using 
#' VIM and funModeling libraries
#' 
#' @export
nas = function(df, print = TRUE) {

  require(dplyr)
  require(VIM)
  require(funModeling)

  nas <- df_status(df, print=FALSE) %>% filter(q_na > 0) %>% arrange(desc(q_na))
  subset <- subset(df, select=c(nas$variable))
  VIM::aggr(subset, col=c('navyblue','red'), numbers=TRUE, sortVars=TRUE,
            labels=names(data), cex.axis=.7, gap=2,
            ylab=c("Histogram of missing data","Pattern"))
}


####################################################################
#' Count all categories on factor variables
#' 
#' This function lets the user count all distinct categories on factor variables
#' 
#' @export
categoryCounter <- function (df) {

  suppressMessages(require(dplyr))

  cats <- df %>% select_if(is.factor)
  result <- c()

  for (i in 1:ncol(cats)) {
    x <- freqs(cats, cats[,i])
    y <- colnames(cats)[i]
    x <- cbind(variable = y, x)
    result <- rbind(result, x)
  }
  result <- rename(result, category = `cats[, i]`)
  return(result)
}


####################################################################
#' Reduce categorical values
#' 
#' This function lets the user reduce categorical values in a vector
#' 
#' @export
categ_reducer <- function(vector, nmin = 0, pmin = 0, pcummax = 100, top = NA, other_label = "other") {
  require(dplyr)
  df <- data.frame(name = vector) %>% lares::freqs(., name)
  if (!is.na(top)) {
    top <- df %>% slice(1:top)
  } else {
    top <- df %>% filter(n >= nmin & p >= pmin & p <= pcummax) 
  }
  vector <- ifelse(vector %in% top$name, as.character(vector), other_label)
  return(vector)
}


####################################################################
#' Normalize values
#' 
#' This function lets the user normalize numerical values into the 0 to 1 range
#' 
#' @export
normalize <- function(x) {
  if (is.numeric(x)) {
    x <- (x-min(x)) / (max(x)-min(x))
    return(x) 
  } else {
    stop("Try with a numerical vector!")
  }
}


####################################################################
#' Convert a vector into a comma separated text
#' Convert a vector into a comma separated text
#' @export
vector2text <- function(vector, sep=", ") {
  output <- paste(shQuote(vector), collapse=sep)
  return(output)
}


####################################################################
#' Clean text
#' 
#' This function lets the user clean text
#' 
#' @export
cleanText <- function(d) {
  d <- as.character(d)
  # Only alphanumeric characters and no accents/symbols on letters
  output <- tolower(gsub("[^[:alnum:] ]", "", iconv(d, from="UTF-8", to="ASCII//TRANSLIT")))
  return(output)
}


####################################################################
#' Find country from a given IP
#' 
#' This function lets the user find a country from a given IP Address
#' 
#' @export
ip_country <- function(ip) {
  require(rvest)
  require(dplyr)
  
  ip <- ip[!is.na(ip)]
  ip <- ip[grep("^172\\.|^192\\.168\\.|^10\\.", ip, invert = T)]
  
  countries <- data.frame(ip = c(), country = c())
  for(i in 1:length(ip)) {
    message(paste("Searching for", ip[i]))
    url <- paste0("https://db-ip.com/", ip[i])
    scrap <- read_html(url) %>% html_nodes('.card-body tr') %>% html_text()
    country <- gsub("Country", "", trimws(scrap[grepl("Country", scrap)]))
    result <- cbind(ip = ip[i], country = country)
    countries <- rbind(countries, result)
  } 
  return(countries)
}


####################################################################
#' Distance from specific point to line
#' 
#' This function lets the user calculate the mathematical linear distance 
#' Between a specific point and a line (given geometrical 3 points)
#' 
#' @param a Vector. Coordinates of the point from which we want to measure the distance
#' @param b Vector. Coordinates of 1st point over the line
#' @param c Vector. Coordinates of 2st point over the line
#' @export
dist2d <- function(a, b = c(0, 0), c = c(1, 1)) {
  v1 <- b - c
  v2 <- a - b
  m <- cbind(v1, v2)
  d <- abs(det(m)) / sqrt(sum(v1 * v1))
}


####################################################################
#' Nicely Format Numerical Values
#' 
#' This function lets the user format numerical values nicely
#' 
#' @param x Numerical Vector
#' @param decimals Integer. Amount of decimals to display
#' @param type Integer. 1 for International standards. 2 for American Standards.  
#' @export
formatNum <- function(x, decimals = 2, type = 1) {
  if (type == 1) {
    format(round(as.numeric(x), decimals), nsmall=decimals, big.mark=".", decimal.mark = ",")
  } else {
    format(round(as.numeric(x), decimals), nsmall=decimals, big.mark=",", decimal.mark = ".") 
  }
}


####################################################################
#' One Hot Encoding for a Vector with Comma Separated Values
#' 
#' This function lets the user do one hot encoding on a variable with comma separated values
#' 
#' @param df Vector or Dataframe. Contains different variables in each column, separated by a specific character
#' @param variables Character. Which variables should we split into new columns
#' @param sep Character. Which character separates the elements
#' @export
one_hot_encoding_commas <- function(df, variables, sep=","){
  # Note that variables must be provided in strings
  for (var in seq_along(variables)) {
    variable <- variables[var]
    df[df==""|is.na(df)] <- "NAs" # Handling missingness
    x <- as.character(unique(df[[variable]]))
    x <- gsub(" ", "", toString(x)) # So it can split on strings like "A1,A2" and "A1, A2"
    x <- unlist(strsplit(x, sep))
    x <- paste(variable, x, sep="_")
    new_columns <- sort(unique(as.character(x)))
    if (length(new_columns) >= 15) {
      message(paste("You are using more than 15 unique values on this variable:", variable))
    }
    for (i in seq_along(new_columns)){
      df$temp <- NA
      df$temp <- ifelse(grepl(new_columns[i], df[[variable]]), TRUE, FALSE)
      colnames(df)[colnames(df) == "temp"] <- new_columns[i]
    }
  }
  return(df)
}
