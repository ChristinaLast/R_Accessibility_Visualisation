library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)


# Leaflet bindings are a bit slow; for now we'll just sample to compensate
allcity <- allcity_unique

# By ordering by centile, we ensure that the (comparatively rare) SuperZIPs
# will be drawn last and thus be easier to see

function(input, output, session) {
  
  ## Interactive Map ###########################################
  
  # Create the map
  output$map <- renderLeaflet({
    leaflet() %>%
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
         xlim = range(allcity$Tot_r_20),
         col = '#00DD00',
         border = 'white')
  })
  
  output$scatterTransit <- renderPlot({
    # If no zipcodes are in view, don't plot
    print(xyplot(Tot_r_20 ~ pct_transi, data = allcity, xlim = range(allcity$pct_transi), ylim = range(allcity$Tot_r_20)))
  })
  
  # This observer is responsible for maintaining the circles and legend,
  # according to the variables the user has chosen to map to color and size.
  observe({
    colorBy <- input$color

    if (colorBy == "Total_Accessibility_20_seg") {
      # Color and palette are treated specially in the "superzip" case, because
      # the values are categorical instead of continuous.
      colorData <- allcity[[colorBy]]
      pal <- colorFactor("viridis", colorData)
    } else if (colorBy == "HH_Trans_cost_perc_income_seg") {
      colorData <- allcity[[colorBy]]
      pal <- colorFactor("viridis", colorData)
    } else {
      colorData <- allcity[[colorBy]]
      pal <- colorBin("viridis", colorData, 7, pretty = FALSE)
    }
    
    leafletProxy("map", data = allcity) %>%
      clearShapes() %>%
      addCircles(lng=~latitude, lat=~longitude, radius=3000, layerId=~City_name,
                 stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
      addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
                layerId="colorLegend")
  })
  
  # Show a popup at the given location
  showCityPopup <- function(allcity, lat, lng) {
    selectedCity <- allcity[allcity$City_name == City_name,]
    content <- as.character(tagList(
      tags$h4("Accessibility:", as.integer(selectedCity$Tot_r_20)),
      tags$strong(HTML(sprintf("%s, %s",
                               selectedCity$City_name, selectedCity$kind
      ))), tags$br(),
      sprintf("Percent of income as household and transport cost: %s%%", as.character(selectedCity$HH_Trans_cost_perc_income_seg)), tags$br(),
      sprintf("Accessibility to jobs at the 20 minute travel time is: %s", as.character(selectedCity$Total_Accessibility_20_seg)), tags$br(),
      sprintf("Hispanic population: %s", selectedCity$Hispanic)
    ))
    leafletProxy("map") %>% addPopups(lng, lat, content, layerId = City_name)
  }
  
  # When map is clicked, show a popup with city info
  observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_shape_click
    if (is.null(event))
      return()
    
    isolate({
      showCityPopup(event$id, event$lng, event$lat)
    })
  })
  
  
  ## Data Explorer ###########################################
  
  observe({
    cities <- if (is.null(input$kind)) character(0) else {
      filter(cleantable, kind %in% input$kind) %>%
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
      map %>% clearPopups()
      dist <- 0.5
      city <- input$goto$city
      lat <- input$goto$lat
      lng <- input$goto$lng
      showCityPopup(city, lat, lng)
      map %>% fitBounds(lng - dist, lat - dist, lng + dist, lat + dist)
    })
  })
  
  output$citytable <- DT::renderDataTable({
    df <- cleantable %>%
      filter(
        Score >= input$minScore,
        Score <= input$maxScore,
        is.null(input$kind) | State %in% input$kind,
        is.null(input$City_name) | City %in% input$City_name
      ) %>%
      mutate(Action = paste('<a class="go-map" href="" data-lat="', Lat, '" data-long="', Long, '" data-city="', City_name, '"><i class="fa fa-crosshairs"></i></a>', sep=""))
    action <- DT::dataTableAjax(session, df, outputId = "citytable")
    
    DT::datatable(df, options = list(ajax = list(url = action)), escape = FALSE)
  })
}
