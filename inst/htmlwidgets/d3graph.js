HTMLWidgets.widget({
  name: 'd3graph',
  type: 'output',

  factory: function(el, width, height) {
    let svg, simulation, node, link, text;
    let nodes = [], links = [];
    
    return {
      renderValue: function(x) {
        // Clear existing content
        el.innerHTML = '';
        
        // Convert R data frames to array of objects
        nodes = HTMLWidgets.dataframeToD3(x.nodes);
        links = HTMLWidgets.dataframeToD3(x.links);
        
        // Create SVG
        svg = d3.select(el)
          .append('svg')
          .attr('width', '100%')
          .attr('height', height)
          .attr('class', 'graph-svg');  // Add class for styling
        
        const svgWidth = el.offsetWidth;
        const svgHeight = height;
        
        // Check if nodes have initial positions
        const hasInitialPositions = nodes.every(n => n.x !== undefined && n.y !== undefined);
        
        // If we have initial positions, scale them to fit the viewport
        if (hasInitialPositions) {
          const xExtent = d3.extent(nodes, d => d.x);
          const yExtent = d3.extent(nodes, d => d.y);
          const xRange = xExtent[1] - xExtent[0] || 1;
          const yRange = yExtent[1] - yExtent[0] || 1;
          
          // Scale to fit with padding
          // NOTE: Y-axis is FLIPPED because SVG has origin at top-left
          // but igraph layouts have origin at bottom-left
          const padding = 50;
          const xScale = d3.scaleLinear()
            .domain(xExtent)
            .range([padding, svgWidth - padding]);
          const yScale = d3.scaleLinear()
            .domain(yExtent)
            .range([svgHeight - padding, padding]);  // REVERSED for Y-axis flip
          
          // Apply scaled positions and fix them
          nodes.forEach(n => {
            n.x = xScale(n.x);
            n.y = yScale(n.y);  // This flips the Y coordinate
            n.fx = n.x;
            n.fy = n.y;
          });
        }
        
        // Create a group for zoom/pan
        const g = svg.append('g');
        
        // Add zoom behavior
        const zoom = d3.zoom()
          .scaleExtent([0.1, 10])  // Min and max zoom levels
          .on('zoom', (event) => {
            g.attr('transform', event.transform);
          });
        
        svg.call(zoom);
        
        // Create arrow marker for directed graphs
        svg.append('defs').append('marker')
          .attr('id', 'arrowhead')
          .attr('viewBox', '-0 -5 10 10')
          .attr('refX', 20)
          .attr('refY', 0)
          .attr('orient', 'auto')
          .attr('markerWidth', 8)
          .attr('markerHeight', 8)
          .attr('xoverflow', 'visible')
          .append('svg:path')
          .attr('d', 'M 0,-5 L 10 ,0 L 0,5')
          .attr('fill', '#999')
          .style('stroke', 'none');
        
        // Create links (now in the g group)
        link = g.append('g')
          .selectAll('line')
          .data(links)
          .enter().append('line')
          .attr('stroke', '#999')
          .attr('stroke-opacity', 0.6)
          .attr('stroke-width', 2)
          .attr('marker-end', x.directed ? 'url(#arrowhead)' : '');
        
        // Create nodes (now in the g group)
        node = g.append('g')
          .selectAll('circle')
          .data(nodes)
          .enter().append('circle')
          .attr('r', d => d.size || 8)  // Use size attribute or default to 8
          .attr('fill', d => d.color || '#69b3a2')  // Use color attribute or default
          .attr('stroke', '#fff')
          .attr('stroke-width', 2)
          .call(d3.drag()
            .on('start', dragstarted)
            .on('drag', dragged)
            .on('end', dragended));
        
        // Add labels (now in the g group)
        text = g.append('g')
          .attr('class', 'labels')
          .selectAll('text')
          .data(nodes)
          .enter().append('text')
          .text(d => d.name)
          .attr('font-size', 10)
          .attr('dx', 12)
          .attr('dy', 4)
          .style('pointer-events', 'none')
          .style('display', x.show_labels ? 'block' : 'none');
        
        // Apply initial theme
        if (x.dark_theme) {
          svg.style('background-color', '#1f1f1f');
          link.attr('stroke', '#666');
          text.style('fill', '#e0e0e0');
        }
        
        // Create force simulation with minimal forces
        simulation = d3.forceSimulation(nodes)
          .force('link', d3.forceLink(links).id(d => d.id).distance(100).strength(0.1))
          .force('charge', d3.forceManyBody().strength(-50))  // Much weaker repulsion
          .force('center', d3.forceCenter(svgWidth / 2, svgHeight / 2))
          .force('collision', d3.forceCollide().radius(d => (d.size || 8) + 5))  // Use node size
          .alphaDecay(0.05)  // Faster settling
          .on('tick', ticked);
        
        // If we have initial positions, stop simulation immediately
        if (hasInitialPositions) {
          simulation.stop();
          ticked();  // Draw once at initial positions
        } else {
          // Stop simulation after initial layout settles
          simulation.on('end', function() {
            // Fix all nodes after initial layout
            nodes.forEach(n => {
              n.fx = n.x;
              n.fy = n.y;
            });
          });
        }
        
        function ticked() {
          link
            .attr('x1', d => d.source.x)
            .attr('y1', d => d.source.y)
            .attr('x2', d => d.target.x)
            .attr('y2', d => d.target.y);
          
          node
            .attr('cx', d => d.x)
            .attr('cy', d => d.y);
          
          text
            .attr('x', d => d.x)
            .attr('y', d => d.y);
        }
        
        function dragstarted(event, d) {
          // Don't restart simulation - just drag the node
          d.fx = d.x;
          d.fy = d.y;
        }
        
        function dragged(event, d) {
          d.fx = event.x;
          d.fy = event.y;
          // Manually update position for immediate feedback
          d.x = event.x;
          d.y = event.y;
          ticked();  // Update visual immediately
        }
        
        function dragended(event, d) {
          // Keep nodes fixed after dragging so they don't move
          d.fx = event.x;
          d.fy = event.y;
        }
        
        // Store the widget instance to access node positions later
        if (typeof Shiny !== 'undefined') {
          Shiny.addCustomMessageHandler('getNodePositions_' + el.id, function(message) {
            // Create arrays for each column (data frame format)
            const ids = [];
            const names = [];
            const xs = [];
            const ys = [];
            
            nodes.forEach(n => {
              ids.push(n.id);
              names.push(n.name);
              xs.push(n.fx || n.x);
              ys.push(n.fy || n.y);
            });
            
            // Send as data frame structure
            const positions = {
              id: ids,
              name: names,
              x: xs,
              y: ys
            };
            
            Shiny.setInputValue(el.id + '_positions', positions, {priority: 'event'});
          });
          
          // Handler for toggling label visibility
          Shiny.addCustomMessageHandler('toggleLabels_' + el.id, function(message) {
            if (text) {
              text.style('display', message.show ? 'block' : 'none');
            }
          });
          
          // Handler for theme changes
          Shiny.addCustomMessageHandler('setTheme_' + el.id, function(message) {
            if (svg) {
              if (message.dark) {
                // Dark theme
                svg.style('background-color', '#1f1f1f');
                if (link) link.attr('stroke', '#666');
                if (text) text.style('fill', '#e0e0e0');
              } else {
                // Light theme
                svg.style('background-color', 'transparent');
                if (link) link.attr('stroke', '#999');
                if (text) text.style('fill', '#000');
              }
            }
          });
        }
      },
      
      resize: function(width, height) {
        if (svg) {
          svg.attr('width', width).attr('height', height);
        }
      },
      
      getNodePositions: function() {
        return nodes.map(n => ({
          id: n.id,
          name: n.name,
          x: n.x,
          y: n.y
        }));
      }
    };
  }
});
