#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @importFrom igraph sample_gnp is_directed
#' @noRd
app_server <- function(input, output, session) {
  # Reactive value to store the graph
  graph_data <- reactiveValues(
    g = NULL,
    layout_coords = NULL,
    save_requested = FALSE  # Flag to track when save is requested
  )
  
  # Get graph from golem options or generate random
  observe({
    g_input <- golem::get_golem_options("g")
    if (!is.null(g_input)) {
      graph_data$g <- g_input
    } else {
      # Generate a random graph
      graph_data$g <- igraph::sample_gnp(20, 0.15)
    }
  })
  
  # Generate graph with selected layout
  observeEvent(input$generate, {
    req(graph_data$g)
    
    # Apply the selected layout algorithm
    set.seed(input$seed)
    layout_func <- get(input$layout_algo, envir = asNamespace("igraph"))
    layout_coords <- layout_func(graph_data$g)
    
    # Store coordinates as vertex attributes
    igraph::V(graph_data$g)$x <- layout_coords[, 1]
    igraph::V(graph_data$g)$y <- layout_coords[, 2]
    
    # Also store as graph attribute
    graph_data$g <- igraph::set_graph_attr(graph_data$g, "layout", layout_coords)
  })
  
  # Render the interactive D3 graph
  output$graph_viz <- renderD3graph({
    req(graph_data$g)
    
    # The graph object contains all necessary information
    # including layout coordinates if they've been set
    # Only render once - don't re-render on label toggle
    d3graph(graph_data$g, height = 600, show_labels = TRUE)
  })
  
  # Handle label visibility toggle without re-rendering
  observeEvent(input$show_labels, {
    session$sendCustomMessage(
      type = "toggleLabels_graph_viz",
      message = list(show = input$show_labels)
    )
  })
  
  # Handle Ready button - save positions and close app
  observeEvent(input$ready, {
    req(graph_data$g)
    
    # Set flag that save was requested
    graph_data$save_requested <- TRUE
    
    # Request node positions from JavaScript
    session$sendCustomMessage(
      type = "getNodePositions_graph_viz",
      message = list()
    )
  })
  
  # Listen for positions from JavaScript
  observeEvent(input$graph_viz_positions, {
    req(graph_data$g)
    
    # Only process if save was explicitly requested
    req(graph_data$save_requested)
    
    positions <- input$graph_viz_positions
    
    # Create a matrix of coordinates
    n_nodes <- igraph::vcount(graph_data$g)
    coords <- matrix(0, nrow = n_nodes, ncol = 2)
    
    # Handle different possible structures
    # First try: list with x and y vectors (data frame-like structure from JavaScript)
    if (is.list(positions) && "x" %in% names(positions) && "y" %in% names(positions)) {
      coords[, 1] <- as.numeric(positions$x)
      coords[, 2] <- as.numeric(positions$y)
    } else if (is.data.frame(positions)) {
      # Data frame structure
      coords[, 1] <- positions$x
      coords[, 2] <- positions$y
    } else if (is.list(positions) && length(positions) > 0) {
      # List of lists structure
      for (i in seq_len(min(length(positions), n_nodes))) {
        if (is.list(positions[[i]])) {
          coords[i, 1] <- as.numeric(positions[[i]]$x)
          coords[i, 2] <- as.numeric(positions[[i]]$y)
        }
      }
    }
    
    # Normalize coordinates back to original scale
    # Get the original coordinate ranges
    if ("x" %in% igraph::vertex_attr_names(graph_data$g) && 
        "y" %in% igraph::vertex_attr_names(graph_data$g)) {
      orig_x <- igraph::V(graph_data$g)$x
      orig_y <- igraph::V(graph_data$g)$y
      
      # Get original ranges
      orig_x_range <- range(orig_x)
      orig_y_range <- range(orig_y)
      
      # Get current ranges
      curr_x_range <- range(coords[, 1])
      curr_y_range <- range(coords[, 2])
      
      # Normalize: map from current range to original range
      if (diff(curr_x_range) > 0) {
        coords[, 1] <- (coords[, 1] - curr_x_range[1]) / diff(curr_x_range) * diff(orig_x_range) + orig_x_range[1]
      }
      if (diff(curr_y_range) > 0) {
        coords[, 2] <- (coords[, 2] - curr_y_range[1]) / diff(curr_y_range) * diff(orig_y_range) + orig_y_range[1]
      }
    }
    
    # Flip Y-axis back: igraph has Y increasing upward, SVG has Y increasing downward
    y_min <- min(coords[, 2])
    y_max <- max(coords[, 2])
    if (y_max > y_min) {
      coords[, 2] <- y_max + y_min - coords[, 2]
    }
    
    # Store coordinates in the graph object
    graph_data$g <- igraph::set_graph_attr(
      graph_data$g, 
      "layout", 
      coords
    )
    
    # Store as vertex attributes
    igraph::V(graph_data$g)$x <- coords[, 1]
    igraph::V(graph_data$g)$y <- coords[, 2]
    
    # Show notification
    showNotification(
      "Layout saved! Node coordinates stored in graph attributes 'x' and 'y'.",
      type = "message",
      duration = 3
    )
    
    # Stop the app after a short delay
    Sys.sleep(1)
    stopApp(returnValue = graph_data$g)
  })
}
