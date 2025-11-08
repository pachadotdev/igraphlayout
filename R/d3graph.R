#' D3 Graph Interactive Widget
#'
#' Create an interactive D3.js graph visualization
#'
#' @param g An igraph object
#' @param width Width of the widget
#' @param height Height of the widget
#' @param elementId Element ID for the widget
#' @param show_labels Logical, whether to show node labels
#'
#' @import htmlwidgets
#' @export
d3graph <- function(g, width = NULL, height = NULL, elementId = NULL, show_labels = TRUE) {
  if (!inherits(g, "igraph")) {
    stop("g must be an igraph object")
  }
  
  # Get vertices
  vertices <- igraph::V(g)
  
  # Get vertex names - use 'name' attribute if available, otherwise use IDs
  if ("name" %in% igraph::vertex_attr_names(g)) {
    vertex_names <- igraph::V(g)$name
  } else {
    vertex_names <- as.character(seq_len(length(vertices)))
  }
  
  nodes <- data.frame(
    id = as.numeric(vertices) - 1,  # JavaScript uses 0-based indexing
    name = vertex_names,
    stringsAsFactors = FALSE
  )
  
  # Add initial positions if available (from x, y vertex attributes or layout graph attribute)
  if ("x" %in% igraph::vertex_attr_names(g) && "y" %in% igraph::vertex_attr_names(g)) {
    nodes$x <- igraph::V(g)$x
    nodes$y <- igraph::V(g)$y
  } else if (!is.null(igraph::graph_attr(g, "layout"))) {
    layout_coords <- igraph::graph_attr(g, "layout")
    if (is.matrix(layout_coords) && nrow(layout_coords) == length(vertices)) {
      nodes$x <- layout_coords[, 1]
      nodes$y <- layout_coords[, 2]
    }
  }
  
  # Add vertex attributes if they exist
  if ("size" %in% igraph::vertex_attr_names(g)) {
    nodes$size <- igraph::V(g)$size
  }
  if ("color" %in% igraph::vertex_attr_names(g)) {
    nodes$color <- igraph::V(g)$color
  }
  
  # Get edges
  edges <- igraph::as_edgelist(g, names = FALSE)
  links <- data.frame(
    source = edges[, 1] - 1,  # Convert to 0-based indexing
    target = edges[, 2] - 1,
    stringsAsFactors = FALSE
  )
  
  # Check if directed
  directed <- igraph::is_directed(g)
  
  # Create widget data
  x <- list(
    nodes = nodes,
    links = links,
    directed = directed,
    show_labels = show_labels
  )
  
  # Create widget
  htmlwidgets::createWidget(
    name = 'd3graph',
    x,
    width = width,
    height = height,
    package = 'igraphlayout',
    elementId = elementId
  )
}

#' Shiny bindings for d3graph
#'
#' Output and render functions for using d3graph within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a d3graph
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name d3graph-shiny
#'
#' @export
d3graphOutput <- function(outputId, width = '100%', height = '600px') {
  htmlwidgets::shinyWidgetOutput(outputId, 'd3graph', width, height, package = 'igraphlayout')
}

#' @rdname d3graph-shiny
#' @export
renderD3graph <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, d3graphOutput, env, quoted = TRUE)
}
