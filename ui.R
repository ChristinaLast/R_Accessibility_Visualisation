library(leaflet)

# Choices for drop-downs
vars <- c(
  "Total 20 minute accessibility" = "Tot_r_20",
  "Hispanic" = "Hispanic",
  "Population" = "population",
  "Total 20 minute accessibility segment"= "Total_Accessibility_20_seg",
  "Household and transport cost as percentage of interest"= "HH_Trans_cost_perc_income_seg"
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
                      column(3,
                             selectInput("states", "States", c("All states"="", structure(state.abb, names=state.name), "Washington, DC"="DC"), multiple=TRUE)
                      ),
                      column(3,
                             conditionalPanel("input.states",
                                              selectInput("cities", "Cities", c("All cities"=""), multiple=TRUE)
                             )
                      )
                    ),
                    fluidRow(
                      column(1,
                             numericInput("minScore", "Min score", min=0, max=100, value=0)
                      ),
                      column(1,
                             numericInput("maxScore", "Max score", min=0, max=100, value=100)
                      )
                    ),
                    hr(),
                    DT::dataTableOutput("citytable")
           ),
           
           conditionalPanel("false", icon("crosshair"))
)
