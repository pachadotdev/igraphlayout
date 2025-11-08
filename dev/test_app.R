load_all()

library(igraph)

set.seed(42)
g <- sample_gnp(15, 0.2)

V(g)$name <- paste0("Node_", 1:vcount(g))
V(g)$color <- sample(tintin::tintin_clrs(), vcount(g), replace = TRUE)
V(g)$size <- sample(5:15, vcount(g), replace = TRUE)

layout_coords <- layout_with_kk(g)
V(g)$x <- layout_coords[, 1]
V(g)$y <- layout_coords[, 2]

plot(g, layout = layout_coords)

g2 <- edit_layout(g) # Launches the interactive layout editor

plot(g2, layout = cbind(V(g2)$x, V(g2)$y))
