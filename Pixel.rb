class Pixel
	def initialize rgb
		if rgb < 0 || rgb > 0xffffff then
			raise 'Pixel.new requires integer of 0xrrggbb'
		end

		@rgb = rgb
	end
	
	def red
		(@rgb & 0xff0000) >> 16
	end

	def green
		(@rgb & 0x00ff00) >> 8
	end

	def blue
		@rgb & 0x0000ff
	end

=begin
	def red= r
		r = r.to_i
		checkComponentRange r
		
	end
private
	def checkComponentRange comp
		if comp < 0 || comp > 0xff then
			raise 'RGB component must be between 0 and 255'
		end
	end
=end

end
