<!-- -*- mode:markdown; coding:utf-8; -*- -->

# Jump Point Search Demonstration #

*   Created : 2015-06-14
*   Last modified : 2015-07-20

A JPS implementation used to make these videos:

* Comparison of search algorithms (A*/JPS)
  * [![](http://img.youtube.com/vi/O81eDgSZfB4/mqdefault.jpg)](https://www.youtube.com/watch?v=O81eDgSZfB4)
* Comparison of search algorithms (Dijkstra/A*/JPS)
  * [![](http://img.youtube.com/vi/ROG4Ud08lLY/mqdefault.jpg)](https://www.youtube.com/watch?v=ROG4Ud08lLY)


## Console Demo ##

    $ ruby JumpPointSearch.rb road_map.txt -astar

↓

<img src="https://raw.githubusercontent.com/vaiorabbit/JumpPointSearch/master/doc/JPS01_AStar.png" width="400">

    $ ruby JumpPointSearch.rb road_map.txt -jps

↓

<img src="https://raw.githubusercontent.com/vaiorabbit/JumpPointSearch/master/doc/JPS02_JPS.png" width="400">


## Reference ##

* Online Graph Pruning for Pathfinding on Grid Maps [D. Harabor and A. Grastien. (2011)]
  * http://users.cecs.anu.edu.au/~dharabor/data/papers/harabor-grastien-aaai11.pdf

* https://en.wikipedia.org/wiki/Jump_point_search


## License ##

The zlib/libpng License ( http://opensource.org/licenses/Zlib ).

    Copyright (c) 2015-2018 vaiorabbit <http://twitter.com/vaiorabbit>

    This software is provided 'as-is', without any express or implied
    warranty. In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
       claim that you wrote the original software. If you use this software in a
       product, an acknowledgment in the product documentation would be
       appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
       misrepresented as being the original software.

    3. This notice may not be removed or altered from any source distribution.
