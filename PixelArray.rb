#!/usr/bin/ruby

require 'RMagick'
require File.join(__dir__, 'common.rb')

class PixelArray
	def initialize path, size = nil, data = nil
		@path = path
		if path != ''
			img = Magick::ImageList.new path
			@size = Vector2d.new(img.columns, img.rows)
			@data = img.export_pixels_to_str(0, 0, @size.x, @size.y, 'RGB')
		else
			raise 'specify valid size and data' if !size || !data
			@size, @data = size, data
		end

		raise 'image size and actual data length inconsistent' \
				if 3 * @size.x * @size.y != @data.size
	end

	def [](x, y)
		# TODO メッセージに値を入れて親切に
		raise 'pixel index out of bound' \
				if x < 0 || @size.x <= x|| y < 0 || @size.y <= y
		
		pixelStart = pixelOffsetInByte x, y
		r, g, b = [0, 1, 2].map {|offset| @data[pixelStart + offset].ord }

		Rgb.new(r, g, b)
	end

	def subarray(arg0, arg1, arg2 = nil, arg3 = nil)
		leftTop = size = nil
		if arg2 == nil && arg3 == nil
			leftTop, size = arg0, arg1
		else
			raise 'all 4 args must not be nil' \
					if [arg0, arg1, arg2, arg3].include? nil
			leftTop = Vector2d.new(arg0, arg1)
			size = Vector2d.new(arg2, arg3)
		end

		# TODO 範囲チェック
		# TODO leftTop と size の位置関係チェック（幅・高さが正）
		
		data = ''
		0.upto(size.y - 1) do |i|
			y = leftTop.y + i
			rowStart = pixelOffsetInByte(leftTop.x, y)
			rowEnd = pixelOffsetInByte(leftTop.x + size.x, y)
			data << @data[rowStart ... rowEnd]
		end
		
		PixelArray.new('', size, data)
	end
	
	# 別の PixelArray を leftTop 位置に上書きコピーする 
	def overwrite leftTop, array
		(0 ... array.size.y).each do |y|
			scanline = array.data[array.pixelOffsetInByte(0, y) \
					... array.pixelOffsetInByte(0, y + 1)]
			destStart = self.pixelOffsetInByte(leftTop.x, leftTop.y + y)
			data[destStart ... (destStart + scanline.size)] = scanline
		end
	end
	
	def saveAsImage savePath
		img = Magick::Image.new(@size.x, @size.y)
		img.import_pixels(0, 0, @size.x, @size.y, 'RGB', @data)
		img.write(savePath)
	end

	attr_reader :size, :data

protected
	def pixelOffsetInByte x, y
		3 * (y * @size.x + x)
	end
end


class PixelSubarray
	# TODO
end

