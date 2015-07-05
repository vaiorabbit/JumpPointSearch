# Usage:
# $ ruby benchmark.rb road_map.txt
#                  user     system      total        real
# Dijkstra     2.990000   0.010000   3.000000 (  3.017810)
# A*           1.530000   0.010000   1.540000 (  1.554558)
# JPS          0.520000   0.000000   0.520000 (  0.533521)

require 'benchmark'
require_relative 'JumpPointSearch'

jps = JPSAlgorithm.new
File.open(ARGV[0]) do |file|
  jps.read_roadmap(file)
end
jps.setup_route

heuristic_flag = true
jps_flag       = true

Benchmark.bm 10 do |r|

  heuristic_flag = false
  jps_flag       = false
  r.report "Dijkstra" do
    100.times do
      jps.reset("N481", "N565", use_heuristic: heuristic_flag, use_jps: jps_flag)
      jps.search
    end
  end

  heuristic_flag = true
  jps_flag       = false
  r.report "A*" do
    100.times do
      jps.reset("N481", "N565", use_heuristic: heuristic_flag, use_jps: jps_flag)
      jps.search
    end
  end

  heuristic_flag = true
  jps_flag       = true
  r.report "JPS" do
    100.times do
      jps.reset("N481", "N565", use_heuristic: heuristic_flag, use_jps: jps_flag)
      jps.search
    end
  end

end
