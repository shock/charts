class ChartsController < ApplicationController
  
  def set_flash_compatibility boolean
    @flash_compatible = boolean
  end
  
  def is_flash_compatible?
    @flash_compatible
  end
  
  def test
  end
end