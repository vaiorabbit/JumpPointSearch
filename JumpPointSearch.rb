# coding: utf-8

#
# Ref.: Online Graph Pruning for Pathfinding on Grid Maps [D. Harabor and A. Grastien. (2011)]
#       http://users.cecs.anu.edu.au/~dharabor/data/papers/harabor-grastien-aaai11.pdf
#

# Usage: $ ruby JumpPointSearch.rb road_map.txt [-dijkstra] [-astar]
class String
  # Ref.: http://stackoverflow.com/questions/1489183/colorized-ruby-output
  def black;          "\033[30m#{self}\033[0m" end
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def brown;          "\033[33m#{self}\033[0m" end
  def blue;           "\033[34m#{self}\033[0m" end
  def magenta;        "\033[35m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def gray;           "\033[37m#{self}\033[0m" end
  def bg_black;       "\033[40m#{self}\033[0m" end
  def bg_red;         "\033[41m#{self}\033[0m" end
  def bg_green;       "\033[42m#{self}\033[0m" end
  def bg_brown;       "\033[43m#{self}\033[0m" end
  def bg_blue;        "\033[44m#{self}\033[0m" end
  def bg_magenta;     "\033[45m#{self}\033[0m" end
  def bg_cyan;        "\033[46m#{self}\033[0m" end
  def bg_gray;        "\033[47m#{self}\033[0m" end
  def bold;           "\033[1m#{self}\033[22m" end
  def reverse_color;  "\033[7m#{self}\033[27m" end
  def no_colors;      self.gsub(/\033\[\d+m/, "") end

  def start_color;    self.bg_green.gray       end
  def goal_color;     self.bg_magenta.gray     end
  def path_color;     self.blue                end
  def obstacle_color; self.bg_black.gray       end
  def visited_color;  self.cyan                end
end

def clamp(x, min, max)
  [[x, max].min, min].max
end


class JPSAlgorithm

  class Node
    attr_accessor :id, :edges, :x, :y

    def initialize(node_id)
      @id = node_id
      @edges = []
    end

    def neighbors
      return Hash[@edges.collect {|edge| [edge.other(self), edge.cost] }] # node => edge.cost
    end

    #↓↓↓ for JPS ↓↓↓#

    def neighbor_at(dx, dy) # d{x|y} = {-1, 0, 1}
      if dx == 0 && dy == 0
        return nil
      else
        edge = @edges.find {|edge| edge.other(self).x == (@x + dx) && edge.other(self).y == (@y + dy)}
        return edge == nil ? nil : [edge.other(self), edge.cost]
      end
    end

    def obstacle_at(dx, dy) # d{x|y} = {-1, 0, 1}
      return neighbor_at(dx, dy) == nil
    end
    private :obstacle_at

    CENTER    = [  0,  0]
    NORTH     = [  0, -1] # ↑
    NORTHEAST = [  1, -1] # ↗
    EAST      = [  1,  0] # →
    SOUTHEAST = [  1,  1] # ↘
    SOUTH     = [  0,  1] # ↓
    SOUTHWEST = [ -1,  1] # ↙
    WEST      = [ -1,  0] # ←
    NORTHWEST = [ -1, -1] # ↖

    def direction(dx, dy)
      return case
             when dx == -1 && dy == -1; NORTHWEST
             when dx == -1 && dy ==  0; WEST
             when dx == -1 && dy ==  1; SOUTHWEST
             when dx ==  0 && dy == -1; NORTH
             when dx ==  0 && dy ==  0; CENTER
             when dx ==  0 && dy ==  1; SOUTH
             when dx ==  1 && dy == -1; NORTHEAST
             when dx ==  1 && dy ==  0; EAST
             when dx ==  1 && dy ==  1; SOUTHEAST
             end
    end
    private :direction

    def natural_neighbors(dx, dy)
      return neighbors() if dx == 0 && dy == 0 # self == Start Node, parent_node == nil

      dirs = case direction(dx, dy)
             when NORTHWEST; [NORTHWEST, NORTH, WEST] # NW
             when WEST;      [WEST]                   # W
             when SOUTHWEST; [SOUTHWEST, SOUTH, WEST] # SW
             when NORTH;     [NORTH]                  # N
             when SOUTH;     [SOUTH]                  # S
             when NORTHEAST; [NORTHEAST, NORTH, EAST] # NE
             when EAST;      [EAST]                   # E
             when SOUTHEAST; [SOUTHEAST, SOUTH, EAST] # SE
             end

      nn = Hash.new
      dirs.each do |dir|
        neighbor = neighbor_at(*dir) # n = node => cost
        nn.store(neighbor[0], neighbor[1]) unless neighbor == nil
      end

      return nn
    end
    private :natural_neighbors

    def forced_neighbors(dx, dy)
      return neighbors() if dx == 0 && dy == 0 # self == Start Node, parent_node == nil

      forced = [] # Array of [node, node_cost] information
      case direction(dx, dy)
      when NORTHWEST
        forced << neighbor_at(*NORTHEAST) if obstacle_at(*WEST)  # if West  is obstacle then mark NorthEast as forced
        forced << neighbor_at(*SOUTHWEST) if obstacle_at(*SOUTH) # if South is obstacle then mark SouthWest as forced
      when WEST
        forced << neighbor_at(*NORTHWEST) if obstacle_at(*NORTH) # if North is obstacle then mark NorthWest as forced
        forced << neighbor_at(*SOUTHWEST) if obstacle_at(*SOUTH) # if South is obstacle then mark SouthWest as forced
      when SOUTHWEST
        forced << neighbor_at(*NORTHWEST) if obstacle_at(*NORTH) # if North is obstacle then mark NorthWest as forced
        forced << neighbor_at(*SOUTHEAST) if obstacle_at(*EAST)  # if East  is obstacle then mark SouthEast as forced
      when NORTH
        forced << neighbor_at(*NORTHEAST) if obstacle_at(*EAST)  # if East  is obstacle then mark NorthEast as forced
        forced << neighbor_at(*NORTHWEST) if obstacle_at(*WEST)  # if West  is obstacle then mark NorthWest as forced
      when SOUTH
        forced << neighbor_at(*SOUTHEAST) if obstacle_at(*EAST)  # if East  is obstacle then mark SouthEast as forced
        forced << neighbor_at(*SOUTHWEST) if obstacle_at(*WEST)  # if West  is obstacle then mark SouthWest as forced
      when NORTHEAST
        forced << neighbor_at(*SOUTHEAST) if obstacle_at(*SOUTH) # if South is obstacle then mark SouthEast as forced
        forced << neighbor_at(*NORTHWEST) if obstacle_at(*WEST)  # if West  is obstacle then mark NorthWest as forced
      when EAST
        forced << neighbor_at(*NORTHEAST) if obstacle_at(*NORTH) # if North is obstacle then mark NorthEast as forced
        forced << neighbor_at(*SOUTHEAST) if obstacle_at(*SOUTH) # if South is obstacle then mark SouthEast as forced
      when SOUTHEAST
        forced << neighbor_at(*NORTHEAST) if obstacle_at(*NORTH) # if North is obstacle then mark NorthEast as forced
        forced << neighbor_at(*SOUTHWEST) if obstacle_at(*WEST)  # if West  is obstacle then mark SouthWest as forced
      end

      fn = Hash.new
      forced.each do |node_and_cost| # node => cost
        fn.store(node_and_cost[0], node_and_cost[1]) unless node_and_cost == nil
      end

      return fn
    end

    def pruned_neighbors(parent_node)
      dx = parent_node == nil ? 0 : clamp(@x - parent_node.x, -1, 1)
      dy = parent_node == nil ? 0 : clamp(@y - parent_node.y, -1, 1)

      nn = natural_neighbors(dx, dy)
      fn = forced_neighbors(dx, dy)
      return nn.merge(fn)
    end

    #↑↑↑ for JPS ↑↑↑#

  end

  ################################################################################

  class Edge
    attr_accessor :cost, :node_id, :nodes

    def initialize(cost, node_id0, node_id1)
      @cost = cost
      @node_id = [node_id0, node_id1]
      @nodes = [nil, nil]
    end

    def other(node)
      return node == @nodes[0] ? @nodes[1] : @nodes[0]
    end
  end

  ################################################################################

  class Route
    attr_accessor :found, :start_id, :goal_id
    attr_reader :map_width, :map_height

    def initialize
      @parents = Hash.new # child -> parent
      @real_costs = Hash.new # child -> real cost
      @heuristic_costs = Hash.new # child -> heuristic cost
      reset()
    end

    def reset
      @parents.clear
      @real_costs.clear
      @heuristic_costs.clear
      @found = false
      @start_id = ""
      @goal_id = ""
    end

    def record(child, parent, real_cost, heuristic_cost)
      @parents[child] = parent
      @real_costs[child] = real_cost
      @heuristic_costs[child] = heuristic_cost
    end

    def parent(child)
      return @parents.has_key?(child) ? @parents[child] : nil
    end

    def cost(node, eval_heuristic: true)
      if @real_costs.has_key?(node)
        return eval_heuristic ? @real_costs[node] + @heuristic_costs[node] : @real_costs[node]
      else
        return Float::MAX
      end
    end

    def estimated_cost(node); return cost(node, eval_heuristic: true);  end
    def real_cost(node);      return cost(node, eval_heuristic: false); end

    def get_path()
      return [] if not @found
      path = []
      parent = @parents.keys.find {|child| child.id == @goal_id}
      while parent != nil
        path.unshift(parent)
        parent = @parents[parent]
      end
      return path
    end
  end

  ################################################################################

  def initialize
    @road_map = [] # Array of Edge
    @nodes = Hash.new
    @route = Route.new
    @use_heuristic = true
    @search_iter = 0
    @obstacles = [] # Array of Node ID
    @visited = [] # Node ID
  end


  def read_roadmap(roadmap_input)
    csv_lines = roadmap_input.readlines
    nodes_count, edges_count, obstacles_count = csv_lines.shift.split(",").collect{|val| val.strip.to_i}

    # Nodes
    nodes_count.times do |i|
      id, x, y = csv_lines.shift.split(",")
      @nodes[id] = Node.new(id)
      @nodes[id].x = x.to_i
      @nodes[id].y = y.to_i
    end
    @render_map_width  = @nodes.values.map{|n| n.x }.max + 1
    @render_map_height = @nodes.values.map{|n| n.y }.max + 1
    @render_cell_width = @nodes.values.map{|n| n.id.length }.max + 1

    # Edges
    edges_count.times do |i|
      cost, node0_id, node1_id = csv_lines.shift.split(",")
      @road_map << Edge.new(cost.to_f, node0_id.strip, node1_id.strip)
    end

    # Obstacles
    @obstacles.clear
    obstacles_count.times do |i|
      @obstacles << csv_lines.shift.strip
    end
    @obstacles.each do |node_id|
      @road_map = @road_map.reject {|edge| edge.node_id.include?(node_id)}
    end
  end


  def setup_route
    @road_map.each do |edge|
      edge.node_id.each_with_index do |id, index|
        @nodes[id] = Node.new(id) unless @nodes.has_key? id
        edge.nodes[index] = @nodes[id]
      end
    end

    @road_map.each do |edge|
      @nodes[edge.node_id[0]].edges << edge
      @nodes[edge.node_id[1]].edges << edge
    end
  end


  @@heuristic_Zero        = Proc.new { |node, goal| 0.0 }                                                     # Always 0 (Dijkstra's algorithm)
  @@heuristic_MaxDiff     = Proc.new { |node, goal| [(node.x - goal.x).abs, (node.y - goal.y).abs].max }      # h = max(|dx|, |dy|)
  @@heuristic_Manhattan   = Proc.new { |node, goal| (node.x - goal.x).to_f.abs + (node.y - goal.y).to_f.abs } # Manhattan Distance (for non-diagonal map only)
  @@heuristic_Pythagorean = Proc.new { |node, goal| Math.sqrt((node.x - goal.x)**2 + (node.y - goal.y)**2) }  # Pythagorean theorem

  def reset(start_id, goal_id, use_heuristic: true, use_jps: true)
    @route.reset
    @route.start_id = start_id
    @route.goal_id  = goal_id
    @route.record(@nodes[start_id], nil, 0.0, 0.0)

    @use_heuristic = use_heuristic
    @heuristic     = use_heuristic ? @@heuristic_MaxDiff : @@heuristic_Zero

    @use_jps = use_jps

    @visited.clear
    @search_iter = 0
  end


  #↓↓↓ for JPS ↓↓↓#

  # See "Algorithm 2  Function jump"
  def jump(x, dx, dy)
    node_and_cost = x.neighbor_at(dx, dy)
    return nil if node_and_cost == nil

    n = node_and_cost[0]
    return n if n == @nodes[@route.goal_id]
    return n if n.forced_neighbors(dx, dy).length > 0

    if dx != 0 && dy != 0
      return n if jump(n, dx,  0) != nil
      return n if jump(n,  0, dy) != nil
    end

    return jump(n, dx, dy)
  end

  #
  # Jump Point Search (JPS) Implementation
  #
  def search_jps
    open_list  = [@nodes[@route.start_id]]
    close_list = []
    goal = @nodes[@route.goal_id]

    until open_list.empty?
      n = open_list.min_by { |node| @route.estimated_cost(node) }
      if n == goal
        @route.found = true
        break
      end

      close_list.push( open_list.delete(n) )

      adjacents_of_n = n.pruned_neighbors(@route.parent(n))
      adjacents_of_n.keys.each do |m|
        j = jump(n, clamp(m.x - n.x, -1, 1), clamp(m.y - n.y, -1, 1))
        next if j == nil or close_list.include?(j)
        h = @heuristic.call(j, goal)
        new_real_cost_j      = @route.real_cost(n) + Math.sqrt((n.x-j.x)**2 + (n.y-j.y)**2)  # g
        new_estimated_cost_j = new_real_cost_j + h                                           # f = g + h
        if open_list.include?(j)
          # If estimated costs are equal then use real costs for more precise comparison (or we may get less optimal path).
          next if new_estimated_cost_j >  @route.estimated_cost(j)
          next if new_estimated_cost_j == @route.estimated_cost(j) && new_real_cost_j >= @route.real_cost(j)
          @route.record(j, n, new_real_cost_j, h)
        else
          open_list.push(j)
          @route.record(j, n, new_real_cost_j, h)
        end
        @visited << j.id unless @visited.include? j.id # stats
      end
      @search_iter += 1 # stats
    end
  end

  #↑↑↑ for JPS ↑↑↑#

  #
  # A* Implementation
  #
  def search_astar
    open_list  = [@nodes[@route.start_id]]
    close_list = []
    goal = @nodes[@route.goal_id]

    until open_list.empty?
      n = open_list.min_by { |node| @route.estimated_cost(node) }
      if n == goal
        @route.found = true
        break
      end

      close_list.push( open_list.delete(n) )

      adjacents_of_n = n.neighbors # Hash [neighbor_node => edge.cost]
      adjacents_of_n.each do |m, edge_cost|
        next if close_list.include?(m)
        h = @heuristic.call(m, goal)
        new_real_cost_m      = @route.real_cost(n) + edge_cost # g
        new_estimated_cost_m = new_real_cost_m + h             # f = g + h
        if open_list.include?(m)
          # If estimated costs are equal then use real costs for more precise comparison (or we may get less optimal path).
          next if new_estimated_cost_m >  @route.estimated_cost(m)
          next if new_estimated_cost_m == @route.estimated_cost(m) && new_real_cost_m >= @route.real_cost(m)
          @route.record(m, n, new_real_cost_m, h)
        else
          open_list.push(m)
          @route.record(m, n, new_real_cost_m, h)
        end
      end

      # stats
      adjacents_of_n.each_key {|n| @visited << n.id unless @visited.include? n.id}
      @search_iter += 1
    end
  end


  def search
    @use_jps ? search_jps : search_astar
  end

  def found;    return @route.found; end
  def get_path; return @route.get_path; end
  def goal_id;  return @route.goal_id; end

  def direction_symbol(next_node, current_node)
    case
    when next_node.x < current_node.x
      case
      when next_node.y <  current_node.y; "↖" # U+2196
      when next_node.y == current_node.y; "←"
      when next_node.y >  current_node.y; "↙" # U+2199
      end
    when next_node.x == current_node.x
      case
      when next_node.y <  current_node.y; "↑"
      when next_node.y == current_node.y; " "
      when next_node.y >  current_node.y; "↓"
      end
    when next_node.x > current_node.x
      case
      when next_node.y <  current_node.y; "↗" # U+2197
      when next_node.y == current_node.y; "→"
      when next_node.y >  current_node.y; "↘" # U+2198
      end
    end
  end
  private :direction_symbol

  def render_cell(path, n)
    if n == nil
      print "_" * (@render_cell_width - 1)
    else
      colorizer = case
                  when n.id == @route.start_id;   :start_color
                  when n.id == @route.goal_id;    :goal_color
                  when @obstacles.include?(n.id); :obstacle_color
                  when path.find{|node| node.id == n.id} != nil; :path_color
                  when @visited.include?(n.id);   :visited_color
                  else :no_colors
                  end
      path_index = path.find_index(n)
      symbol = n.id + case
                      when path_index == nil; ""
                      when n.id == @route.start_id || colorizer == :path_color;  direction_symbol(path[path_index+1], n)
                      when n.id == @route.goal_id;  "•" # U+2022
                      else ""
                      end
      print %Q{#{symbol}#{" " * (@render_cell_width - symbol.length)}}.send(colorizer)
    end
  end
  private :render_cell

  def render
    puts "#iteration = #{@search_iter} [@use_heuristic == #{@use_heuristic}, @use_jps == #{@use_jps}]"
    path = self.get_path
    if path != nil
      @render_map_height.times do |h|
        @render_map_width.times do |w|
          n = @nodes.values.find{|n| n.x == w && n.y == h}
          render_cell(path, n)
        end # End : @render_map_width.times do |w|
        puts
      end # End : @render_map_height.times do |h|
    end
  end

end


if __FILE__ == $0
  jps = JPSAlgorithm.new
  File.open(ARGV[0]) do |file|
    jps.read_roadmap(file)
  end
  jps.setup_route

  heuristic_flag = true
  jps_flag       = true

  if ARGV.include?("-dijkstra")
    heuristic_flag = false
    jps_flag       = false
  elsif ARGV.include?("-astar")
    heuristic_flag = true
    jps_flag       = false
  end

  jps.reset("N481", "N502", use_heuristic: heuristic_flag, use_jps: jps_flag)
# jps.reset("N24", "N575", use_heuristic: heuristic_flag, use_jps: jps_flag)
# jps.reset("N1", "N2303", use_heuristic: heuristic_flag, use_jps: jps_flag)
#  jps.reset("N1", "N3905", use_heuristic: heuristic_flag, use_jps: jps_flag)
  jps.search

  if jps.found
    jps.get_path.each do |node|
      print node.id
      print node.id == jps.goal_id ? "\n" : " → "
    end
  end

  jps.render
end
