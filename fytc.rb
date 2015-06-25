require 'rubygems'
require 'crack'
require 'rest-client'
require 'nokogiri'
require 'csv'

puts 'Enter a zipcode:'
zipcode = gets.chomp
order = ''
until ['p','l'].include?(order)
  puts 'How do you want to sort the data? By phone number (p), or last name (l)?'
  order = gets.chomp
end

url='http://search.irs.gov/search?q='+zipcode+'&site=efile&client=efile_frontend&output=xml_no_dtd&proxystylesheet=efile_frontend&filter=0&getfields=*&partialfields=buszip%3A'+zipcode+'%7Czip_w%3A'+zipcode+'&num=1000'

page = Nokogiri::HTML(RestClient.get(url))

result = []

page.css('table').each do |table|
  entry = {}
  table.css('tr').each do |row|
    entry[row.css('td')[0].text] = row.css('td')[1].text
  end
  result << entry
end

def make_number(string)
  first = string.split('/')
  second = first[1].split('-')
  num = first[0] + second[0] + second[1]
  num.to_i
end

def split_in_arr(string)
  arr = []
  i = 0
  string.each_char do |c|
    if c =~ /\W/ && c != "-"
      p c
      i += 1
    elsif arr[i]
      arr[i] += c
    else
      arr[i] = c
    end
  end
  arr
end

if order == 'l'
  result.sort_by!{|hsh| split_in_arr(hsh['Point of Contact: '])[-1].downcase}
else
  result.sort_by!{|hsh| make_number(hsh['Telephone: '])}
end

CSV.open("output.csv", "wb") do |csv|
  result.each do |el|
    res = []
    el.each do |key, val|
      res << "#{key} #{val}"
    end
    csv << res
  end
end

result.each do |el|
  el.each do |key, val|
    puts "#{key} #{val}\n"
  end
  puts "\n"
end