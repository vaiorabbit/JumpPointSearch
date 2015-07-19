require 'ffi'

module NanoVG
  extend FFI::Library

  #
  # define/enum
  #

  # NVGwinding
  NVG_CCW = 1
  NVG_CW  = 2

  # NVGsolidity
  NVG_SOLID = 1
  NVG_HOLE  = 2

  # NVGlineCap
  NVG_BUTT   = 0
  NVG_ROUND  = 1
  NVG_SQUARE = 2
  NVG_BEVEL  = 3
  NVG_MITER  = 4

  # NVGalign
  #  Horizontal align
  NVG_ALIGN_LEFT     = 1
  NVG_ALIGN_CENTER   = 2
  NVG_ALIGN_RIGHT    = 4
  #  Vertical align
  NVG_ALIGN_TOP      = 8
  NVG_ALIGN_MIDDLE   = 16
  NVG_ALIGN_BOTTOM   = 32
  NVG_ALIGN_BASELINE = 64

  # NVGimageFlags
  NVG_IMAGE_GENERATE_MIPMAPS  = 1
  NVG_IMAGE_REPEATX           = 2
  NVG_IMAGE_REPEATY           = 4
  NVG_IMAGE_FLIPY             = 8
  NVG_IMAGE_PREMULTIPLIED     = 16

  # NVGcreateFlags
  NVG_ANTIALIAS         = 1
  NVG_STENCIL_STROKES   = 2
  NVG_DEBUG             = 4

  #
  # struct
  #

  class NVGcolor < FFI::Struct
    layout(
      :rgba, [:float, 4]
    )
  end

  class NVGpaint < FFI::Struct
    layout(
      :xform,       [:float, 6],
      :extent,      [:float, 2],
      :radius,      :float,
      :feather,     :float,
      :innerColor,  NVGcolor,
      :outerColor,  NVGcolor,
      :image,       :int32
    )
  end

  class NVGglyphPosition < FFI::Struct
    layout(
      :str,  :pointer,
      :x,    :float,
      :minx, :float,
      :maxx, :float
    )
  end

  class NVGtextRow < FFI::Struct
    layout(
      :start, :pointer,
      :end,   :pointer,
      :next,  :pointer,
      :width, :float,
      :minx,  :float,
      :maxx,  :float
    )
  end

  #
  # Load native library.
  #
  @@nanovg_import_done = false

  def self.load_dll(libpath = './libnanovg.dylib', render_backend: :gl2)
    ffi_lib_flags :now, :global # to force FFI to access nvgCreateInternal from nvgCreateGL2
    ffi_lib libpath
    import_symbols(render_backend) unless @@nanovg_import_done
  end

  def self.import_symbols(render_backend)
    #
    # Common API
    #
    attach_function :nvgBeginFrame, :nvgBeginFrame, [:pointer, :int32, :int32, :float], :void
    attach_function :nvgCancelFrame, :nvgCancelFrame, [:pointer], :void
    attach_function :nvgEndFrame, :nvgEndFrame, [:pointer], :void

    attach_function :nvgRGB, :nvgRGB, [:uint8, :uint8, :uint8], NVGcolor.by_value
    attach_function :nvgRGBf, :nvgRGBf, [:float, :float, :float], NVGcolor.by_value
    attach_function :nvgRGBA, :nvgRGBA, [:uint8, :uint8, :uint8, :uint8], NVGcolor.by_value
    attach_function :nvgRGBAf, :nvgRGBAf, [:float, :float, :float, :float], NVGcolor.by_value

    attach_function :nvgLerpRGBA, :nvgLerpRGBA, [NVGcolor.by_value, NVGcolor.by_value, :float], NVGcolor.by_value
    attach_function :nvgTransRGBA, :nvgTransRGBA, [NVGcolor.by_value, :uint8], NVGcolor.by_value
    attach_function :nvgTransRGBAf, :nvgTransRGBAf, [NVGcolor.by_value, :float], NVGcolor.by_value
    attach_function :nvgHSL, :nvgHSL, [:float, :float, :float], NVGcolor.by_value
    attach_function :nvgHSLA, :nvgHSLA, [:float, :float, :float, :uint8], NVGcolor.by_value

    attach_function :nvgSave, :nvgSave, [:pointer], :void
    attach_function :nvgRestore, :nvgRestore, [:pointer], :void
    attach_function :nvgReset, :nvgReset, [:pointer], :void

    attach_function :nvgStrokeColor, :nvgStrokeColor, [:pointer, NVGcolor.by_value], :void
    attach_function :nvgStrokePaint, [:pointer, NVGpaint.by_value], :void
    attach_function :nvgFillColor, [:pointer, NVGcolor.by_value], :void
    attach_function :nvgFillPaint, [:pointer, NVGpaint.by_value], :void
    attach_function :nvgMiterLimit, [:pointer, :float], :void
    attach_function :nvgStrokeWidth, [:pointer, :float], :void
    attach_function :nvgLineCap, [:pointer, :int32], :void
    attach_function :nvgLineJoin, [:pointer, :int32], :void
    attach_function :nvgGlobalAlpha, [:pointer, :float], :void

    attach_function :nvgResetTransform, :nvgResetTransform, [:pointer], :void
    attach_function :nvgTransform, :nvgTransform, [:pointer, :float, :float, :float, :float, :float, :float], :void
    attach_function :nvgTranslate, :nvgTranslate, [:pointer, :float, :float], :void
    attach_function :nvgRotate, :nvgRotate, [:pointer, :float], :void
    attach_function :nvgSkewX, :nvgSkewX, [:pointer, :float], :void
    attach_function :nvgSkewY, :nvgSkewY, [:pointer, :float], :void
    attach_function :nvgScale, :nvgScale, [:pointer, :float, :float], :void
    attach_function :nvgCurrentTransform, :nvgCurrentTransform, [:pointer, :pointer], :void

    attach_function :nvgTransformIdentity, :nvgTransformIdentity, [:pointer], :void
    attach_function :nvgTransformTranslate, :nvgTransformTranslate, [:pointer, :float, :float], :void
    attach_function :nvgTransformScale, :nvgTransformScale, [:pointer, :float, :float], :void
    attach_function :nvgTransformRotate, :nvgTransformRotate, [:pointer, :float], :void
    attach_function :nvgTransformSkewX, :nvgTransformSkewX, [:pointer, :float], :void
    attach_function :nvgTransformSkewY, :nvgTransformSkewY, [:pointer, :float], :void
    attach_function :nvgTransformMultiply, :nvgTransformMultiply, [:pointer, :pointer], :void
    attach_function :nvgTransformPremultiply, :nvgTransformPremultiply, [:pointer, :pointer], :void
    attach_function :nvgTransformInverse, :nvgTransformInverse, [:pointer, :pointer], :int32
    attach_function :nvgTransformPoint, :nvgTransformPoint, [:pointer, :pointer, :pointer, :float, :float], :void

    attach_function :nvgDegToRad, :nvgDegToRad, [:float], :float
    attach_function :nvgRadToDeg, :nvgRadToDeg, [:float], :float

    attach_function :nvgCreateImage, :nvgCreateImage, [:pointer, :pointer, :int32], :int32
    attach_function :nvgCreateImageMem, :nvgCreateImageMem, [:pointer, :int32, :pointer, :int32], :int32
    attach_function :nvgCreateImageRGBA, :nvgCreateImageRGBA, [:pointer, :int32, :int32, :int32, :pointer], :int32
    attach_function :nvgUpdateImage, :nvgUpdateImage, [:pointer, :int32, :pointer], :void
    attach_function :nvgImageSize, :nvgImageSize, [:pointer, :int32, :pointer, :pointer], :void
    attach_function :nvgDeleteImage, :nvgDeleteImage, [:pointer, :int32], :void

    attach_function :nvgLinearGradient, :nvgLinearGradient, [:pointer, :float, :float, :float, :float, NVGcolor.by_value, NVGcolor.by_value], NVGpaint.by_value
    attach_function :nvgBoxGradient, :nvgBoxGradient, [:pointer, :float, :float, :float, :float, :float, :float, NVGcolor.by_value, NVGcolor.by_value], NVGpaint.by_value
    attach_function :nvgRadialGradient, :nvgRadialGradient, [:pointer, :float, :float, :float, :float, NVGcolor.by_value, NVGcolor.by_value], NVGpaint.by_value
    attach_function :nvgImagePattern, :nvgImagePattern, [:pointer, :float, :float, :float, :float, :float, :int32, :float], NVGpaint.by_value

    attach_function :nvgScissor, :nvgScissor, [:pointer, :float, :float, :float, :float], :void
    attach_function :nvgIntersectScissor, :nvgIntersectScissor, [:pointer, :float, :float, :float, :float], :void
    attach_function :nvgResetScissor, :nvgResetScissor, [:pointer], :void

    attach_function :nvgBeginPath, :nvgBeginPath, [:pointer], :void
    attach_function :nvgMoveTo, :nvgMoveTo, [:pointer, :float, :float], :void
    attach_function :nvgLineTo, :nvgLineTo, [:pointer, :float, :float], :void
    attach_function :nvgBezierTo, :nvgBezierTo, [:pointer, :float, :float, :float, :float, :float, :float], :void
    attach_function :nvgQuadTo, :nvgQuadTo, [:pointer, :float, :float, :float, :float], :void
    attach_function :nvgArcTo, :nvgArcTo, [:pointer, :float, :float, :float, :float, :float], :void
    attach_function :nvgClosePath, :nvgClosePath, [:pointer], :void
    attach_function :nvgPathWinding, :nvgPathWinding, [:pointer, :int32], :void
    attach_function :nvgArc, :nvgArc, [:pointer, :float, :float, :float, :float, :float, :int32], :void
    attach_function :nvgRect, :nvgRect, [:pointer, :float, :float, :float, :float], :void
    attach_function :nvgRoundedRect, :nvgRoundedRect, [:pointer, :float, :float, :float, :float, :float], :void
    attach_function :nvgEllipse, :nvgEllipse, [:pointer, :float, :float, :float, :float], :void
    attach_function :nvgCircle, :nvgCircle, [:pointer, :float, :float, :float], :void
    attach_function :nvgFill, :nvgFill, [:pointer], :void
    attach_function :nvgStroke, :nvgStroke, [:pointer], :void

    attach_function :nvgCreateFont, :nvgCreateFont, [:pointer, :pointer, :pointer], :int32
    attach_function :nvgCreateFontMem, :nvgCreateFontMem, [:pointer, :pointer, :pointer, :int32, :int32], :int32
    attach_function :nvgFindFont, :nvgFindFont, [:pointer, :pointer], :int32
    attach_function :nvgFontSize, :nvgFontSize, [:pointer, :float], :void
    attach_function :nvgFontBlur, :nvgFontBlur, [:pointer, :float], :void
    attach_function :nvgTextLetterSpacing, :nvgTextLetterSpacing, [:pointer, :float], :void
    attach_function :nvgTextLineHeight, :nvgTextLineHeight, [:pointer, :float], :void
    attach_function :nvgTextAlign, :nvgTextAlign, [:pointer, :int32], :void
    attach_function :nvgFontFaceId, :nvgFontFaceId, [:pointer, :int32], :void
    attach_function :nvgFontFace, :nvgFontFace, [:pointer, :pointer], :void
    attach_function :nvgText, :nvgText, [:pointer, :float, :float, :pointer, :pointer], :float
    attach_function :nvgTextBox, :nvgTextBox, [:pointer, :float, :float, :float, :pointer, :pointer], :void
    attach_function :nvgTextBounds, :nvgTextBounds, [:pointer, :float, :float, :pointer, :pointer, :pointer], :float
    attach_function :nvgTextBoxBounds, :nvgTextBoxBounds, [:pointer, :float, :float, :float, :pointer, :pointer, :pointer], :void
    attach_function :nvgTextGlyphPositions, :nvgTextGlyphPositions, [:pointer, :float, :float, :pointer, :pointer, :pointer, :int32], :int32
    attach_function :nvgTextMetrics, :nvgTextMetrics, [:pointer, :pointer, :pointer, :pointer], :void
    attach_function :nvgTextBreakLines, :nvgTextBreakLines, [:pointer, :pointer, :pointer, :float, :pointer, :int32], :int32

    #
    # GL2-specific API (nanovg_gl)
    #
    if render_backend == :gl2
      attach_function :nvgCreateGL2, :nvgCreateGL2, [:int32], :pointer
      attach_function :nvgDeleteGL2, :nvgDeleteGL2, [:pointer], :void
      attach_function :nvgSetupGL2, :nvgSetupGL2, [], :void
    end

    #
    # GL3-specific API (nanovg_gl)
    #
    if render_backend == :gl3
      attach_function :nvgCreateGL3, :nvgCreateGL3, [:int32], :pointer
      attach_function :nvgDeleteGL3, :nvgDeleteGL3, [:pointer], :void
      attach_function :nvgSetupGL3, :nvgSetupGL3, [], :void
    end

    @@nanovg_import_done = true
  end
end

=begin
NanoVG-Bindings : A Ruby bindings of NanoVG
Copyright (c) 2015 vaiorabbit

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
=end
