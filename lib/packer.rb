
require 'RMagick'
require 'hashr'

include Magick

class EmptyImage < ImageList
  def initialize
    super('resources/nothing.png')
  end
end

class Tileset
  def self.create(params)
    Tileset.new(
      ImageList.new(params['filename']),
      params['tile_width'],
      params['tile_height'],
    )
  end

  def self.empty(width, height, tile_width, tile_height)
    image = EmptyImage.new.resize_to_fill(width, height)
    Tileset.new(image, tile_width, tile_height)
  end

  def self.merge(tilesets, settings)
    tiles = tilesets.map(&:tiles).reduce(&:+)
    height = tiles.size*settings['tile_height']
    width = tiles.map(&:size).max*settings['tile_width']

    result = Tileset.empty(
      width,
      height,
      settings['tile_width'],
      settings['tile_height']
    )
    result.tiles = tiles
    result
  end

  def initialize(image, tile_width, tile_height)
    @image = image

    @tile_width = tile_width
    @tile_height = tile_height
  end

  def width
    @image.columns
  end

  def height
    @image.rows
  end

  def tiles
    (0..(height - @tile_height)).step(@tile_height).map do |y|
      (0..(width - @tile_width)).step(@tile_width).map do |x|
        @image.crop(x, y, @tile_width, @tile_height)
      end
    end
  end

  def tiles=(tiles)
    offset_y = 0
    tiles.each do |row|
      offset_x = 0
      row.each do |image|
        @image.composite!(
          image,
          offset_x,
          offset_y + @tile_height - image.rows,
          #offset_y,
          OverlayCompositeOp
        )
        offset_x += @tile_width
      end
      offset_y += @tile_height
    end
    create_desc_image
  end

  def display
    @image.display
  end

  def write(filename)
    @image.write(filename)
  end

  def create_desc_image
    @desc_image = @image.dup
    id = 0
    (0..(height - @tile_height)).step(@tile_height).map do |y|
      (0..(width - @tile_width)).step(@tile_width).map do |x|
        id += 1
        Draw.new.annotate(@desc_image, 32, 48, x, y, id.to_s) do
          self.font_family = 'Helvetica'
          self.fill = 'white'
          self.pointsize = 12
          self.undercolor = 'black'
          self.gravity = CenterGravity
        end
      end
    end
  end

  def write_desc(filename)
    @desc_image.write(filename)
  end
end

settings = {
  'input' => [
    {
      'filename'  => 'tileb.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
    {
      'filename'  => 'blocks1.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'blocks2.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'blocks3.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'blocks4.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'floors1.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
    {
      'filename'  => 'vx_chara01_a.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'bomb.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
    {
      'filename'  => '38189015.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
  ],
  'output' => {
    'filename'  => 'output.png',
    'tile_height' => 48,
    'tile_width' => 32,
  }
}

input = settings['input'].map do |image_hash|
  Tileset.create(image_hash)
end 

tileset = Tileset.merge(input, settings['output'])
#tileset.display
tileset.write(settings['output']['filename'])
tileset.write_desc('desc.png')

