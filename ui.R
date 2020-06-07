library(leaflet)

# Choices for drop-downs
vars <- c(
  "Total 20 minute accessibility" = "Tot_r_20",
  "Hispanic" = "Hispanic",
  "Population" = "population",
  "Total 20 minute accessibility segment"= "Tot_r_20_seg",
  "Household and transport cost as percentage of interest"= "ht_ami_seg"
)


navbarPage("Los Angeles County", id="nav",
           
           tabPanel("Interactive map",
                    div(class="outer",
                        
                        tags$head(
                          # Include our custom CSS
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        
                        # If not using custom CSS, set height of leafletOutput to a number instead of percent
                        leafletOutput("map", width="100%", height="100%"),
                        
                        # Shiny versions prior to 0.11 should use class = "modal" instead.
                        absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                      draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                                      width = 330, height = "auto",
                                      
                                      h2("City explorer"),
                                      
                                      selectInput("color", "Color", vars),
                                      
                                      plotOutput("histCity", height = 200),
                                      plotOutput("scatterTransit", height = 250)
                        ),
                        
                        tags$div(id="cite",
                                 'Data compiled for ', tags$em('Predicting accessibility in Los Angeles County: A comparative study using a multilevel model and an artificial neural network'), ' by Christina Last (2018)).'
                        )
                    )
           ),
           
           tabPanel("Data explorer",
                    fluidRow(
                      column(1,
                             selectInput("cities", "Cities", c("All cities"=""), multiple=TRUE)
                      )
                    ),
                    fluidRow(
                      column(1,
                             numericInput("minTot_r_20", "Min accessibility", min=134684, max=769283, value=134684)
                      ),
                      column(1,
                             numericInput("maxTot_r_20", "Max accessibility", min=134684, max=769283, value=769283)
                      )
                    ),
                    hr(),
                    DT::dataTableOutput("citytable")
           ),
           
           conditionalPanel("false", icon("crosshair"))
)
