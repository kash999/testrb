

require 'open-uri'
require 'nokogiri'


uri = '<>'
@doc = Nokogiri::HTML(open(uri).read)



img =  @doc.css('img.vert')

img.each { |i|  
	n = i['src'].split('/')[-1].sub('160','1000')
    puts n
    r = Random::rand(1..9)
    src = i['src'].sub('ept', "ep#{r}").sub('160', '1000')
    open("img/#{n}", 'wb') do |f|
    	f << open(src).read
    end 

}
