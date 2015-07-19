# coding: utf-8
require 'opengl'
require 'glfw'
require_relative './nanovg'
require_relative './JumpPointSearch'


OpenGL.load_dll()
GLFW.load_dll()
NanoVG.load_dll('libnanovg_gl2.dylib')

include OpenGL
include GLFW
include NanoVG

# Saves as .tga
$ss_name = "ss00000.tga"
$ss_id = 0
def save_screenshot(w, h, name)
  image = FFI::MemoryPointer.new(:uint8, w*h*4)
  return if image == nil

  glReadPixels(0, 0, w, h, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, image)

  File.open( name, 'wb' ) do |fout|
    fout.write [0].pack('c')      # identsize
    fout.write [0].pack('c')      # colourmaptype
    fout.write [2].pack('c')      # imagetype
    fout.write [0].pack('s')      # colourmapstart
    fout.write [0].pack('s')      # colourmaplength
    fout.write [0].pack('c')      # colourmapbits
    fout.write [0].pack('s')      # xstart
    fout.write [0].pack('s')      # ystart
    fout.write [w].pack('s')      # image_width
    fout.write [h].pack('s')      # image_height
    fout.write [8 * 4].pack('c')  # image_bits_per_pixel
    fout.write [8].pack('c')      # descriptor

    fout.write image.get_bytes(0, w*h*4)
  end
end


module Arrow

  def self.render(vg, src_x, src_y, dst_x, dst_y, head_length: 100.0, head_width: head_length/3, shaft_width: head_width/2,
                  outer_line: true, inner_fill: true, outer_width: 2.5, outer_color: nvgRGBA(255,255,0,255), gradient_start: nvgRGBA(255,192,0,0), gradient_end: nvgRGBA(255,192,0,255))

    arrow_length = Math.sqrt((dst_x - src_x)**2 + (dst_y - src_y)**2)
    bottom_x = 0.0
    bottom_y = 0.0
    toptip_x = arrow_length
    toptip_y = 0.0
    shaft_length = arrow_length - head_length
    arrow_length_base = Math.sqrt((bottom_x - toptip_x)**2 + (bottom_y - toptip_y)**2)

    theta = Math.atan2( (dst_y - src_y)/arrow_length, (dst_x - src_x) / arrow_length )

    nvgSave(vg)
    nvgTranslate(vg, src_x,src_y)
    nvgRotate(vg, theta)

    nvgBeginPath(vg)
    nvgMoveTo(vg, bottom_x, bottom_y)
    nvgLineTo(vg, bottom_x, bottom_y + shaft_width / 2)
    nvgLineTo(vg, bottom_x + shaft_length, bottom_y + shaft_width / 2)
    nvgLineTo(vg, bottom_x + shaft_length, bottom_y + head_width / 2)
    nvgLineTo(vg, bottom_x + arrow_length, bottom_y)
    nvgLineTo(vg, bottom_x + shaft_length, bottom_y - head_width / 2)
    nvgLineTo(vg, bottom_x + shaft_length, bottom_y - shaft_width / 2)
    nvgLineTo(vg, bottom_x, bottom_y - shaft_width / 2)
    nvgClosePath(vg)

    # Outer Line
    if outer_line
      nvgStrokeWidth(vg, outer_width)
      nvgStrokeColor(vg, outer_color)
      nvgStroke(vg)
    end

    # Inner Area
    if inner_fill
      paint = nvgLinearGradient(vg, bottom_x,bottom_y, bottom_x+arrow_length,bottom_y, gradient_start, gradient_end)
      nvgFillPaint(vg, paint)
      nvgFill(vg)
    end

    nvgRestore(vg)
  end

end


$step_search = false
# Press ESC to exit.
key = GLFW::create_callback(:GLFWkeyfun) do |window, key, scancode, action, mods|
  if key == GLFW_KEY_ESCAPE && action == GLFW_PRESS
    glfwSetWindowShouldClose(window, GL_TRUE)
  end
  if key == GLFW_KEY_S && action == GLFW_PRESS
    $step_search = true
  end
end



