#! /usr/bin/ruby

if ARGV.length < 2
	puts "Need more args!"
	puts "Specify working Dir and reg ex's to use for renaming"
	puts "like this: 'ruby renamer.rb /path/to regex1 regex2'"
	exit!
end

#dir = Dir.new("/home/rtw/cd/")
dir = Dir.new(ARGV[0])
Dir.chdir(ARGV[0])

files = Array.new
oldN = Array.new
newN = Array.new
total = 0

for i in 1..(ARGV.length - 1)
	files[i-1] = Array.new
	dir.each do |item|
		files[i-1].push(item) if item =~ /#{ARGV[i]}/ && item =~ /mp3|wav/
	end
end


#get total
for i in 0..files.length
	if(files[i] != nil)
		total += files[i].length
		files[i].sort!
		files[i].each do |j|
	###		puts "after: #{j}"
		end
		puts
	end
end
####


#get counter limit
counter = 100 if(total <= 100)
counter = 1000 if(total > 100 && total <= 1000)
counter = 10000 if(total > 1000 && total <= 10000)
if(total > 10000)
	puts "too many files!"
	exit!
end
####

#go through each array grabbing the first element, skipping ones that we have
for z in 0..total
	for i in 0..files.length #get each array
		if(files[i] != nil && files[i].length > 0) #as long as it is valid
			str = counter
			counter += 1
			str1 = files[i].shift
			while(files[i].length >= 0) #stay in here until we get unique item
				oldN.each do |j|
					if(str1 == j)
						str1 = files[i].shift
						next
					end
				end
				break
			end
			if(str1 != nil)
				str = str.to_s + "_" + str1.to_s
				newN.push(str)
				oldN.push(str1)
			else
				counter -= 1 #if nil, back up counter
			end
			
			
		else #if not entered, back up z
			z = z - 1
		end
		
	end
end


if(oldN.length != newN.length)
	puts "different size?"
	exit!
end

for i in 0..(oldN.length - 1)
	puts "Renamed: \"#{oldN[i]}\" to: \"#{newN[i]}\""
end


puts "Commit process? yes/No"
prompt = $stdin.gets
prompt.chomp

if(prompt =~ /yes/i)
	for i in 0..(oldN.length - 1)
		File.rename(oldN[i], newN[i])
	end
end
