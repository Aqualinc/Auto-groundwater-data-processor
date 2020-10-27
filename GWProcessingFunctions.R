

#' Import the Solist  ".xle" file (which is in xml format) and turn into a zoo object
#' 
#'   This function reads in a SOLIST level logger xml file from the Christchurch shallow bore network, and converts it into a zoo timeseries of depth and temperature.
#'   If the LEVEL data are in psi or kPa then it is converted to metres head.
#' @param XMLFile a timeseries object in xml format
#' @value A list which includes a POSIXct zoo object of LEVEL (m of head) and temperature (oC), a Battery Level value, Location description string, APP number, Zone number
#' @keywords xml
#' @export
#' @examples
#' ReadXMLData() 

ReadXMLData <- function(XMLFile) {

  #Test for and load any libraries that are needed
  if (!require(xml2)) install.packages('xml2'); library(xml2)
  if (!require(zoo)) install.packages('zoo'); library(zoo)
  
  #Define the multipliers to convert from kPa or psi air pressure to metres of head
  ConversionFactors <- c(kPa=0.10199773339984, psi = 0.70324961490205) #from https://www.convertunits.com
  
  #Load the data
   data <- read_xml(XMLFile,encoding = "ISO-8859-1")

   #Get the battery level
   BatteryLevel <- xml_double(xml_child(data,search="Instrument_info/Battery_level"))
   #Get the Location description
   LocationDescription <- xml_text(xml_child(data,search="Instrument_info_data_header/Location"))
   #Get the Project ID
   ProjectID <- xml_text(xml_child(data,search="Instrument_info_data_header/Project_ID"))
   #Extract the APP number from the Project ID. This is assumed to be the first 1 to 3 digits after the case insentive letters "APP"
   APPNumber <- as.numeric(sub(".*APP\\s*([1-9][0-9]{0,2}).*","\\1", ProjectID, ignore.case = TRUE))
   #Extract the Zone number from the Project ID. This is assumed to be the first single digit number after the case insensitive word "zone"
   ZoneNumber <- as.numeric(sub(".*Zone\\s*([1-9]).*","\\1", ProjectID, ignore.case = TRUE))
   
   #Get the time series of the first two channels, date and time. These are in the "Data" child node.
   Date <- xml_text(xml_find_all(xml_child(data,search="Data"), ".//Date"))
   Time <- xml_text(xml_find_all(xml_child(data,search="Data"), ".//Time"))
   ch1 <- xml_double(xml_find_all(xml_child(data,search="Data"), ".//ch1"))
   ch2 <- xml_double(xml_find_all(xml_child(data,search="Data"), ".//ch2"))

   #Get the name and units of the channels. They should be "LEVEL" and "TEMPERATURE.", but which is which is not necesarily constant.
   ch1ID <- xml_text(xml_child(data,search="Ch1_data_header/Identification"))
   ch1Units <- xml_text(xml_child(data,search="Ch1_data_header/Unit"))
   
   ch2ID <- xml_text(xml_child(data,search="Ch2_data_header/Identification"))
   ch2Units <- xml_text(xml_child(data,search="Ch2_data_header/Unit"))
   
   #Find which channel is LEVEL and which is TEMPERATURE. Case insensitive match.
   LEVELChannel <- which(toupper(c(ch1ID,ch2ID)) == "LEVEL")
   TEMPERATUREChannel <- which(toupper(c(ch1ID,ch2ID)) == "TEMPERATURE")
   
   #Rename the channel data to their respective names
   TEMPERATURE <- get(paste0("ch",TEMPERATUREChannel))
   LEVEL <- get(paste0("ch",LEVELChannel))
   
   LEVELUnits <- c(ch1Units,ch2Units)[LEVELChannel]
   #Check the units of the LEVEL channel and convert to metres head if necesary
   if( LEVELUnits != "m") LEVEL <- LEVEL * ConversionFactors[LEVELUnits]
   
   #Turn the dates and time into a POSIXct object
   DateTime <- as.POSIXct(paste(Date,Time),format = "%Y/%m/%d %H:%M:%S", tz = "Etc/GMT-12")
  
   #Create a zoo timeseries
   OutputData <- zoo(data.frame(LEVEL=LEVEL,TEMPERATURE=TEMPERATURE),order.by = DateTime)
   OutputList <- list(Data = OutputData, Battery = BatteryLevel, Location = LocationDescription, APP = APPNumber, Zone = ZoneNumber)
   return(OutputList)
}

#' Import a Solist  ".csv" (comma-separated-variable text) file and turn into a zoo object
#' 
#'   This function reads in a SOLIST level logger csv file from the Christchurch shallow bore network, and converts it into a zoo timeseries of depth and temperature.
#'   If the LEVEL data are in psi or kPa then it is converted to metres head.
#' @param csvFile a timeseries object in csv format
#' @value A list which includes a POSIXct zoo object of LEVEL (m of head) and temperature (oC), a Battery Level value, Location description string, APP number, Zone number
#' @keywords csv
#' @export
#' @examples
#' ReadXMLData() 

