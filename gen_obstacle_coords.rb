# Usage: $ ruby gen_obstacle_coords.rb obstacle_map.txt
# ex.) $ ruby gen_road_map.rb 21 "`ruby gen_obstacle_coords.rb obstacle_map.txt`" > road_map.txt
# ex.) $ ruby gen_road_map.rb 24 "`ruby gen_obstacle_coords.rb obstacle_map_invader_24.txt`" > road_map.txt
#      $ ruby AStarAlgorithm.rb road_map.txt

File.open(ARGV[0]) do |file|
  lines = file.readlines
  width_count, height_count = lines.shift.split(",").collect{|val| val.strip.to_i}
  height_count.times do |h|
    lines.shift.chars.each_with_index do |c, i|
      print "(#{i},#{h}) " if c == '#'
    end
  end
  puts
end
