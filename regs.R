# library(readxl)
library(tidyverse)
library(rvest)
# library(XML)

# Load data and filter for the PDFs that we want to download
regs <- read.csv("DOCKET_EPA-HQ-OAR-2013-0602.csv", skip = 5, header = TRUE)
regs <- regs %>% filter(Document.Type != "PUBLIC SUBMISSIONS")
# regs <- regs %>% filter(DocumentType == "PUBLIC SUBMISSIOSN") # uncomment to download all of the random comments

pdflist <- c()

for(i in 126:nrow(regs)) {
  print(i)
  
  # designate url for current pdf to download
  url <- as.character(regs$Document.Detail[i])
  
  # rewrite the js file for phantom to update with the new url each time through the loop
  lines <- readLines("scrape_final.js")
  lines[1] <- paste0("var url ='", url ,"';")
  writeLines(lines, "scrape_final.js")
  
  # run phantom and virtually load the js website
  read_html(url)
  system("phantomjs scrape_final.js")
  pg <- read_html("1.html")
  
  # load the html version (after processing the js version) and grab the urls for all pdfs
  pdf.output <- html_nodes(pg, "a") %>% 
    html_attr("href") %>%
    grep("pdf", ., value = TRUE)
  
  doc.output <- html_nodes(pg, "a") %>%
    html_attr("href") %>%
    grep("docx", ., value = TRUE)
  
  output <- c(pdf.output, doc.output)
  
  # add to the list
  pdflist <- c(pdflist, output)
}

# Save the pdf list in case something goes wrong
write.csv(pdflist, "pdf_list.csv")

# Make directory to store pdfs
if (file.exists("regulations/")){
  print("Problem:  that file exists.  Do you want to overwrite the pdfs you've already downloaded?")
} else {
  dir.create("regulations/")
}

# Download pdf files to that directory
for(i in 1:length(pdflist)) {
  outfile <- strsplit(pdflist[i], "EPA")[[1]][2]
  outfile <- paste("EPA", strsplit(outfile, "&")[[1]][1], ".pdf", sep="")
  print(outfile)
  download.file(pdflist[i], destfile = paste("regulations/", outfile, sep=""), method = "wininet", mode ="wb")
}
