if $0 == __FILE__
  require 'rubygems'
  require 'wdd-ruby-ext'
end

class RGBColor
  attr :red, true
  attr :green, true
  attr :blue, true
  
  def initialize( *args )
    if args.length == 0
      raise "Must supply initializer arguments"
    elsif args.length ==1 
      raise "Single argument must be a string" if !args[0].is_a?( String )
      hex_color_string = args[0]
      
      if matches = hex_color_string.match( /#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})/ )
        @red = ("%02d" % "0x#{matches[1]}").to_i
        @green = ("%02d" % "0x#{matches[2]}").to_i
        @blue = ("%02d" % "0x#{matches[3]}").to_i
      elsif  matches = hex_color_string.match( /#?([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})/ )
        @red = ("%02d" % "0x#{matches[1]}#{matches[1]}").to_i
        @green = ("%02d" % "0x#{matches[2]}#{matches[2]}").to_i
        @blue = ("%02d" % "0x#{matches[3]}#{matches[3]}").to_i
      else
        raise "Invalid RGB hex color code #{hex_color_string}" if !matches
      end
    elsif args.length == 3
      args.each do |arg|
        arg = arg.to_i
        raise "Invalid color value #{arg}" if !arg.is_a?( Fixnum ) || arg<0 || arg > 255
      end
      @red = args[0]
      @green = args[1]
      @blue = args[2]
    end
  end
  
  def to_hex
    ("%02x" % @red) + ("%02x" % @green) + ("%02x" % @blue)
  end

  def to_hex!
    '#' + to_hex
  end

  # Lightens the color by +percentage+
  def lighten percentage
    raise "Invalid multiplier #{multiplier}.  Should be >= 0 and <= 100." if percentage < 0 || percentage > 100
    multiplier = percentage.to_f / 100
    new_red = (@red+(multiplier*(255-@red))).min(255).to_i
    new_green = (@green+(multiplier*(255-@green))).min(255).to_i
    new_blue = (@blue+(multiplier*(255-@blue))).min(255).to_i
    return RGBColor.new( new_red, new_green, new_blue )
  end

  # Darkens the color by +percentage+
  def darken percentage
    raise "Invalid multiplier #{multiplier}.  Should be >= 0 and <= 100." if percentage < 0 || percentage > 100
    multiplier = percentage.to_f / 100
    new_red = (@red-multiplier*@red).min(255).to_i
    new_green = (@green-multiplier*@green).min(255).to_i
    new_blue = (@blue-multiplier*@blue).min(255).to_i
    return RGBColor.new( new_red, new_green, new_blue )
  end
  
  def saturation
    least_val = @red.min(@green).min(@blue)
    most_val = @red.max(@green).max(@blue)
    saturation_level = (most_val - least_val).to_f / most_val * 100
  end
  
  def saturate percentage
    min_val = 0
    multiplier = percentage.to_f / 100
    most_val = @red.max(@green).max(@blue)
    return self.dup if most_val <= min_val
    least_val = @red.min(@green).min(@blue)
    red_ratio = 1.0 - @red.to_f / most_val
    green_ratio = 1.0 - @green.to_f / most_val
    blue_ratio = 1.0 - @blue.to_f / most_val
    new_red = @red - red_ratio * (@red - min_val) * multiplier
    new_green = @green - green_ratio * (@green - min_val) * multiplier
    new_blue = @blue - blue_ratio * (@blue - min_val) * multiplier
    # puts "@red: #{@red}"
    # puts "@green: #{@green}"
    # puts "@blue: #{@blue}"
    # puts "new_red: #{new_red}"
    # puts "new_green: #{new_green}"
    # puts "new_blue: #{new_blue}"
    return RGBColor.new( new_red.to_i, new_green.to_i, new_blue.to_i )
  end

  def desaturate percentage
    multiplier = (100.0 - percentage.to_f) / 100
    most_val = @red.max(@green).max(@blue)
    least_val = @red.min(@green).min(@blue)
    range = most_val
    red_ratio = 1.0 - @red.to_f / most_val
    green_ratio = 1.0 - @green.to_f / most_val
    blue_ratio = 1.0 - @blue.to_f / most_val
    highest_ratio = red_ratio.max(green_ratio).max(blue_ratio)
    new_red = most_val - red_ratio * range * multiplier
    new_green = most_val - green_ratio * range * multiplier
    new_blue = most_val - blue_ratio * range * multiplier
    return RGBColor.new( new_red.to_i, new_green.to_i, new_blue.to_i )
  end
  
  def self.color_cycle start, arc_step_in_degrees, iterations, desaturation=0, darken=0
    angle = 0
    two_thirds_PI = 2.0 * Math::PI / 3
    four_thirds_PI = 4.0 * Math::PI / 3
    half_PI = Math::PI / 2
    colors = []
    iterations.times do |i|
      angle = ((start + i*arc_step_in_degrees) * Math::PI * 2) / 360
      red = (Math.cos(angle) + 1) / 2 * 255
      green = (Math.cos(angle + two_thirds_PI) + 1) / 2 * 255
      blue = (Math.cos(angle + four_thirds_PI) +1) / 2 * 255
      desat = (Math.cos(i)+1) / 2 * 60
      dark = (Math.cos(i*2)+1) / 2 * 20
      color = RGBColor.new(red, green, blue).saturate(desat).darken(dark).desaturate(desaturation).darken(darken)
      colors << color
      yield color if block_given?
    end
    colors
  end
end


if $0 == __FILE__
  color = RGBColor.new( "FF8800" )
  puts color.to_hex
  puts color.to_hex!
  color = RGBColor.new( 0xAA, 0x88, 0x44 )
  puts color.to_hex
  puts color.to_hex!
  puts color.saturation
  puts
  puts color.saturate( 0 ).to_hex
  puts color.saturate( 50 ).to_hex
  puts color.saturate( 100 ).to_hex
  puts
  puts color.desaturate( 0 ).to_hex
  puts color.desaturate( 50 ).to_hex
  puts color.desaturate( 100 ).to_hex
  puts color.lighten( 0 ).to_hex
  puts color.lighten( 50 ).to_hex
  puts color.lighten( 100 ).to_hex
  puts color.darken( 0 ).to_hex
  puts color.darken( 50 ).to_hex
  puts color.darken( 100 ).to_hex
  color = RGBColor.new( "#888" )
  puts color.to_hex
  
  colors = RGBColor.color_cycle( 0, 20, 16) {|rgb| puts rgb.to_hex!}
end