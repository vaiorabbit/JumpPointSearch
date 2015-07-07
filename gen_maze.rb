# Usage: $ ruby gen_maze.rb 24 > obstacle_map.txt

$map_wh = ARGV[0].to_i

$map = Array.new($map_wh).map { Array.new($map_wh, '#') }

DIR = [[-1, 0], [1, 0], [0, -1], [0, 1]]

def dig(x, y)
  dir = DIR.shuffle

  4.times do |i|
    dx = dir[i][0]
    dy = dir[i][1]
    next if (x + dx) < 0 || ($map_wh <= x + dx) || (y + dy) < 0 || ($map_wh <= y + dy)
    if $map[y + dy * 2][x + dx * 2] == '#'
      $map[y + dy][x + dx] = '_'
      $map[y + dy * 2][x + dx * 2] = '_'
      dig(x + dx * 2, y + dy * 2)
    end
  end
end


odd_numbers = (1..$map_wh).step(2).to_a
dig(odd_numbers.sample, odd_numbers.sample)

puts "#{$map_wh},#{$map_wh}"
$map_wh.times do |y|
  $map_wh.times do |x|
    print $map[y][x]
  end
  puts
end
