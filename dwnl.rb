#!/usr/bin/ruby

require 'fileutils'
require 'open-uri'

class Manga
  attr_reader :chap, :chap_img, :chap_src  #, :page
  attr_accessor :folder

  def initialize(url, folder="")
    @page = open(url).readlines
    @chap = Array.new
    @chap_img = Hash.new
    @folder = (folder == "") ? "./" + url.gsub(/http:\/\/.*mangas\//,"").gsub(/\//,"").gsub(/-/,"_") : folder
puts @folder
  end

  def get_chap
    @page.each do |l|
      if l.match(/^ *<a href=\"\/\/www.japscan.com\/lecture-en-ligne/)
        temp = l.gsub(/.*=\"/,"").gsub(/\".*/,"")
        @chap.push(temp)
      end
    end
    puts "\n\nFound " +  @chap.length.to_s + " (chapiters/volumes) to download\n\n\n"
  end

  def get_img_add
    @chap.each do |chapter|
      img_src = Array.new
      page = open("http:" + chapter).readlines
      page.each do |l|
        if l.match(/data-img.*<\/option>/)
          img_src.push(get_img_src(l.gsub(/.*value=\"/,"").gsub(/\".*/,"").chomp))
        end
      end

      if chapter.match(/.*\/volume.*[0-9\.]+\//)
        chap = chapter.gsub(/.*\/volume.*([0-9\.]+)\//,'\1')
      else
        chap = chapter.gsub(/.*\/([0-9\.]+)\//,'\1')
      end
      chap = (chap.match(/\./))? "%05.1f" % chap : "%03d" % chap
      @chap_img[chap] = img_src
    end
  end
  
  def create_folder
    if File.directory?(@folder)
      puts "Warning: #{@folder} directory already exists" unless File.directory?(@folder)
    end
    FileUtils.mkdir_p(@folder)
    puts "Downloading manga to folder" + @folder + "\n\n"
  end

  def download_chapter
    @chap_img.each do |chapter, urls|
      chap_path = @folder + "/" + chapter
      if File.directory?(chap_path)
        puts "Warning: Chapter @chapter already exist in " + @folder + " -> skipping"
      else
        FileUtils.mkdir_p(chap_path)
        puts "Chapter " + chapter
        i = 0
        print "-> downloading file "
        urls.each do |url|
          i+=1
          filename = chap_path + "/" + File.basename(url)
          print "\r"
          stream = " -> downloading file "+ i.to_s + "/" + urls.length.to_s
          print stream
          open(filename.chomp, 'w') do |file|
            file.write(open(url).read)
            file.close
          end
        end
      end
      puts "complete"
    end
  end

  def get_img_src(url)
    page = open("http://www.japscan.com" + url).readlines
    page.each do |l|
      if l.match(/<img/)
        return l.gsub(/.*src=\"/,"").gsub(/\".*/,"")
        break
      end
    end
  end
  
end

def get_manga_list
  list = Array.new  
  manga_page = open("http://www.japscan.com/mangas/").readlines
  manga_page.each do |l|
    next unless l.valid_encoding?
    if l.match(/^ *<div class=\"cell\"><a href=\"\/mangas\//)
      list.push(l.gsub(/.*=\"\/mangas\//,"").gsub(/\/\".*/,""))
    end
  end
  return list
end

def search_menu
  puts "Please enter search word (or regexp)"
  getted = gets.chomp
  puts "Search Results:"
  puts $manga_list.select { |x| x.match(/#{getted}/) }
  puts ""
  begin 
    puts "1 > Download manga"
    puts "2 > Search again"
    puts "3 > Main menu"
    getted = gets.chomp.to_i
  end while getted != 1 && getted != 2 && getted != 3
  puts ""
  case getted
  when 1
    dowload_menu
  when 2
    search_menu
  when 3
    main_menu
  end
end

def download_menu
  puts "Enter full manga name"
  manga_name = gets.chomp
  url = "http://www.japscan.com/mangas/" + manga_name + "/"
 
  mymanga = Manga.new(url)
  mymanga.get_chap
  
  puts "Please enter chapters to download (all/X/Y-Z)"
  flag = 0
  begin 
    getted = gets.chomp
    if getted == "all"
      flag = 1
    elsif getted.match(/[0-9]+\-[0-9]+/)
      flag = 2
    elsif getted.match(/[0-9]+/)
      flag = 3
    end
    puts flag
  end while flag == 0
end

def main_menu
  begin 
    puts "1 > List all mangas"
    puts "2 > Search Manga (regexp)"
    puts "3 > Download Manga"
    puts "4 > Exit"
    getted = gets.chomp.to_i
  end while getted != 1 && getted != 2 && getted != 3 && getted != 4
  case getted
  when 1
    puts $manga_list
    puts ""
    main_menu
  when 2
    search_menu
  when 3
    download_menu
  when 4
    exit
  end
end

$manga_list = get_manga_list
main_menu

