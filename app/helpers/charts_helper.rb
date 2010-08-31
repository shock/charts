require 'rgb_color'

module ChartsHelper
  
  # include the AmChartsHelper and GoogleChartsHelper modules too if they haven't been included already
  def included(klass)
    klass.send( :include, AmChartsHelper ) unless klass.included_modules.include?( AmChartsHelper )
    klass.send( :include, GoogleChartsHelper ) unless klass.included_modules.include?( GoogleChartsHelper )
  end
  
  def is_flash_compatible?
    controller.is_flash_compatible?
  end
  
  def chart_composition sections, options
    unless is_flash_compatible?
      google_chart_composition( sections, options )
    else
      am_chart_composition( sections, options )
    end
  end
  
end