ReadcsvData <- function(csvFile) {

  #Test for and load any libraries that are needed
  if (!require(zoo)) install.packages('zoo'); library(zoo)
  
  #Define the multipliers to convert from kPa or psi air pressure to metres of head
  ConversionFactors <- c(kPa=0.10199773339984, psi = 0.70324961490205) #from https://www.convertunits.com
  
  #Load the header information from the file
  HeaderData <- readLines(csvFile, n = 11)
  
  
  #Load the data
  data <- read.table(csvFile,sep=",",skip=which(HeaderData  == "TEMPERATURE")+1, header=TRUE,colClasses = c("character","character",rep("numeric",3)))
  
  #Get the battery level
  BatteryLevel <- NA
  
  #Get the Location description. This is the line immediately after the line called "Location:"
  LocationDescription <- HeaderData[which(HeaderData == "Location:") + 1]
  
  #Get the Project ID
  ProjectID <- HeaderData[which(HeaderData == "Project ID:")+1]
  #Extract the APP number from the Project ID. This is assumed to be the first 1 to 3 digits after the case insentive letters "APP"
  APPNumber <- as.numeric(sub(".*APP\\s*([1-9][0-9]{0,2}).*","\\1", ProjectID, ignore.case = TRUE))
  #Extract the Zone number from the Project ID. This is assumed to be the first single digit number after the case insensitive word "zone"
  ZoneNumber <- as.numeric(sub(".*Zone\\s*([0-9]).*","\\1", ProjectID, ignore.case = TRUE))

  LEVELUnits <- sub(".*: ","",HeaderData[which(HeaderData == "LEVEL")+ 1])
  #Check the units of the LEVEL channel and convert to metres head if necesary
  if( LEVELUnits != "m") data$LEVEL <- data$LEVEL * ConversionFactors[LEVELUnits]
  
  #Turn the dates and time into a POSIXct object. Annoyingly the date format is different compared to the .xle files.
  DateTime <- as.POSIXct(paste(data$Date,data$Time),format = "%d/%m/%Y %H:%M:%S", tz = "Etc/GMT-12")
  
  #Create a zoo timeseries
  OutputData <- zoo(data.frame(LEVEL=data$LEVEL,TEMPERATURE=data$TEMPERATURE),order.by = DateTime)
  OutputList <- list(Data = OutputData, Battery = BatteryLevel, Location = LocationDescription, APP = APPNumber, Zone = ZoneNumber)
  return(OutputList)
}



#' Barometric Correction
#'
#' This function accepts a zoo timeseries of groundwater pressure (in m head), a zoo timeseries of barometric pressure, and the depth to the sensor (in -ve metres) and calculates the depth to the water level (as -ve metres)
#' @param GWSeries a timeseries object
#' @param AirPressureSeries a timeseries object of air pressure values
#' @value A timeseries object of the groundwater levels after compensation for air pressure variability
#' @keywords groundwater
#' @export
#' @examples
#' BarometricCorrection()


BarometricCorrection <- function(GWSeries, AirPressureSeries, SensorLevelBelowSurface = 0) {
  
  #Test for and load any libraries that are needed
  if (!require(zoo)) install.packages('zoo'); library(zoo)
  

  #Check that the groundwater time series is wholly within the range of the barometric pressure series
  GWRange <- range(index(GWSeries))
  BaroRange <- range(index(AirPressureSeries))
  if (GWRange[1] < BaroRange[1] | GWRange[2] > BaroRange[2]) warning('groundwater time series is not wholly within the time range of the air pressure time series')

  #For every timestep in the groundwater series, find or estimate the barometric pressure. This is required in case the timestamps do not exactly allign, or if a different sampling frequency is used between the groundwater and air pressure series.
  GWAndBaro <- merge(GWSeries,AirPressureSeries)
  GWAndBaro$AirPressureSeries <- na.approx(GWAndBaro$AirPressureSeries, method = "linear", na.rm = FALSE)
  
  #Compensate the groundwater LEVELs by subtracting the atmospheric pressure
  AirPressureCompensated <- with(GWAndBaro, GWSeries - AirPressureSeries)
  
  LEVELToWL <- SensorLevelBelowSurface - AirPressureCompensated
  
  HeightAboveGround <- -LEVELToWL
  
  #Remove any NAs
  HeightAboveGround <- HeightAboveGround[complete.cases(HeightAboveGround)]

  return(HeightAboveGround)
}

#' Barometric Data Merging
#'
#' This function finds the barometric files within a vector of file names and merges ones from the same site
#' @param DataDirectory the directory from which to search for air pressure files
#' @value A list of air pressure time series data in metres of head
#' @keywords groundwater
#' @export
#' @examples
#' BarometricCorrection()
#' 
BaroDataMerging <- function(DataDirectory) {
  #Test for and load any libraries that are needed
  if (!require(tools)) install.packages('tools'); library(tools)
  
  #Get all the airpressure logger files to process
  BaroFilesToProcess <- list.files(path = DataDirectory, pattern = '(?i)^.*BARO.*$', recursive = TRUE, full.names = TRUE)
  BaroData <- lapply(BaroFilesToProcess, function(SingleBaroFile) {
    if(file_ext(SingleBaroFile) == "xle") OutData <- ReadXMLData(SingleBaroFile)
    if(file_ext(SingleBaroFile) == "csv") OutData <- ReadcsvData(SingleBaroFile)
    return(OutData)
    })
  
  Zones <- sapply(BaroData, '[[','Zone')
  
  #Work through each zone and build up a master barometric file. Zone 0 is a special case invented to signify all zones.
  ZoneBaroData <- lapply(unique(Zones), function(Zone) {
    #Extract all the data files associated with the zone of interest, and any in zone 0.
    ListIndices <- which(Zones == Zone)
    BarosOfInterest <- BaroData[ListIndices]
    LEVELsOfInterest <- lapply(BarosOfInterest, function(x) x[['Data']]$'LEVEL')
    #Merge the data, then find the row averages if there are multiple series. This covers the possibility of overlapping times
    MergedData <- do.call(merge, LEVELsOfInterest)
    if(!is.null(ncol(MergedData))) MergedData <- zoo(rowMeans(MergedData,na.rm=TRUE), index(MergedData))
    return(MergedData)
  })
  
  
  names(ZoneBaroData) <- paste0("Zone",unique(Zones))
  return(ZoneBaroData)
}