class JPSAlgorithm
  def render_nanovg(vg, base_x, base_y, width, height)
    dw = width / @render_map_width.to_f
    dh = height / @render_map_height.to_f
    path = self.get_path
    nvgBeginPath(vg)
    @render_map_height.times do |h|
      nvgMoveTo(vg, base_x, base_y+h*dh)
      nvgLineTo(vg, base_x+width, base_y+h*dh)
    end
    @render_map_width.times do |w|
      nvgMoveTo(vg, base_x+w*dw, base_y)
      nvgLineTo(vg, base_x+w*dw, base_y+height)
    end
    nvgStrokeWidth(vg, 1.0)
    nvgStrokeColor(vg, nvgRGBA(255,255,255,255))
    nvgStroke(vg)

    @render_map_height.times do |h|
      @render_map_width.times do |w|
        n = @nodes.values.find{|n| n.x == w && n.y == h}
        color = nvgRGBA(128,128,128,255)
        if n != nil
          color = case
                  when n.id == @route.start_id;   nvgRGBA(0,255,0,255)
                  when n.id == @route.goal_id;    nvgRGBA(255,0,0,255)
                  when @obstacles.include?(n.id); nvgRGBA(0,0,0,255)
                  when path != nil && path.find{|node| node.id == n.id} != nil; nvgRGBA(0,0,255,255)
                  when search_done?()==false && @open_list.empty? == false && (@open_list.last.id == n.id); nvgRGBA(0,255,255,255)
                  when search_done?()==false && @visited.include?(n.id);   nvgRGBA(0,128,128,255)
                  else nvgRGBA(192,192,192,255)
                  end
        end
        nvgBeginPath(vg)
        nvgRect(vg, base_x+w*dw+dw*0.05,base_y+h*dh+dh*0.05, dw*0.9, dh*0.9)
        nvgFillColor(vg, color)
        nvgFill(vg)
      end # End : @render_map_width.times do |w|
    end # End : @render_map_height.times do |h|

    if search_done?
      @render_map_height.times do |h|
        @render_map_width.times do |w|
          current_node = @nodes.values.find{|n| n.x == w && n.y == h}
          path_index = path.find_index(current_node)
          color = nvgRGBA(128,255,0,255)
          if current_node != nil && path.find{|node| node.id == current_node.id} != nil
            next_node = path[path_index+1]
            if next_node != nil
              d = direction_symbol(next_node, current_node)
              Arrow::render(vg, base_x+w*dw+dw*0.5,base_y+h*dh+dh*0.5, base_x+(next_node.x)*dw+dw*0.5, base_y+(next_node.y)*dh+dh*0.5,
                                   head_length: dw*0.2, head_width: dw/2, shaft_width: dw/4
                           )
            end
          end
        end # End : @render_map_width.times do |w|
      end # End : @render_map_height.times do |h|
    end
  end
end

if __FILE__ == $0

  ################################################################################

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

  jps.reset("N481", "N502", use_heuristic: heuristic_flag, use_jps: jps_flag) # road_map.txt
#  jps.reset("N1", "N3905", use_heuristic: heuristic_flag, use_jps: jps_flag) # road_map_maze64.txt

  ################################################################################

  if glfwInit() == GL_FALSE
    puts("Failed to init GLFW.")
    exit
  end

  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2)
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0)

  window = glfwCreateWindow( 1280, 720, "JPSRenderNanoVG", nil, nil )
  if window == 0
    glfwTerminate()
    exit
  end

  glfwSetKeyCallback( window, key )
  glfwMakeContextCurrent( window )

  nvgSetupGL2()
  vg = nvgCreateGL2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG)
  if vg == nil
    puts("Could not init nanovg.")
    exit
  end

  glfwSwapInterval(0)
  glfwSetTime(0)
  prevt = glfwGetTime()

  winWidth_buf  = '        '
  winHeight_buf = '        '
  fbWidth_buf  = '        '
  fbHeight_buf = '        '

  while glfwWindowShouldClose( window ) == 0
    t = glfwGetTime()
    dt = t - prevt
    prevt = t

#    if $step_search
      jps.search_step unless jps.search_done?
#      $step_search = false
#    end

    glfwGetWindowSize(window, winWidth_buf, winHeight_buf)
    glfwGetFramebufferSize(window, fbWidth_buf, fbHeight_buf)
    winWidth = winWidth_buf.unpack('L')[0]
    winHeight = winHeight_buf.unpack('L')[0]
    fbWidth = fbWidth_buf.unpack('L')[0]
    fbHeight = fbHeight_buf.unpack('L')[0]

    pxRatio = fbWidth.to_f / winWidth.to_f

    glViewport(0, 0, fbWidth, fbHeight)
    glClearColor(0.3, 0.3, 0.32, 1.0)
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT)
    if true # jps.search_done?
      nvgBeginFrame(vg, winWidth, winHeight, pxRatio)
      jps.render_nanovg(vg, 0.0, 0.0, fbWidth, fbHeight)
      nvgEndFrame(vg)
    end

    glfwSwapBuffers( window )
    glfwPollEvents()
=begin
    $ss_name = sprintf("ss%05d.tga", $ss_id)
    save_screenshot(fbWidth, fbHeight, $ss_name)
    $ss_id += 1
=end
  end

  nvgDeleteGL2(vg)

  glfwTerminate()
end
