
require 'RMagick'
require 'hashr'

include Magick

class EmptyImage < ImageList
  def initialize
    super('tmp/empty.png')
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
    system "convert -size #{width}x#{height} xc:none tmp/empty.png"
    image = EmptyImage.new #.resize_to_fill(width, height)
    Tileset.new(image, tile_width, tile_height)
  end

  def self.merge(tilesets, settings)
    tiles = tilesets.map(&:tiles).reduce(&:+)
    height = settings['max_y'] #tiles.size*settings['tile_height']
    width = settings['max_x'] #tiles.map(&:size).max*settings['tile_width']

    result = Tileset.empty(
      width,
      height,
      settings['tile_width'],
      settings['tile_height'],
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
    puts 'Creating output...'
    offset_y = 0
    shift_x = 0
    length = tiles.count
    tiles.each_with_index do |row, i|
      offset_x = shift_x
      row.each do |image|
        @image.composite!(
          image,
          offset_x + (@tile_width - image.columns)/2,
          offset_y + (image.rows >= @tile_width ? @tile_height - image.rows : @tile_width - image.rows/2),
          #offset_y + @tile_height - image.rows,
          #offset_y,
          OverlayCompositeOp
        )
        offset_x += @tile_width
      end
      offset_y += @tile_height
      if offset_y + @tile_height > height
        offset_y = 0
        shift_x += 512
      end
      print "  #{(100.to_f/length*(i + 1)).round}%       \r"
    end
    puts
  end

  def display
    @image.display
  end

  def write(filename)
    @image.write(filename)
  end

  def create_desc_image
    puts 'Creating description...'
    @desc_image = @image.dup
    id = 0
    max_y, max_x = height - @tile_height, width - @tile_width
    (0..max_y).step(@tile_height).map do |y|
      print "  #{(100.to_f/max_y*y).round}%       \r"
      (0..max_x).step(@tile_width).map do |x|
        id += 1
        Draw.new.annotate(@desc_image, 32, 48, x, y, id.to_s) do
          self.font_family = 'Helvetica'
          self.fill = 'white'
          self.pointsize = 12
          self.undercolor = 'black'
          self.gravity = NorthGravity
        end
      end
    end
    puts ''
  end

  def write_desc(filename)
    create_desc_image
    @desc_image.flatten_images.write(filename)
  end
end

settings = {
  'input' => [
    {
      'filename'  => 'input/tileb.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/blocks1.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/blocks2.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/blocks3.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/blocks4.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/floors1.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/vx_chara01_a.png',
      'tile_height' => 48,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/bomb.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/38189015.png',
      'tile_height' => 32,
      'tile_width' => 32,
    },
    {
      'filename'  => 'input/bigset.png',
      'tile_height' => 24,
      'tile_width' => 24,
    },
  ],
  'output' => {
    'filename'  => 'output.png',
    'tile_height' => 48,
    'tile_width' => 32,
    'max_x' => 2048,
    'max_y' => 2016,
  }
}

input = settings['input'].map do |image_hash|
  Tileset.create(image_hash)
end 

tileset = Tileset.merge(input, settings['output'])
#tileset.display
tileset.write(settings['output']['filename'])
tileset.write_desc('desc.png')

