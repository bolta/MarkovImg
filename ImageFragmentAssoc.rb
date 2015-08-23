require File.join(__dir__, 'common.rb')
require File.join(__dir__, 'PixelArray.rb')

class ImageFragmentAssoc
	OutsideOfImage = 'outside of image'

	def initialize blockSize
		# TODO このクラスを直接インスタンス化することを禁止する

		@assoc = {}
		@blockSize = blockSize
	end

	def addImage path
		blocks = makeBlocks(path)
		
		(0 ... blocks.size).each do |y|
			row = blocks[y]
			(0 ... row.size).each do |x|
				key = calcKey(blocks, row.size, blocks.size, x, y)
				block = row[x]
				addAssoc(key, block)
			end
		end
	end

	def execute sizeInBlocks, outPath
		blocks = []
		(0 ... sizeInBlocks.y).each do |y|
			row = []
			blocks << row
			(0 ... sizeInBlocks.x).each do |x|			
#print "(#{x}, #{y})"
=begin
				blocks の左・上の内容から、キーを求める
				求めたキーに「近い」キーで連想配列の値（ブロック）を求める
				求めたブロックを現在位置にはめる
=end
				key = calcKey(blocks, x, y, x, y, true)
#puts "key = #{key}"
				block = blockFor key
#puts "block = #{block}"
				row << block
			end
		end

		imageSize = Vector2d.new(sizeInBlocks.x * @blockSize.x,
				sizeInBlocks.y * @blockSize.y)
		# TODO 単色の初期化はコンストラクタ側でやれるように…
		image = PixelArray.new('', imageSize, "\0\0\0" * imageSize.area)
		blocks.each_with_index do |row, r|
			row.each_with_index do |block, c|
				leftTop = Vector2d.new(c * @blockSize.x, r * @blockSize.y)
				image.overwrite(leftTop, block)
			end
		end
		
		image.saveAsImage(outPath)
	end

protected
	def calcKey(blocks, columnCount, rowCount, x, y, debug = false)
		raise 'this method must be implemented in a subclass'
	end
	
	def blockFor key
		raise 'this method must be implemented in a subclass'
	end

private
	def makeBlocks(path)
		image = PixelArray.new(path)
		blocks = []
		
		0.step(image.size.y - 1, @blockSize.y) do |y|
			break if image.size.y - y < @blockSize.y
			
			row = []
			blocks << row
			0.step(image.size.x - 1, @blockSize.x) do |x|
				break if image.size.x - x < @blockSize.x
				row << image.subarray(Vector2d.new(x, y), @blockSize)
			end
		end

		blocks
	end

	def addAssoc(key, value)
		@assoc[key] ||= []
		@assoc[key] << value
	end
end

# 左・上隣のブロックの色の平均をキーとする断片連想
class LeftUpperAverageAssoc < ImageFragmentAssoc
	def initialize blockSize, bucketRes
		super blockSize
		@bucketRes = bucketRes
	end

private
	AverageFull = 0
	AverageRightmost = 1
	AverageBottom = 2

protected
	def calcKey(blocks, columnCount, rowCount, x, y, debug = false)
		begin
	#		if debug
	#			p blocks.map{|row| row.map{|block|"*"}}
	#		end
	##puts "************" +  blocks.inspect if x != 0
			left = x == 0 ? OutsideOfImage \
					: average(blocks[y][x - 1], AverageRightmost)
			upper = y == 0 ? OutsideOfImage \
					: average(blocks[y - 1][x], AverageBottom)
		rescue => e
#		p blocks
		
			raise e
		end

		toBucket(
			if left == OutsideOfImage
				if upper == OutsideOfImage
					OutsideOfImage
				else
					toBucket upper
				end
			else
				if upper == OutsideOfImage
					toBucket left
				else
					toBucket((left + upper) / 2)
				end
			end
		)
	end

	def toBucket rgb
		if rgb == OutsideOfImage
			OutsideOfImage
		else
			Rgb.new(* rgb.map {|comp| comp.to_i / @bucketRes })
		end
	end

	def blockFor key
		# TODO 本当は key に「一番近い」キーで値を引く
#		size = Vector2d.new(@blockSize.x, @blockSize.y)
#		PixelArray.new('', size, '@zz' * size.area)
#		@assoc[OutsideOfImage][0] # 仮

		exactCands = @assoc[key]
		if exactCands != nil
			if ! exactCands.is_a? Array || exactCands.empty?
				assert false
				return notAvailable
			end
			
			return exactCands[rand exactCands.size]
		end
		
		return notAvailable
	end

private
	def notAvailable
		size = Vector2d.new(@blockSize.x, @blockSize.y)
print "*"
#		PixelArray.new('', size,
#				 ([255, 0, 0].map {|comp| comp.chr}.join) * size.area)
		@assoc[OutsideOfImage][0]
	end

	def average(image, mode = AverageFull)
# puts "image = #{image.inspect}"
		return OutsideOfImage if image == OutsideOfImage
		
		sum = Rgb.new(0, 0, 0)
		top = mode == AverageBottom ? image.size.y - 1 : 0
		left = mode == AverageRightmost ? image.size.x - 1 : 0
		(top ... image.size.y).each do |y|
			(left ... image.size.x).each do |x|
				sum += image[x, y]
			end
		end
		
		width = image.size.x - left
		height = image.size.y - top
		comps = sum.map {|comp| (comp.to_f / width / height).round }
		Rgb.new(*comps)
	end
end



