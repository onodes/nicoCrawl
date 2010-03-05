require 'rubygems'
require 'cgi'
require 'mechanize'
require 'pp'
require 'thread'
require 'pit'
class NicoCrawl
  def initialize(id,pass)
    @@agent ||= Mechanize.new
    @@id = id
    @@pass = pass
    @agent = @@agent
    @agent.user_agent_alias = 'Windows IE 7'
  end

  def login
    page = @@agent.get("https://secure.nicovideo.jp/secure/login_form")
    login_form = page.forms.first
    login_form.fields[1].value = "onodes@gmail.com"
    login_form.fields[2].value = "vipofvip"
    redirect_page = @@agent.submit(login_form)
    # @agent.cookies
    puts "LOGIN OK"
    self
  end



  def search(word)
    @links = []
    puts "search"
    page = @agent.get("http://www.nicovideo.jp/tag/" + word)
    link_data = page/"p.font12/a.watch"
    link_data.each{|link|
      @links << {"title" => link.inner_text.to_s , "watch_url" => "http://nicovideo.jp/" + link["href"],"sm_url" => link["href"].to_s.sub("watch/","")}
    }
    self
  end



  def get_url(sm,agent)
    #@linksの部分が１つにしか対応していない
    api_page = agent.get("http://www.nicovideo.jp/api/getflv?v=" + sm)
    #p api_page
    urls = CGI.unescape(api_page.body)
    #p urls
    flv_url = urls.match(/url=/).post_match.match(/&link=/).pre_match
    return flv_url
  end

  def download_func(i,agent)
    #t1 = Thread.new do
    #  puts "Thread : #{i} - t1"
    #  agent.get(@links[i]["watch_url"])
    #end

    t1 = Thread.new do 
      agent.get(@links[i]["watch_url"])
      puts "Thread : #{i} - t1"
      sleep 3
      puts "Download now #{@links[i]["title"]}"
      movie_file = get_url(@links[i]["sm_url"],agent)
      file = agent.get(movie_file)
      type = movie_file.include?("v=") ? ".flv":".mp4"  
      file.save_as("./DL/" + @links[i]["title"] + type)
      puts "DL #{@links[i]["title"]} done"

    end

    t1.join
    self
  end

  def download 
    thread_array = []
    thread_table = Queue.new

    @links.size.times{|num|
      thread_table.push(num)
    }


    3.times{
      puts "make thread"
      thread_array << Thread.new{
      while(!thread_table.empty?)
        num = thread_table.pop
        agent = @agent 
        download_func(num,agent)
      end
    }
    sleep 5
    }
    sleep 5
    puts "try thread join" 
    thread_array.each{|thread|
      thread.join
      puts "joined thread"
      sleep 5
    }

  end

end


puts "Start!"
t = []
print "How many word do you find? = "

num = gets.chomp.to_i
num.times do |i|
  print "No.#{i} serch word = "
  word = gets.chomp
  t << Thread.new{NicoCrawl.new(Pit.get("nicovideo")["id"],Pit.get("nicovideo")["pass"]).login.search(word).download}
  sleep 3
end

t.each{|data| 
  data.join
  #sleep 10 
}
