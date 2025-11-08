#' Edit a Graph Layout Shiny Application
#'
#' @param g An igraph object to visualize and edit the layout.
#' If NULL, a random graph will be generated.
#' 
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams shiny::shinyApp
#'
#' @export
#' @importFrom shiny shinyApp runApp
#' @importFrom golem with_golem_options
edit_layout <- function(
  g = NULL,
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  uiPattern = "/",
  ...
) {
  app <- with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(g = g, ...)
  )
  
  # Run the app and capture the return value from stopApp()
  result <- runApp(app, launch.browser = getOption("shiny.launch.browser", interactive()))
  
  return(result)
}
