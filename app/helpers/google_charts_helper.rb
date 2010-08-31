require 'rgb_color'
# require 'digest/sha1'
require 'base64'
require 'uri'

module GoogleChartsHelper
  IMAGES_PATH = "images/charts"
  IMAGES_ROOT = "#{RAILS_ROOT}/public/#{IMAGES_PATH}"
  
  #############################################################################
  ##
  ############## GOOGLE CHARTS  #######################
  #
  ## The google charts get used in the emailed reports, since the amCharts are flash-only 
  
  private
    # cycle of mostly pleasant colors to use in the google charts
    def default_color_train
      %w{#5D1880 #905717 #3E841F #193FBE #9B3E15 #C22DDE #00FFFF #9200C6 #4466AA}
    end
  
    # Assigns defaults to unspecified chart options
    def process_google_options options
      options[:width] ||= 360
      options[:height] ||= 240
      options[:background] = options[:background_color] || options[:background] || 'eeeeee'
      options[:line_thickness] ||= options[:line_width]
      options[:colors] ||= default_color_train
      options[:lighten_background] ||= 0 #percent
      options[:backgroud_shading_angle] ||= 45 # degrees
      options[:axes_color] ||= '444444'
      options[:title_color] ||= '222222'
      options[:y_min] ||= 0
      options[:colors].each_with_index do |color,i|
        if color =~ /#?([0-9a-fA-F]{2}[0-9a-fA-F]{2}[0-9a-fA-F]{2})/
          options[:colors][i] = $1 # strip off the preceding #
        end
      end
      options[:img_width] ||= options[:width]
      options[:img_height] ||= options[:height]
      options[:show_legend] = true if options[:show_legend] == nil
      options[:show_labels] = false if options[:show_labels] == nil
      options
    end
    
    # Downloads the image from google and returns a localized URL
    def self.cache_google_chart url
      time = Time.now.utc
      token = "#{"0.x" % time.to_i}.#{"0.x" % time.usec}.#{Digest::SHA1.hexdigest(url)}"      
      url_token_filename = "#{token}.jpg"
      host = "chart.apis.google.com"
      matches = url.match /http:\/\/#{host}(\/.*)/
      raise "Invalid Google Chart URL" unless matches
      path = matches[1]
      raise "Invalid Google Chart URL" unless path
      
      FileUtils.mkdir_p( IMAGES_ROOT )
      Net::HTTP.start(host) { |http|
        resp = http.get(path)
        File.open("#{IMAGES_ROOT}/#{url_token_filename}", "wb") { |file|
          file.write(resp.body)
         }
      }
      cached_img_url = "#{$APP_CONFIG.site_url}/#{IMAGES_PATH}/#{url_token_filename}"
    end
    
    # determine if the image shoud be cached and return the appropriate URL
    def self.create_img_tag google_url, options={}
      if options[:cached]
        url = GoogleChartsHelper.cache_google_chart google_url
      else
        url = google_url
      end
      "<img src=\"#{url}\" width=\"#{options[:img_width]}\" height=\"#{options[:img_height]}\">"
    end
    
  public
    
    # Generates a Google Pie Chart showing the percentages 
    #
    # +section+ => an array of [name, data] pairs for each section of the pie chart. The name is used as the
    #   label for the section.  The data is used to determine the percentages of each section.  This is a required option.
    # +options+ are optional as follows:
    # :width => chart width, default is 360
    # :height => chart height, default is 240
    # :title => chart title, default is Topic name and :group_by column name
    # :colors => an optional array of colors to be used for the slices.
    # :show_legend => boolean
    #
    # Example (within a view):
    #
    # <%= google_chart_composition( [["Siamese", 2], ["Calico", 3], ["Black", 8]], {:width=>400, :height=>300, :title=>"Cats" } ) %>
    #
    def google_chart_composition sections, options={}
      options = process_google_options(options)
      width = options[:width]
      height = options[:height]
      bgcolor = options[:background]
      colors = options[:colors]

      x_size = width
      y_size = height
      is_3d = false

      if x_size < y_size then min_size=x_size; else min_size=y_size; end
      marker_size = (min_size.to_f / 40).to_i
      if is_3d
        x_margin_size = (x_size.to_f / 5.8).to_i
      else
        x_margin_size = (x_size.to_f / 3.5).to_i
        # if x_margin_size > 45 then x_margin_size=45; end
      end
      y_margin_size = y_size.to_f / 10

      legend_x = x_size / 2
      legend_y = y_size / 10
      bgcolor = options[:background] || 'FFC8C8'
  
      if !options[:title]
        title = "#{name} Sentiment"
      else
        title = "#{options[:title]}"
      end
    
      total = 0
      sections.each do |section_data|
        total += section_data.last
      end
      
      chart_url = nil
      GoogleChart::PieChart.new("#{x_size}x#{y_size}", title,false) do |pc|
        pc.is_3d = is_3d
        sections.each_with_index do |section_data, i|
          section_label = section_data.first
          data = section_data.last
          pc.data( "#{section_label} #{'%.1f' % (data.to_f/total*100)}%", (data.to_f/total*100), options[:colors][i] ) if data > 0
        end
        pc.show_legend = options[:show_legend] == true ? true : false

        if options[:lighten_background] > 0
          pc.fill(:background, :gradient, :angle => options[:backgroud_shading_angle], :color => [[bgcolor,1],[RGBColor.new(bgcolor).lighten(options[:lighten_background]).to_hex,0]])
        else
          pc.fill(:background, :solid, {:color => bgcolor})
        end

        # Pie Chart with no labels
        pc.show_labels = options[:show_labels]
        chart_url = pc.to_url :chma=>"#{x_margin_size},#{x_margin_size},#{y_margin_size},#{y_margin_size}|10,10" 
      end
      GoogleChartsHelper.create_img_tag( chart_url, options )
    end

end