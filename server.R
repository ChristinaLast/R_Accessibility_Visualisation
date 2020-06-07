library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)



# Leaflet bindings are a bit slow; for now we'll just sample to compensate
allcity <- allcity
#removing the spatial data for data explorer
cols_to_keep = c('City_name', 'Tot_r_10', 'Tot_r_20', 'Tot_r_50', 'ht_ami', 'population', 'co2_per_hh', 'autos_per_', 'pct_transi', 'res_densit', 'h_cost', 'Black_Afri', 'Hispanic', 'White_Alon', 'Tot_r_20_seg', 'ht_ami_seg','kind', 'sqmi', 'latitude', 'longitude')
allcity_nogeom <- allcity[cols_to_keep]
allcity_nogeom <- as.data.frame(allcity_nogeom)

# By ordering by centile, we ensure that the (comparatively rare) SuperZIPs
# will be drawn last and thus be easier to see
#




function(input, output, session) {
  
  ## Interactive Map ###########################################
  
  # Create the map
  output$map <- renderLeaflet({
    leaflet(allcity) %>%
      addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
      ) %>%
      setView(lng = -118.2437, lat = 34.0522, zoom = 10)
  })
  
  # A reactive expression that returns the set of zips that are
  # in bounds right now
  # A reactive expression that returns the set of zips that are
  # in bounds right now
  
  # Precalculate the breaks we'll need for the two histograms
  tot20Breaks <- hist(plot = FALSE, allcity$Tot_r_20, breaks = 20)$breaks
  
  output$histCity <- renderPlot({
    
    hist(allcity$Tot_r_20,
         breaks = tot20Breaks,
         main = "City level Accessibility (no. of jobs)",
         xlab = "Percentile",
         col = '#00DD00',
         border = 'white')
  })
  
  output$scatterTransit <- renderPlot({
    # If no zipcodes are in view, don't plot
    print(xyplot(allcity$Tot_r_20 ~ allcity$pct_transi, data = allcity, xlim = range(allcity$pct_transi), ylim = range(allcity$Tot_r_20), xlab="Percentage (%) using transit", ylab="Jobs accessible 20mins"))
  
  })
  
  # This observer is responsible for maintaining the circles and legend,
  # according to the variables the user has chosen to map to color and size.
  observe({
    colorBy <- input$color

    if (colorBy == "Tot_r_20_seg") {
      # Color and palette are treated specially in the "superzip" case, because
      # the values are categorical instead of continuous.
      colorData <- allcity[[colorBy]]
      pal <- colorFactor("viridis", colorData)
    } else if (colorBy == "ht_ami_seg") {
      colorData <- allcity[[colorBy]]
      pal <- colorFactor("viridis", colorData)
    } else {
      colorData <- allcity[[colorBy]]
      pal <- colorBin("viridis", colorData, 7, pretty = FALSE)
    }
    
    leafletProxy("map", data = allcity) %>%
      addPolygons(stroke = FALSE, smoothFactor = 0.3, fillOpacity = 1,
                  fillColor =pal(colorData),
                  popup = ~paste("<b>City: </b>", allcity[['City_name']],"<br/>",
                                 "<b>Population: </b>", allcity[['population']],"<br/>",
                                 "<b>Total jobs accessible (20 mins travel time): </b>", formatC(colorData, big.mark = ","),
                                 "<br/>","<b>Household + transport cost (% income): </b>",allcity[['ht_ami_seg']],
                                 "<br/>","<b>Hiscpanic population (count): </b>",allcity[['Hispanic']])) %>%
      addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
                layerId="colorLegend")
  })

  ## Data Explorer ###########################################
  
  observe({
    cities <- if (is.null(input$kind)) character(0) else {
      filter(allcity_nogeom, kind %in% input$kind) %>%
        `$`('City') %>%
        unique() %>%
        sort()
    }
    stillSelected <- isolate(input$City_name[input$City_name %in% cities])
    updateSelectizeInput(session, "cities", choices = cities,
                         selected = stillSelected, server = TRUE)
  })
  
  
  observe({
    if (is.null(input$goto))
      return()
    isolate({
      map <- leafletProxy("map")
      dist <- 0.5
      lat <- input$goto$latitude
      lng <- input$goto$longitude
      map %>% fitBounds(lng - dist, lat - dist, lng + dist, lat + dist)
    })
  })
  
  output$citytable <- DT::renderDataTable({
    df <- allcity_nogeom %>%
      filter(
        Tot_r_20 >= input$minTot_r_20,
        Tot_r_20 <= input$maxTot_r_20,
      ) %>%
      mutate(Action = paste('<a class="go-map" href="" data-lat="', latitude, '" data-long="', longitude, '" data-city="', City_name, '"><i class="fa fa-crosshairs"></i></a>', sep=""))
    action <- DT::dataTableAjax(session, df, outputId = "citytable")
    
    DT::datatable(df, options = list(ajax = list(url = action)), escape = FALSE)
  })
}
