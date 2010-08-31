require 'rgb_color'

module AmChartsHelper
  
  # cycle of mostly pleasant colors to use in the google charts
  def default_color_train
    %w{#5D1880 #905717 #3E841F #193FBE #9B3E15 #C22DDE #00FFFF #9200C6 #4466AA}
  end
  
  # cycle of shapes to use in the google charts
  def shape_train
    [:cross, :diamond, :circle, :square, :x]
  end
  
  
  private 
    def process_am_options options
      options[:width] ||= 360
      options[:height] ||= 240
      options[:background] ||= '#eeeeee'
      options[:colors] ||= default_color_train
      options[:lighten_background] ||= 0 #percent
      options[:axes_color] ||= '#AAAAAA'
      options[:indicator_color] ||= '#222222'
      options[:indicator_text_color] ||= '#FFFFFF'
      options[:title_color] ||= '#444444'
      options[:balloon_alpha] ||= 90
      options[:area_alpha] ||= 0
      options[:y_min] ||= 0
      options[:popout] = true if options[:popout] == nil
      options[:animate] ||= 0.3
      options
    end
  
  public
  
    # Generates an amCharts pie chart for the supplied sections.  This method provides further abstraction on top of
    # the ambling gem by reducing the number of options and simplifying layout.
    #
    # +sections+ - An array of [name, value, url] tuples for each section of the pie.  url is optional
    # +options+ are optional as follows:
    # :width => chart width, default is 360
    # :height => chart height, default is 240
    # :title => chart title, default is Topic name and :group_by column name
    # :colors => an optional array of colors to be used for the slices.
    # :show_legend => true or false ( default == true )
    # :popout => enable popout animation : true or false ( default == true )
    # :animate => animation time (s) for colliding pie pieces on chart open. 0 is no animation.  0.3 is the default.
    #
    # Example (within a view):
    # <% sections = [['cats', 10, "http://cats.com"], ['dogs', 12, "http://dogs.com"]] %>
    # <%= am_chart_composition( sections, {:width=>400, :height=>300, :title=>"Daily Activity" } ) %>
    #
    def am_chart_composition sections, options
      # puts "options: #{options.inspect}"
      options = process_am_options(options)
      width = options[:width]
      height = options[:height]
      bgcolor = options[:background]
      colors = options[:colors]

      title = options[:title] || "Composition Breakdown"    
      title_height = title.blank? ? 0 : 30

      options[:show_legend] = true unless options[:show_legend] != nil
      bottom_margin = 30 + ( options[:show_legend] ? 30 : 0 )
  
      legend_width = 100
      pie_padding = 20
      x_pie_radius = ((width-legend_width-pie_padding*2) / 2).to_i
      y_pie_radius = ((height-title_height-pie_padding*2) / 2).to_i
      pie_radius = x_pie_radius.min( y_pie_radius )
      # puts "pie_radius: #{pie_radius}"
      legend_height = 35
      plot_margin = 10

      chart = Ambling::Data::Pie.new

      sections.each_with_index do |name_value_url, i|
        section_label = name_value_url[0]
        value = name_value_url[1]
        url = name_value_url[2]
        if url && !options[:suppress_links]
          puts "url: #{url}"
          chart.slices << Ambling::Data::Slice.new(value, :title => section_label, :url => url)
        else
          chart.slices << Ambling::Data::Slice.new(value, :title => section_label)
        end
      end
  
      text_size = (pie_radius/5).to_i.max(8).min(14)
      # puts "text_size: #{text_size}"
  
      chart_settings = Ambling::Pie::Settings.new({
        :pie => {
          :x => ((width-legend_width)/2).to_i,
          :y => (title_height + (height-title_height)/2).to_i,
          :radius => pie_radius,
          :colors => colors.join(','),
          :outline_color => '#FFFFFF',
          :outline_alpha => 50,
          :gradient=>'radial',
          :gradient_ratio=>'0,-20',
          :hover_brightness=>5,
          :height=>5,
          :angle=>1,
          :link_target=>options[:link_target],
        },
        :animation => {
          :pull_out_on_click => options[:popout],
          :start_time=> options[:animate],
          :start_effect=>"regular",
        },
        :data_labels => {
          :show => cdata_section("<b>{value}</b>"), 
          :radius => -(pie_radius/3).to_i , 
          :hide_labels_percent=>5,
          :text_color => '#FFFFFF',
          :text_size => text_size
        },
        :legend => {
          :enabled => options[:show_legend], :x => width-legend_width, :y => title_height + 20, :width => legend_width, :text_color => '#000',
          :max_columns => 1, :spacing => 2, :text_size => 10,
          :key => {:size => 10},
          :align=>'center'
        },
        :labels => {
          :label => [
            {:x => 0, :y => 5, :text => cdata_section("<b>#{title}</b>"),
              :text_size => 14, :text_color => options[:title_color], :width=>width, :align=>'center'}
            ]
        },
        :decimals_separator=>'.',
        :thousands_separator=>',',
        :precision=>1,
        :background => { :color=>"#{RGBColor.new(bgcolor).to_hex!}, #{RGBColor.new(bgcolor).lighten(options[:lighten_background]).to_hex!}", :alpha=>100, :border_color=>bgcolor, :border_alpha=>100 },
      })

  
      ambling_chart( :pie,  
        :chart_data => chart.to_xml,
        :id => "graph_data#{chart_settings.object_id}", 
        :width => width, 
        :height => height,
        :swf_params =>{:wmode => "opaque"},
        :chart_settings => chart_settings.to_xml ) do
        content_tag('p', "To see this page properly, you need to upgrade your Flash Player")
      end  
    end
    
    # Generates an amCharts line chart
    #
    # +options+ are optional as follows:
    # :width => chart width, default is 360
    # :height => chart height, default is 240
    # :title => chart title, default is Topic name and :group_by column name
    # :series => an array names for the X-axis points
    # :lines => an array of [name, [values...], [urls...]] tuples for each line to be charted.  The name is used as the label
    #    for the line.  The values array is the data for the points.  The urls array is optional, but if specified
    #    will be used to provide active links for each data point.
    # :colors => an optional array of colors to be used for the lines.
    # :show_legend => true or false
    # :line_width => integer
    # :x_axis_show_every => an integer indicating that only every nth x-axis label should be shown
    # 
    # :series, and :lines are required, and should contain arrays of equal length corresponding to the number of data points.
    #
    # Example (within a view):
    #
    # <%= am_chart_trend( {:series=>["Mon", "Tue"], :lines=>[["New York", [89,88]], ["Austin", [97,99]]], :width=>400, :height=>300, :title=>"Temperature"} ) %>
    #
    def am_chart_trend( options )
      options = process_am_options(options)
      width = options[:width]
      height = options[:height]
      legend_width = width
      legend_height = 40
      plot_margin = 10
      line_width = options[:line_width] || 2

      title = options[:title] || ""
      top_margin = title.blank? ? 10 : 35

      options[:show_legend] = true unless options[:show_legend] != nil
      bottom_margin = 30 + ( options[:show_legend] ? 30 : 0 )

      chart = Ambling::Data::LineChart.new
      series = options[:series]
      show_every = options[:x_axis_show_every].to_i
      show_every = 1 if show_every < 1
      series.each_with_index do |x_axis_label,i|
        show = (i % show_every) == 0
        chart.series << Ambling::Data::Value.new(x_axis_label, :xid => i, :show=>show) 
      end
      
      max_value = 0
      graph_settings = []
      options[:lines].each_with_index do |tuple, i|
        line_label = tuple.shift
        values = tuple.shift
        urls = tuple.shift || []
        line_color = options[:colors][i%options[:colors].size]
        area_color = RGBColor.new(line_color).saturate(100).to_hex!
        balloon_color = RGBColor.new(line_color).darken(20).to_hex!
        line_graph = Ambling::Data::LineGraph.new([], :title => line_label, :color => line_color, :gid=>i)
        values.each_with_index do |data, j|
          line_graph << Ambling::Data::Value.new((data*10).round.to_f/10, :xid => j, :url=>urls[j])
          max_value = max_value.max(data)
        end
        chart.graphs << line_graph
        graph_settings << {:gid => i, :line_width => line_width, :balloon_text => "{value} {title} on {series}", :balloon_color=>balloon_color, :balloon_alpha=>options[:balloon_alpha], :fill_color=>area_color, :fill_alpha=>options[:area_alpha], :bullet=>"round", :bullet_color=>line_color, :bullet_size=>3, :bullet_alpha=>50, :vertical_lines=>false}
      end

      max_value = options[:y_max] || max_value
      # puts ""
      # puts "#{chart.to_xml}"
      # puts ""

      if options[:background] =~ /#?([0-9a-fA-F]{2}[0-9a-fA-F]{2}[0-9a-fA-F]{2})/
        background_options = { :color=>"#{RGBColor.new(options[:background]).to_hex!}, #{RGBColor.new(options[:background]).lighten(options[:lighten_background]).to_hex!}", :alpha=>100, :border_alpha=>0 }
      else
        background_options = { :file=>options[:background], :alpha=>0, :border_alpha=>0 }
      end

      plot_area_options = {
        :margins => {:left => 51, :top => top_margin, :right => 18, :bottom => bottom_margin}
      }
      plot_area_options.merge!(:color=>options[:plot_background], :alpha=>100) if options[:plot_background]
      plot_area_height = height - plot_area_options[:margins][:top] - plot_area_options[:margins][:bottom]

      total_y_values = max_value-options[:y_min]

      chart_settings = Ambling::Line::Settings.new( {
        :grid => {
          :x => {:enabled=>false, :alpha => 10, :approx_count=>series.length/7},
          :y_left => {:enabled=>true, :alpha => 10, :approx_count=>(plot_area_height/10).to_i}
        },
        :values => {
          :x => {:enabled => false, :frequency => 1, :rotate=>0, :text_size=>9},
          :y_left => { :min=>options[:y_min], :max=>max_value, :color=>options[:title_color], :integers_only=>true, :frequency => 1, :skip_first=>true  }
        },
        :link_target=>options[:link_target],
        :indicator => {
          :zoomable=>true,
          :color=>options[:indicator_color],
          :x_balloon_text_color=>options[:indicator_text_color],
        },
        :balloon => {
          :only_one=>true,
        },
        :axes => {
          :x => {:tick_length => 2, :width => 1, :color=>options[:axes_color]},
          :y_left => {:tick_length => 12, :width => 1, :color=>options[:axes_color], :alpha=>00}
        },
        :plot_area => plot_area_options,
        :legend => {
          :enabled => options[:show_legend], :x => 0, :y => height-legend_height, :width => legend_width, :text_color => '#444',
          :margins=>10, :align=>'center',
          :max_columns => 5, :spacing => 2, :text_size => 10,
          :key => {:size => 10}
        },
        :labels => {
          :label => [
            {:x => 0, :y => 5, :text => cdata_section("<b>#{title}</b>"),
              :text_size => 14, :text_color => options[:title_color], :width=>width, :align=>'center'}
            ]
        },
        :graphs => {
          :graph => graph_settings
        },
        :background => background_options,
        :decimals_separator=>'.',
        :thousands_separator=>',',
        :start_on_axis=>true,
        :text_size=>10
      } )

      # puts ""
      # puts "#{chart_settings.to_xml}"
      # puts ""

      ambling_chart( :line,  
        :chart_data => chart.to_xml,
        :id => "graph_data#{chart_settings.object_id}",
        :class =>'am_chart',
        :width => width, 
        :height => height,
        :swf_params =>{:wmode => "opaque"},
        :chart_settings => chart_settings.to_xml ) do
        content_tag('p', "To see this page properly, you need to upgrade your Flash Player")
      end

    end
    
    # Generates an amCharts bar chart 
    #
    # +options+ are optional as follows:
    # :width => chart width, default is 360
    # :height => chart height, default is 240
    # :title => chart title, default is Topic name and :group_by column name
    # :series => an array names for the X-axis points
    # :columns => an array of [name, [values...], [urls...]] tuples for each column to be charted.  The name is used as the label
    #    for the column.  The values array is the data for the points.  The urls array is optional, but if specified
    #    will be used to provide active links for each data point.
    # :colors => an optional array of colors to be used for the columns.
    # :show_legend => true or false
    # :column_width => integer percentage (100 makes columns adjacent, 50 makes them with half as wide)
    # :x_axis_show_every => an integer indicating that only every nth x-axis label should be shown
    # 
    # :series, and :columns are required, and should contain arrays of equal length corresponding to the number of data points.
    #
    # Example (within a view):
    #
    # <%= am_chart_column( {:series=>["Mon", "Tue"], :columns=>[["New York", [89,88]], ["Austin", [97,99]]], :width=>400, :height=>300, :title=>"Temperature"} ) %>
    #
    def am_chart_column( options )
      options = process_am_options(options)
      width = options[:width]
      height = options[:height]
      legend_width = width
      legend_height = 40
      if (options[:auto_expand_legend] || true) && options[:show_legend]
        expansion_height = 15 * ((options[:columns].size / 4).to_i)
        legend_height += expansion_height
        height += expansion_height + 40
      end
      plot_margin = 10
      options[:column_width] ||= 90

      title = options[:title] || ""
      top_margin = title.blank? ? 10 : 35

      options[:show_legend] = true unless options[:show_legend] != nil
      bottom_margin = 40 + ( options[:show_legend] ? legend_height : 0 )

      chart = Ambling::Data::ColumnChart.new
      series = options[:series]
      show_every = options[:x_axis_show_every].to_i
      show_every = 1 if show_every < 1
      series.each_with_index do |x_axis_label,i|
        show = (i % show_every) == 0
        chart.series << Ambling::Data::Value.new(x_axis_label, :xid => i, :show=>true) 
      end
      
      max_value = 0
      graph_settings = []
      options[:columns].each_with_index do |tuple, i|
        column_label = tuple.shift
        values = tuple.shift
        urls = tuple.shift || []
        column_color = options[:colors][i%options[:colors].size]
        area_color = RGBColor.new(column_color).saturate(100).to_hex!
        balloon_color = RGBColor.new(column_color).darken(20).to_hex!
        column_graph = Ambling::Data::ColumnGraph.new([], :title => column_label, :color => column_color, :gid=>i)
        values.each_with_index do |data, j|
          column_graph << Ambling::Data::Value.new((data*10).round.to_f/10, :xid => j, :url=>urls[j] ? urls[j].gsub("&", "%26") : nil)
          max_value = max_value.max(data)
        end
        chart.graphs << column_graph
        graph_settings << {:gid => i, :balloon_text => "{value} {title} on {series}", :balloon_color=>balloon_color, :balloon_alpha=>options[:balloon_alpha], :fill_alpha=>options[:area_alpha]}
      end

      max_value = options[:y_max] || max_value
      # puts ""
      # puts "#{chart.to_xml}"
      # puts ""

      if options[:background] =~ /#?([0-9a-fA-F]{2}[0-9a-fA-F]{2}[0-9a-fA-F]{2})/
        background_options = { :color=>"#{RGBColor.new(options[:background]).to_hex!}, #{RGBColor.new(options[:background]).lighten(options[:lighten_background]).to_hex!}", :alpha=>100, :border_alpha=>0 }
      else
        background_options = { :file=>options[:background], :alpha=>0, :border_alpha=>0 }
      end

      plot_area_options = {
        :margins => {:left => 51, :top => top_margin, :right => 18, :bottom => bottom_margin}
      }
      plot_area_options.merge!(:color=>options[:plot_background], :alpha=>100) if options[:plot_background]
      plot_area_height = height - plot_area_options[:margins][:top] - plot_area_options[:margins][:bottom]

      total_y_values = max_value-options[:y_min]

      chart_settings = Ambling::Column::Settings.new( {
        :type => :column,
        :depth => options[:depth] || 0,
        :angle => options[:angle] || 30,
        :column => {
          :type  => options[:column_type],
          :width => options[:column_width],
          :grow_time => 0,
          :grow_effect => :strong,
          :link_target=>options[:link_target],
        },
        :grid => {
          :category => {:alpha => 10},
          :value => {:alpha => 10}
        },
        :values => {
          :category => {:enabled => true, :frequency => 1, :rotate=>55, :text_size=>9},
          :value => { :min=>options[:y_min], :max=>max_value, :color=>options[:title_color], :integers_only=>true, :frequency => 1, :skip_first=>true  }
        },
        # :indicator => {
        #   :zoomable=>true,
        #   :color=>options[:indicator_color],
        #   :x_balloon_text_color=>options[:indicator_text_color],
        # },
        :balloon => {
          # :only_one=>true,
        },
        :axes => {
          :category => {:tick_length => 2, :width => 1, :color=>options[:axes_color]},
          :value => {:tick_length => 12, :width => 1, :color=>options[:axes_color], :alpha=>00}
        },
        :plot_area => plot_area_options,
        :legend => {
          :enabled => options[:show_legend], :x => 0, :y => height-legend_height-plot_margin, :width => legend_width, :text_color => '#444',
          :margins=>10, :align=>'center',
          :max_columns => 5, :spacing => 2, :text_size => 10,
          :key => {:size => 10}
        },
        :labels => {
          :label => [
            {:x => 0, :y => 5, :text => cdata_section("<b>#{title}</b>"),
              :text_size => 14, :text_color => options[:title_color], :width=>width, :align=>'center'}
            ]
        },
        :graphs => {
          :graph => graph_settings
        },
        :background => background_options,
        :decimals_separator=>'.',
        :thousands_separator=>',',
        # :start_on_axis=>true,
        :text_size=>10
      } )

      # puts ""
      # puts "#{chart_settings.to_xml}"
      # puts ""

      ambling_chart( :column,  
        :chart_data => chart.to_xml,
        :id => "graph_data#{chart_settings.object_id}",
        :class =>'am_chart',
        :width => width, 
        :height => height,
        :swf_params =>{:wmode => "opaque"},
        :chart_settings => chart_settings.to_xml ) do
        content_tag('p', "To see this page properly, you need to upgrade your Flash Player")
      end

    end
end