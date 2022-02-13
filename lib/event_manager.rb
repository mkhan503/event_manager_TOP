require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def legislators_names(zipcode)

  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators.officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end

end

def save_thanks_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.gsub(/\D/,'')
   
  phone_number.slice!(0) if (phone_number.length == 11 && phone_number[0] == '1')
   
  phone_number = 'Incorrect number' if phone_number.length != 10

  phone_number

end

def find_peak(hash)
  peak = []
  hash.each { |key, value| peak << key if value == hash.values.max }
  peak

=begin max = 0 
  peak = []

  hash.each_value{ |value| max = value if value > max }

  hash.each_pair{ |key, value| peak << key if max == value }

  peak
=end

end

def num_to_day(peak_days_num)
  peak_days = []

  peak_days_num.each do |day|
    peak_days << Date::DAYNAMES[day]
  end

  peak_days

end

template_letter = File.read('form_letter.erb')

erb_template = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
   headers: true,
  header_converters: :symbol
)

registration_hour_count = {}
registration_day_count = {}

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_names(zipcode)

  form_letter = erb_template.result(binding)

  save_thanks_letter(id, form_letter)

  phone_number = clean_phone_number(row[:homephone])

  registration_time = Time.strptime(row[:regdate], "%m/%d/%Y %H:%M").strftime("%H:%M").to_i
  
  registration_hour_count[registration_time].nil? ?  registration_hour_count[registration_time] = 1 : registration_hour_count[registration_time] += 1


  register_day = Date.strptime(row[:regdate], "%m/%d/%Y").wday

  registration_day_count[register_day].nil? ?  registration_day_count[register_day] = 1 : registration_day_count[register_day] += 1

end

peak_hours = find_peak(registration_hour_count).join(',')
puts "Peak hours: #{peak_hours}"

#peak_days_num = find_peak(registration_day_count)

peak_days = num_to_day(find_peak(registration_day_count)).join(',')
puts "Peak day(s): #{peak_days} "







