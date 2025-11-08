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
          max = 10000,
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
        checkboxInput("dark_theme", "Use dark theme", value = FALSE),
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
    ),
    # Add custom CSS for dark theme
    tags$style(HTML("
      body.dark-theme {
        background-color: #1f1f1f !important;
        color: #e0e0e0 !important;
      }
      body.dark-theme .form-control,
      body.dark-theme .selectize-input,
      body.dark-theme .selectize-dropdown {
        background-color: #2a2a2a !important;
        color: #e0e0e0 !important;
        border-color: #444 !important;
      }
      body.dark-theme h1,
      body.dark-theme h2,
      body.dark-theme h3,
      body.dark-theme label,
      body.dark-theme p {
        color: #e0e0e0 !important;
      }
      body.dark-theme .checkbox label {
        color: #e0e0e0 !important;
      }
      body.dark-theme hr {
        border-top-color: #444 !important;
      }
      
      /* Center notifications */
      #shiny-notification-panel {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: auto;
        max-width: 500px;
      }
      
      .shiny-notification {
        font-size: 16px;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      }
    ")),
    # Add JavaScript to toggle dark theme class on body
    tags$script(HTML("
      $(document).ready(function() {
        // Set initial theme
        if ($('#dark_theme').is(':checked')) {
          $('body').addClass('dark-theme');
        }
        
        // Listen for checkbox changes
        $('#dark_theme').on('change', function() {
          if ($(this).is(':checked')) {
            $('body').addClass('dark-theme');
          } else {
            $('body').removeClass('dark-theme');
          }
        });
      });
    "))
  )
}
