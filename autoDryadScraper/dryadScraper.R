# try automatic download of dryad data

#assertions:
# the dryad solr api is sadly no longer maintained
# datafiles can be accessed via the dryad doi url (e.g. https://datadryad.org/stash/dataset/doi:10.5061/dryad.k61qv)
# filename and download link are in node with attributes 'title' 'href' and 'target'
# parsing citation out of the htmltree (to generate the folder names as in the PruittDataReview/PruittData repo) is more annoying

require(RCurl)
require(xml2)
require(dplyr)
options(stringsAsFactors = FALSE)

## get list of dryad dois

dryadoiFilename <- "/home/anne/personal/pruitt_dryadois.csv"
baseDatafileURL <- "https://datadryad.org"
outputDir <- "/home/anne/personal/testScraper/"
oldwd <- getwd()

dir.create(outputDir)
setwd(outputDir)


rawdois <- read.csv(dryadoiFilename) %>% filter(grepl("datadryad", dryadoi)) %>%
  mutate(shortdoi = basename(dryadoi))


for (i in 1:nrow(rawdois)){
 
    # make outputdir or curl::curl_download complains
    thisOutputDir <- rawdois$shortdoi[[i]] 
    dir.create(thisOutputDir)
    dryadpage <- xml2::read_html(rawdois$dryadoi[[i]])
    attrnodes <- dryadpage %>% xml_find_all("//*[@title and @href and @target]") %>% xml_attrs()
    lapply(attrnodes, function(x) {
      destfile <-paste0(thisOutputDir,"/",x["title"])
      if (file.exists(destfile)) destfile <- paste0(destfile,"_duplicate_",basename(x["href"]))
      curl::curl_download(paste0(baseDatafileURL,x["href"]), destfile)
    })
}

setwd(oldwd)