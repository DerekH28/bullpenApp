library(shiny)
library(ggplot2)
library(readr)
library(DT)
library(DBI)
library(RSQLite)
library(grid)
library(png)
library(rmarkdown)

# Initialize SQLite databases
db_pitchers <- dbConnect(SQLite(), "pitchers_db.sqlite")
db_sessions <- dbConnect(SQLite(), "sessions_db.sqlite")

# Create tables if not exist in pitchers database
dbExecute(db_pitchers, "CREATE TABLE IF NOT EXISTS pitchers (id INTEGER PRIMARY KEY, name TEXT)")

# Close the connection for now
dbDisconnect(db_pitchers)
dbDisconnect(db_sessions)

ui <- fluidPage(
  titlePanel("Baseball Application"),
  
  # Home screen with three options
  conditionalPanel(
    condition = "output.showHomeScreen",
    h1("Welcome to the Baseball App"),
    actionButton("bullpenSession", "Scripted Bullpen Session"),
    actionButton("liveBullpenSession", "Live Bullpen Session"),
    actionButton("adminPage", "Admin Page")
  ),
  
  # Admin page with password input and admin options
  conditionalPanel(
    condition = "output.showAdminPage",
    actionButton("backToHomeFromAdmin", "Back"),
    textInput("adminPassword", "Enter Admin Password"),
    actionButton("submitPassword", "Submit"),
    verbatimTextOutput("passwordStatus"),
    conditionalPanel(
      condition = "output.adminAuthenticated",
      h2("Admin Options"),
      textInput("newPitcherName", "Add New Pitcher"),
      actionButton("addPitcher", "Add Pitcher"),
      selectInput("deletePitcherId", "Delete Pitcher", choices = NULL),
      actionButton("deletePitcher", "Delete Pitcher"),
      DTOutput("pitcherList"),
      DTOutput("sessionList")
    )
  ),
  
  # Bullpen session UI
  conditionalPanel(
    condition = "output.showBullpenSession",
    actionButton("backToHomeFromBullpen", "Back"),
    sidebarLayout(
      sidebarPanel(
        fileInput("csvInput1", "Upload CSV File 1", accept = ".csv"),
        selectInput("selectPitcher", "Select Pitcher", choices = NULL),
        actionButton("prevRow1", "Previous Row"),
        actionButton("nextRow1", "Next Row"),
        textOutput("value1_1"),
        textOutput("value2_1"),
        textOutput("value3_1"),
        textOutput("value4_1"),
        numericInput("x_value_user", "X Value", value = 0, min = 0, max = 19.94),
        numericInput("y_value_user", "Y Value", value = 0, min = 0, max = 25.79),
        actionButton("add_point", "Add Point"),
        textOutput("pitch_number"),
        textOutput("horizontal_distance"),
        textOutput("vertical_distance"),
        textOutput("total_distance"),
        downloadButton("downloadTable", "Download CSV"),
        downloadButton("downloadPDF", "Download PDF of Session"),
        actionButton("endSession", "End Session")
      ),
      mainPanel(
        uiOutput("dynamicLayout")
      )
    )
  ),
  
  # Live bullpen session UI
  conditionalPanel(
    condition = "output.showLiveBullpenSession",
    actionButton("backToHomeFromLiveBullpen", "Back"),
    sidebarLayout(
      sidebarPanel(
        fileInput("csvInput2", "Upload CSV File 2", accept = ".csv"),
        selectInput("selectPitcherLive", "Select Pitcher", choices = NULL),
        textOutput("live_count"),
        textOutput("live_batter_handedness"),
        numericInput("x_value_recommended", "Recommended X Value", value = 0, min = 0, max = 19.94),
        numericInput("y_value_recommended", "Recommended Y Value", value = 0, min = 0, max = 25.79),
        actionButton("update_recommended", "Update Recommended Pitch"),
        numericInput("x_value_actual", "Actual X Value", value = 0, min = 0, max = 19.94),
        numericInput("y_value_actual", "Actual Y Value", value = 0, min = 0, max = 25.79),
        actionButton("add_live_point", "Add Actual Pitch"),
        textOutput("live_pitch_number"),
        textOutput("live_horizontal_distance"),
        textOutput("live_vertical_distance"),
        textOutput("live_total_distance"),
        downloadButton("downloadLiveTable", "Download CSV"),
        downloadButton("downloadLivePDF", "Download PDF of Session")
      ),
      mainPanel(
        fluidRow(
          column(6, plotOutput("liveSquarePlot1", height = "400px")),
          column(6, DTOutput("liveDistanceTable"))
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Reactive values for navigation and state
  rv <- reactiveValues(
    showHomeScreen = TRUE, 
    showAdminPage = FALSE, 
    showBullpenSession = FALSE, 
    showLiveBullpenSession = FALSE, 
    adminAuthenticated = FALSE
  )
  
  # Reactive values for live bullpen session
  live_session_data <- reactiveVal(NULL)
  live_current_row <- reactiveVal(1)
  
  # Observe navigation buttons
  observeEvent(input$bullpenSession, {
    rv$showHomeScreen <- FALSE
    rv$showBullpenSession <- TRUE
  })
  
  observeEvent(input$liveBullpenSession, {
    rv$showHomeScreen <- FALSE
    rv$showLiveBullpenSession <- TRUE
  })
  
  observeEvent(input$adminPage, {
    rv$showHomeScreen <- FALSE
    rv$showAdminPage <- TRUE
  })
  
  observeEvent(input$backToHomeFromAdmin, {
    rv$showAdminPage <- FALSE
    rv$showHomeScreen <- TRUE
  })
  
  observeEvent(input$backToHomeFromBullpen, {
    rv$showBullpenSession <- FALSE
    rv$showHomeScreen <- TRUE
  })
  
  observeEvent(input$backToHomeFromLiveBullpen, {
    rv$showLiveBullpenSession <- FALSE
    rv$showHomeScreen <- TRUE
  })
  
  # Admin authentication
  observeEvent(input$submitPassword, {
    if (input$adminPassword == "admin123") {
      rv$adminAuthenticated <- TRUE
      output$passwordStatus <- renderText("Password correct.")
    } else {
      rv$adminAuthenticated <- FALSE
      output$passwordStatus <- renderText("Incorrect password.")
    }
  })
  
  # Output control for UI
  output$showHomeScreen <- reactive(rv$showHomeScreen)
  output$showAdminPage <- reactive(rv$showAdminPage)
  output$showBullpenSession <- reactive(rv$showBullpenSession)
  output$showLiveBullpenSession <- reactive(rv$showLiveBullpenSession)
  output$adminAuthenticated <- reactive(rv$adminAuthenticated)
  
  outputOptions(output, "showHomeScreen", suspendWhenHidden = FALSE)
  outputOptions(output, "showAdminPage", suspendWhenHidden = FALSE)
  outputOptions(output, "showBullpenSession", suspendWhenHidden = FALSE)
  outputOptions(output, "showLiveBullpenSession", suspendWhenHidden = FALSE)
  outputOptions(output, "adminAuthenticated", suspendWhenHidden = FALSE)
  
  # Database interaction
  observe({
    req(rv$adminAuthenticated)
    db_pitchers <- dbConnect(SQLite(), "pitchers_db.sqlite")
    pitchers <- dbGetQuery(db_pitchers, "SELECT * FROM pitchers")
    dbDisconnect(db_pitchers)
    
    updateSelectInput(session, "deletePitcherId", choices = pitchers$id, selected = NULL)
    output$pitcherList <- renderDT({
      datatable(pitchers)
    })
  })
  
  observeEvent(input$addPitcher, {
    req(input$newPitcherName)
    db_pitchers <- dbConnect(SQLite(), "pitchers_db.sqlite")
    dbExecute(db_pitchers, "INSERT INTO pitchers (name) VALUES (?)", params = list(input$newPitcherName))
    dbDisconnect(db_pitchers)
    updateSelectInput(session, "deletePitcherId", selected = NULL)
  })
  
  observeEvent(input$deletePitcher, {
    req(input$deletePitcherId)
    db_pitchers <- dbConnect(SQLite(), "pitchers_db.sqlite")
    dbExecute(db_pitchers, "DELETE FROM pitchers WHERE id = ?", params = list(input$deletePitcherId))
    dbDisconnect(db_pitchers)
    updateSelectInput(session, "deletePitcherId", selected = NULL)
  })
  
  # Display the list of session names (table names) from the sessions database
  output$sessionList <- renderDT({
    req(rv$adminAuthenticated)
    db_sessions <- dbConnect(SQLite(), "sessions_db.sqlite")
    table_list <- dbListTables(db_sessions)
    dbDisconnect(db_sessions)
    
    # Create a data frame with session names
    session_names <- data.frame(SessionName = table_list, stringsAsFactors = FALSE)
    
    datatable(session_names)
  })
  
  # Update pitcher choices for the bullpen session
  observe({
    db_pitchers <- dbConnect(SQLite(), "pitchers_db.sqlite")
    pitchers <- dbGetQuery(db_pitchers, "SELECT id, name FROM pitchers")
    dbDisconnect(db_pitchers)
    
    updateSelectInput(session, "selectPitcher", choices = pitchers$name, selected = NULL)
    updateSelectInput(session, "selectPitcherLive", choices = pitchers$name, selected = NULL)
  })
  
  # Original bullpen session code (for brevity, simplified here)
  csv_data1 <- reactive({
    req(input$csvInput1)  
    read_csv(input$csvInput1$datapath)
  })
  
  current_row <- reactiveVal(1)
  
  observeEvent(input$nextRow1, {
    csv1 <- csv_data1()
    new_row <- min(current_row() + 1, nrow(csv1))
    current_row(new_row)
  })
  
  observeEvent(input$prevRow1, {
    new_row <- max(current_row() - 1, 1)
    current_row(new_row)
  })
  
  output$value1_1 <- renderText({
    data <- csv_data1()
    row <- current_row()
    req(nrow(data) >= row)
    paste("Value 1:", data[row, 3])
  })
  
  output$value2_1 <- renderText({
    data <- csv_data1()
    row <- current_row()
    req(nrow(data) >= row)
    paste("Count:", data[row, 4], "-", data[row, 5])
  })
  
  output$value3_1 <- renderText({
    data <- csv_data1()
    row <- current_row()
    req(nrow(data) >= row)
    paste("Value 3:", data[row, 5])
  })
  
  output$value4_1 <- renderText({
    data <- csv_data1()
    row <- current_row()
    req(nrow(data) >= row)
    paste("Value 4:", data[row, 6])
  })
  
  user_point <- reactiveVal(NULL)
  
  observeEvent(input$add_point, {
    data <- csv_data1()
    row <- current_row()
    req(nrow(data) >= row, ncol(data) >= 2)
    
    x_value1 <- as.numeric(data[row, 1])
    y_value1 <- as.numeric(data[row, 2])
    
    x_user <- input$x_value_user
    y_user <- input$y_value_user
    
    horizontal_distance <- abs(x_value1 - x_user)
    vertical_distance <- abs(y_value1 - y_user)
    total_distance <- sqrt((x_value1 - x_user)^2 + (y_value1 - y_user)^2)
    
    new_distance <- data.frame(
      Pitch = row,
      Horizontal = horizontal_distance,
      Vertical = vertical_distance,
      Total = total_distance
    )
    
    distances(rbind(distances(), new_distance))
    user_point(c(x_user, y_user))
  })
  
  # Output for dynamic layout
  output$dynamicLayout <- renderUI({
    req(csv_data1())
    data <- csv_data1()
    row <- current_row()
    req(nrow(data) >= row)
    batter_handedness <- data[row, 3]  # Assuming the third column indicates handedness
    
    if (batter_handedness == "R") {
      # Batter on left, data table on right
      fluidRow(
        column(6, plotOutput("squarePlot1", height = "400px")),
        column(6, DTOutput("distanceTable"))
      )
    } else if (batter_handedness == "L") {
      # Data table on left, batter on right
      fluidRow(
        column(6, DTOutput("distanceTable")),
        column(6, plotOutput("squarePlot1", height = "400px"))
      )
    }
  })
  
  output$squarePlot1 <- renderPlot({
    data <- csv_data1()
    row <- current_row()
    req(nrow(data) >= row, ncol(data) >= 2)
    
    x_value1 <- as.numeric(data[row, 1])
    y_value1 <- as.numeric(data[row, 2])
    
    plot <- ggplot() +
      geom_rect(aes(xmin = 0, xmax = 19.94, ymin = 0, ymax = 25.79), fill = "white", color = "black") +
      geom_segment(aes(x = 0, xend = 19.94, y = 25.79 / 3, yend = 25.79 / 3), color = "lightgrey") +
      geom_segment(aes(x = 0, xend = 19.94, y = 2 * 25.79 / 3, yend = 2 * 25.79 / 3), color = "lightgrey") +
      geom_segment(aes(x = 19.94 / 3, xend = 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
      geom_segment(aes(x = 2 * 19.94 / 3, xend = 2 * 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
      geom_point(aes(x = x_value1, y = y_value1), color = "red", size = 9) +
      coord_fixed(ratio = 19.94 / 25.79) +
      theme_void() +
      theme(panel.border = element_blank())
    
    if (!is.null(user_point())) {
      plot <- plot +
        geom_point(aes(x = user_point()[1], y = user_point()[2]), color = "blue", size = 9)
    }
    
    # Add batter image based on handedness
    batter_handedness <- data[row, 3]  # Assuming the third column indicates handedness
    if (batter_handedness == "R") {
      plot <- plot + 
        annotation_custom(rasterGrob(png::readPNG("right_handed_batter.png"), width = unit(2, "cm"), height = unit(2, "cm")),
                          xmin = -5, xmax = 0, ymin = 0, ymax = 25.79)
    } else if (batter_handedness == "L") {
      plot <- plot + 
        annotation_custom(rasterGrob(png::readPNG("left_handed_batter.png"), width = unit(2, "cm"), height = unit(2, "cm")),
                          xmin = 19.94, xmax = 24.94, ymin = 0, ymax = 25.79)
    }
    
    print(plot)
  }, height = 400, width = 600)
  
  distances <- reactiveVal(data.frame(
    Pitch = integer(),
    Horizontal = numeric(),
    Vertical = numeric(),
    Total = numeric(),
    stringsAsFactors = FALSE
  ))
  
  output$distanceTable <- renderDT({
    datatable(distances(), options = list(pageLength = 5, autoWidth = TRUE))
  })
  
  output$downloadTable <- downloadHandler(
    filename = function() {
      paste("distances-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(distances(), file, row.names = FALSE)
    }
  )
  
  # Live bullpen session data and plot
  live_distances <- reactiveVal(data.frame(
    Pitch = integer(),
    Horizontal = numeric(),
    Vertical = numeric(),
    Total = numeric(),
    stringsAsFactors = FALSE
  ))
  
  # Load CSV for live session and set initial values
  observeEvent(input$csvInput2, {
    req(input$csvInput2)
    data <- read_csv(input$csvInput2$datapath)
    live_session_data(data)
    live_current_row(1)
    
    updateNumericInput(session, "x_value_recommended", value = as.numeric(data[1, 1]))
    updateNumericInput(session, "y_value_recommended", value = as.numeric(data[1, 2]))
  })
  
  observeEvent(live_current_row(), {
    data <- live_session_data()
    row <- live_current_row()
    req(nrow(data) >= row)
    
    count <- paste(data[row, 4], "-", data[row, 5])
    handedness <- data[row, 3]
    
    output$live_count <- renderText({ paste("Count:", count) })
    output$live_batter_handedness <- renderText({ paste("Batter Handedness:", handedness) })
    
    updateNumericInput(session, "x_value_recommended", value = as.numeric(data[row, 1]))
    updateNumericInput(session, "y_value_recommended", value = as.numeric(data[row, 2]))
  })
  
  observeEvent(input$update_recommended, {
    # Logic to update recommended pitch location if necessary
    # This can be handled with additional UI elements or logging
  })
  
  observeEvent(input$add_live_point, {
    x_recommended <- input$x_value_recommended
    y_recommended <- input$y_value_recommended
    x_actual <- input$x_value_actual
    y_actual <- input$y_value_actual
    
    horizontal_distance <- abs(x_recommended - x_actual)
    vertical_distance <- abs(y_recommended - y_actual)
    total_distance <- sqrt((x_recommended - x_actual)^2 + (y_recommended - y_actual)^2)
    
    new_live_distance <- data.frame(
      Pitch = nrow(live_distances()) + 1,
      Horizontal = horizontal_distance,
      Vertical = vertical_distance,
      Total = total_distance
    )
    
    live_distances(rbind(live_distances(), new_live_distance))
  })
  
  output$liveSquarePlot1 <- renderPlot({
    plot <- ggplot() +
      geom_rect(aes(xmin = 0, xmax = 19.94, ymin = 0, ymax = 25.79), fill = "white", color = "black") +
      geom_segment(aes(x = 0, xend = 19.94, y = 25.79 / 3, yend = 25.79 / 3), color = "lightgrey") +
      geom_segment(aes(x = 0, xend = 19.94, y = 2 * 25.79 / 3, yend = 2 * 25.79 / 3), color = "lightgrey") +
      geom_segment(aes(x = 19.94 / 3, xend = 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
      geom_segment(aes(x = 2 * 19.94 / 3, xend = 2 * 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
      geom_point(aes(x = input$x_value_recommended, y = input$y_value_recommended), color = "red", size = 9) +
      coord_fixed(ratio = 19.94 / 25.79) +
      theme_void() +
      theme(panel.border = element_blank())
    
    # Add actual pitch location points
    live_data <- live_distances()
    if (nrow(live_data) > 0) {
      plot <- plot +
        geom_point(aes(x = input$x_value_actual, y = input$y_value_actual), color = "blue", size = 9)
    }
    
    print(plot)
  }, height = 400, width = 600)
  
  output$liveDistanceTable <- renderDT({
    datatable(live_distances(), options = list(pageLength = 5, autoWidth = TRUE))
  })
  
  output$downloadLiveTable <- downloadHandler(
    filename = function() {
      paste("live_distances-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(live_distances(), file, row.names = FALSE)
    }
  )
  
  # Generate and download PDF for live session
  output$downloadLivePDF <- downloadHandler(
    filename = function() {
      paste("live_session_report_", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      # Save plot as an image
      pdf_plot <- tempfile(fileext = ".png")
      png(pdf_plot, width = 8, height = 6, units = "in", res = 300)
      plot <- ggplot() +
        geom_rect(aes(xmin = 0, xmax = 19.94, ymin = 0, ymax = 25.79), fill = "white", color = "black") +
        geom_segment(aes(x = 0, xend = 19.94, y = 25.79 / 3, yend = 25.79 / 3), color = "lightgrey") +
        geom_segment(aes(x = 0, xend = 19.94, y = 2 * 25.79 / 3, yend = 2 * 25.79 / 3), color = "lightgrey") +
        geom_segment(aes(x = 19.94 / 3, xend = 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
        geom_segment(aes(x = 2 * 19.94 / 3, xend = 2 * 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
        geom_point(aes(x = input$x_value_actual, y = input$y_value_actual), color = "blue", size = 9)
      print(plot)
      dev.off()
      
      # Render the PDF with rmarkdown
      rmarkdown::render(input = "C:\\Users\\Derek\\OneDrive\\Documents\\session_report.Rmd",
                        output_file = file,
                        params = list(
                          plot = pdf_plot,
                          data = live_distances()
                        ),
                        envir = new.env(parent = globalenv()))
    }
  )
  
  # Generate and download PDF for scripted session
  output$downloadPDF <- downloadHandler(
    filename = function() {
      paste("session_report_", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      # Save plot as an image
      pdf_plot <- tempfile(fileext = ".png")
      png(pdf_plot, width = 8, height = 6, units = "in", res = 300)
      plot <- ggplot() +
        geom_rect(aes(xmin = 0, xmax = 19.94, ymin = 0, ymax = 25.79), fill = "white", color = "black") +
        geom_segment(aes(x = 0, xend = 19.94, y = 25.79 / 3, yend = 25.79 / 3), color = "lightgrey") +
        geom_segment(aes(x = 0, xend = 19.94, y = 2 * 25.79 / 3, yend = 2 * 25.79 / 3), color = "lightgrey") +
        geom_segment(aes(x = 19.94 / 3, xend = 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
        geom_segment(aes(x = 2 * 19.94 / 3, xend = 2 * 19.94 / 3, y = 0, yend = 25.79), color = "lightgrey") +
        geom_point(aes(x = input$x_value_user, y = input$y_value_user), color = "blue", size = 9)
      print(plot)
      dev.off()
      
      # Render the PDF with rmarkdown
      rmarkdown::render(input = "C:\\Users\\Derek\\OneDrive\\Documents\\session_report.Rmd",
                        output_file = file,
                        params = list(
                          plot = pdf_plot,
                          data = distances()
                        ),
                        envir = new.env(parent = globalenv()))
    }
  )
  
  # End Session and save data
  observeEvent(input$endSession, {
    req(input$selectPitcher, nrow(distances()) > 0)
    db_pitchers <- dbConnect(SQLite(), "pitchers_db.sqlite")
    db_sessions <- dbConnect(SQLite(), "sessions_db.sqlite")
    
    # Get the selected pitcher's name
    pitcher <- dbGetQuery(db_pitchers, "SELECT name FROM pitchers WHERE name = ?", params = list(input$selectPitcher))
    if (nrow(pitcher) > 0) {
      pitcher_name <- pitcher$name[1]
      
      # Prepare data for insertion
      session_data <- distances()
      session_data$pitcher_name <- pitcher_name
      session_data$date <- Sys.Date()
      session_data$details <- apply(session_data, 1, function(row) paste("Pitch:", row["Pitch"], "Horizontal:", row["Horizontal"], "Vertical:", row["Vertical"], "Total:", row["Total"]))
      
      # Create a unique table name based on the session date and pitcher
      table_name <- paste0("session_", pitcher_name, "_", format(Sys.Date(), "%Y%m%d"))
      
      # Ensure table name is valid by replacing non-alphanumeric characters
      table_name <- gsub("[^[:alnum:]_]", "_", table_name)
      
      # Create a new table for the session's performances
      dbExecute(db_sessions, sprintf("CREATE TABLE IF NOT EXISTS %s (pitcher_name TEXT, date TEXT, details TEXT)", table_name))
      
      # Insert data into the new table
      dbWriteTable(db_sessions, table_name, session_data[, c("pitcher_name", "date", "details")], append = TRUE, row.names = FALSE)
    }
    
    dbDisconnect(db_pitchers)
    dbDisconnect(db_sessions)
    
    # Reset the distances table
    distances(data.frame(
      Pitch = integer(),
      Horizontal = numeric(),
      Vertical = numeric(),
      Total = numeric(),
      stringsAsFactors = FALSE
    ))
  })
}

shinyApp(ui = ui, server = server)
