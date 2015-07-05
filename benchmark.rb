# Usage:
# $ ruby benchmark.rb road_map.txt
#                  user     system      total        real
# Dijkstra     2.980000   0.010000   2.990000 (  3.001365)
# A*           2.170000   0.010000   2.180000 (  2.234452)
# JPS          0.690000   0.000000   0.690000 (  0.696792)

require 'benchmark'
require_relative 'JumpPointSearch'

jps = JPSAlgorithm.new
File.open(ARGV[0]) do |file|
  jps.read_roadmap(file)
end
jps.setup_route

n = ARGV[1].to_i

heuristic_flag = true
jps_flag       = true

Benchmark.bm 10 do |r|

  heuristic_flag = false
  jps_flag       = false
  r.report "Dijkstra" do
    n.times do
      jps.reset("N481", "N502", use_heuristic: heuristic_flag, use_jps: jps_flag)
      jps.search
    end
  end

  heuristic_flag = true
  jps_flag       = false
  r.report "A*" do
    n.times do
      jps.reset("N481", "N502", use_heuristic: heuristic_flag, use_jps: jps_flag)
      jps.search
    end
  end

  heuristic_flag = true
  jps_flag       = true
  r.report "JPS" do
    n.times do
      jps.reset("N481", "N502", use_heuristic: heuristic_flag, use_jps: jps_flag)
      jps.search
    end
  end

end
