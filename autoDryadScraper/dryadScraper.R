# try automatic download of dryad data

#assertions:
# the dryad solr api is sadly no longer maintained
# datafiles can be accessed via the dryad doi url (e.g. https://datadryad.org/stash/dataset/doi:10.5061/dryad.k61qv)
# filename and download link are in node with attributes 'title' 'href' and 'target'
# paper doi is in a node with attributes 'href' and 'target' (so overlaps with datafile node)
# paper doi is always (?) first node with 'href' and 'target'
# parsing citation out of the htmltree (to generate the folder names as in the PruittDataReview/PruittData repo) is more annoying

require(RCurl)
require(xml2)
require(dplyr)
options(stringsAsFactors = FALSE)

## get list of dryad dois

dryadoiFilename <- "/home/anne/personal/pruitt_dryadois.csv"
baseDatafileURL <- "https://datadryad.org"
outputDir <- "/home/anne/personal/PruittData/"
oldwd <- getwd()

dir.create(outputDir)
setwd(outputDir)

# existing datadirs

datadirs <- list.files(outputDir)

# list of dryad dois
rawdois <- read.csv(dryadoiFilename) %>% filter(grepl("datadryad", dryadoi)) %>%
  mutate(shortdoi = basename(dryadoi))


for (i in 1:nrow(rawdois)){
 # get dryad page
  dryadpage <- xml2::read_html(rawdois$dryadoi[[i]])
  
 # extract paper doi
  paperdoi <- dryadpage %>% xml_find_first("//*[@href and @target]")  %>% xml_attrs()

# try to find the corresponding data dir. / have been replaced with _ in the dir names
  
  dirPaperdoi <- gsub("/","_", gsub("https://doi.org/","",paperdoi["href"]))
  datadir <- datadirs[grepl(dirPaperdoi, datadirs)]
  
  attrnodes <- dryadpage %>% xml_find_all("//*[@title and @href and @target]") %>% xml_attrs()
  
    # make outputdir or curl::curl_download complains
  if (length(datadir)>0) thisOutputDir <- paste0(datadir,"/DryadAutoScrape/",rawdois$shortdoi[[i]] ) else
    thisOutputDir <- paste("DryadAutoScrapeUnmatched/",rawdois$shortdoi[[i]]) 
    dir.create(thisOutputDir, recursive=TRUE)
    lapply(attrnodes, function(x) {
      destfile <-paste0(thisOutputDir,"/",x["title"])
      if (file.exists(destfile)) destfile <- paste0(destfile,"_duplicate_",basename(x["href"]))
      curl::curl_download(paste0(baseDatafileURL,x["href"]), destfile)
    })
}

setwd(oldwd)