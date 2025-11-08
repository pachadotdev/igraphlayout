#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic
    fluidPage(
      col_3(
        h1("Graph Layout Editor"),
        numericInput(
          "seed",
          "Random Seed for Layout",
          value = 42,
          min = 1,
          max = 100,
          step = 1
        ),
        selectInput(
          "layout_algo",
          "Select layout algorithm",
          choices = c(
            "Davidson-Harel layout algorithm" = "layout_with_dh",
            "Fruchterman-Reingold layout algorithm" = "layout_with_fr",
            "GEM layout algorithm" = "layout_with_gem",
            "Graphopt layout algorithm" = "layout_with_graphopt",
            "Kamada-Kawai layout algorithm" = "layout_with_kk",
            "Large Graph Layout" = "layout_with_lgl",
            "Graph layout by multidimensional scaling" = "layout_with_mds"
          )
        ),
        actionButton("generate", "Apply Layout", class = "btn-primary"),
        hr(),
        checkboxInput("show_labels", "Show node labels", value = TRUE),
        hr(),
        actionButton("ready", "Ready - Save Layout", class = "btn-success"),
        hr(),
        p("Drag nodes to adjust the layout. Click 'Ready' when finished.")
      ),
      col_9(
        d3graphOutput("graph_viz", height = "99vh")
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "igraphlayout"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
