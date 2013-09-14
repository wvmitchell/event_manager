require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode zipcode
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_num(phone_num)
  phone_num = phone_num.tr('^0-9', '')
  if phone_num.length < 10 || phone_num.length > 11
    phone_num = nil
  elsif phone_num.length == 11 && phone_num[0] == '1'
    phone_num = phone_num[1..-1]
  elsif phone_num.length == 11
    phone_num = nil
  else
    phone_num
  end 
end

def clean_date(date)
  DateTime.strptime(date, '%m/%e/%y %H:%M')
end

def add_hour(dateObj, hash)
  hour = dateObj.hour.to_s
  if hash.has_key? hour
    hash[hour] += 1
  else
    hash[hour] = 1
  end
end

def add_day(dateObj, hash)
  day = dateObj.wday.to_s
  if hash.has_key? day
    hash[day] += 1
  else
    hash[day] = 1
  end
end

puts "Event Manager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
hour_of_day_tabulation = {}
day_of_week_tabulation = {}


contents.each do |row|
  id = row[0]
  date = clean_date row[:regdate]
  add_hour date, hour_of_day_tabulation
  add_day date, day_of_week_tabulation
  name = row[:first_name]
  phone_num = clean_phone_num row[:homephone]
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  #save_thank_you_letters id, form_letter
end

puts hour_of_day_tabulation
puts day_of_week_tabulation
