# Usage: $ ruby gen_road_map.rb Width "(x0,y0)  (x1,y1)  ..."
# ex 1.) $ ruby gen_road_map.rb 20 "(3,3) (4,4) (12,18) (18,18) (19,19)" > road_map.txt
# ex 2.) $ ruby gen_road_map.rb 21 "`ruby gen_obstacle_coords.rb obstacle_map.txt`" > road_map.txt
#        $ ruby AStarAlgorithm.rb road_map.txt
n = ARGV[0].to_i
output_diag = true
grid_cost = 1.0
diag_cost = Math.sqrt(2*grid_cost*grid_cost)

width = n
height = n

# Nodes
nodes_count = width * height

# Edges
grid_edges_count = 2 * (n - 1) * n
diag_edges_count = 2 * (n - 1) * (n - 1)
edges_count = output_diag ? grid_edges_count + diag_edges_count : grid_edges_count

# Obstacles
obstacle_coords = ARGV.length >= 2 ? ARGV[1].split(' ') : []
obstacles_count = obstacle_coords.length
obstacle_nodes = []
obstacle_coords.each do |xy|
  matched = /\(([0-9]+),([0-9]+)\)/.match(xy) # (xxx, yyy)
  x = matched[1].to_i # xxx
  y = matched[2].to_i # yyy
  index = width * y + x
  obstacle_nodes << "N#{index}"
end

puts "#{nodes_count},#{edges_count},#{obstacles_count}"

#
# Nodes
#
height.times do |h|
  width.times do |w|
    index = width * h + w
    puts "N#{index},#{w},#{h}"
  end
end

#
# Edges
#

# -
height.times do |h|
  width.times do |w|
    if w > 0
      index_nL = width * h + (w - 1)
      index_nR = width * h + w
      puts "#{grid_cost},N#{index_nL},N#{index_nR}"
    end
  end
end

# |
height.times do |h|
  width.times do |w|
    if h > 0
      index_nU = width * (h - 1) + w
      index_nD = width * h + w
      puts "#{grid_cost},N#{index_nU},N#{index_nD}"
    end
  end
end

if output_diag
  # \
  height.times do |h|
    width.times do |w|
      if w > 0 && h > 0
        index_nUL = width * (h - 1) + (w - 1)
        index_nDR = width * h + w
        puts "#{diag_cost},N#{index_nUL},N#{index_nDR}"
      end
    end
  end

  # /
  height.times do |h|
    width.times do |w|
      if w < (width - 1) && h > 0
        index_nUR = width * (h - 1) + (w + 1)
        index_nDL = width * h + w
        puts "#{diag_cost},N#{index_nUR},N#{index_nDL}"
      end
    end
  end
end

#
# Obstacles
#

obstacle_nodes.each do |node|
  puts node
end
