

#' Import the Solist  ".xle" file (which is in xml format) and turn into a zoo object
#' 
#'   This function reads in a SOLIST level logger xml file and converts it into a zoo timeseries of depth and temperature
#' @param XMLData a timeseries object in xml format
#' @value A timeseries object 
#' @keywords xml
#' @export
#' @examples
#' ReadXMLData() 

ReadXMLData <- function(XMLFile) {

  #Test for and load any libraries that are needed
  if (!require(xml2)) install.packages('xml2'); library(xml2)
  if (!require(zoo)) install.packages('zoo'); library(zoo)
  
  #Load the data
   data <- read_xml(XMLFile,encoding = "ISO-8859-1")
   
   #Get the timeseries of temperature, depth, date and time. These are in the "Data" child node.
   Date <- xml_text(xml_find_all(xml_child(data,search="Data"), ".//Date"))
   Time <- xml_text(xml_find_all(xml_child(data,search="Data"), ".//Time"))
   Depth <- xml_double(xml_find_all(xml_child(data,search="Data"), ".//ch1"))
   Temperature <- xml_double(xml_find_all(xml_child(data,search="Data"), ".//ch2"))
   
   #Turn the dates and time into a POSIXct object
   DateTime <- as.POSIXct(paste(Date,Time),format = "%Y/%m/%d %H:%M:%S", tz = "Etc/GMT-12")
  
   #Create a zoo timeseries
   OutputData <- zoo(data.frame(Depth=Depth,Temperature=Temperature),order.by = DateTime)
   return(OutputData)
}


#' Barometric Correction
#'
#' This function accepts a zoo timeseries of groundwater levels and a zoo timeseries of barometric pressure and adjusts the groundwater levels to account for atmospheric pressure variations
#' @param GWSeries a timeseries object
#' @param AirPressureSeries a timeseries object of air pressure values
#' @value A timeseries object of the groundwater levels after compensation for air pressure variability
#' @keywords groundwater
#' @export
#' @examples
#' BarometricCorrection()


BarometricCorrection <- function(GWSeries, AirPressureSeries) {
  
  #Test for and load any libraries that are needed
  if (!require(zoo)) install.packages('zoo'); library(zoo)

  #Check that the groundwater time series is wholly within the range of the barometric pressure series
  GWRange <- range(index(GWSeries))
  BaroRange <- range(index(AirPressureSeries))
  if (GWRange[1] < BaroRange[1] | GWRange[2] > BaroRange[2]) warning('groundwater time series is not wholly within the time range of the air pressure time series')
  
  #For every timestep in the groundwater series, find or estimate the barometric pressure. This is required in case the timestamps do not exactly allign, or if a different sampling frequency is used between the groundwater and air pressure series.
  GWAndBaro <- merge(GWSeries,AirPressureSeries)
  GWAndBaro$AirPressureSeries <- na.approx(GWAndBaro$AirPressureSeries, method = "linear", na.rm = FALSE)
  
  #Compensate the groundwater depths by subtracting the atmospheric pressure
  Compensated <- with(GWAndBaro, GWSeries - AirPressureSeries)
  
  #Remove any NAs
  Compensated <- Compensated[complete.cases(Compensated)]

  return(Compensated)
}


#Load some sample data
DataDirectory <- "G:\\ARL Projects\\WL Projects\\WL18036_EQC Earthquake Commission\\Data\\HighResolutionData\\FromT_T_January2019\\DH1 - DH4\\DH1-DH4 Raw\\Data Harvest 1\\Zone 1"
BaroFile <- file.path(DataDirectory,"221BARO_10_03_2017.xle")
GroundwaterFile <- file.path(DataDirectory,"221_10_03_2017.xle")
#221BARO_10_03_2017.xle
#44_23_07_2017.xle
#221_10_03_2017.xle

Barometric <- ReadXMLData(BaroFile)
Groundwater <- ReadXMLData(GroundwaterFile)
