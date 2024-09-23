require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

template_letter = File.read('form_letter.erb')


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
    address: zip,
    levels: 'country',
    roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def save_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone)
  phone.to_s.gsub(/\D/, '')  # Removes non-digit characters
end


puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

erb_template = ERB.new template_letter

# Create a hash to count the frequency of each hour
hourly_registrations = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phone_number(row[:homephone])
  reg_date = row[:regdate].split(" ")
  time = reg_date[1]

  # Extract the hour from the time (assuming format is HH:MM or HH:MM:SS)
  hour = time.split(":")[0].to_i

  # Increment the counter for this hour
  hourly_registrations[hour] += 1

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_letter(id, form_letter)



  # if phone.nil?
  #   puts "No number"
  # elsif phone.length < 10
  #   puts "This is a bad number"
  # elsif phone.length == 10
  #   puts "This is a good number"
  # elsif phone.length == 11 && phone[0] == '1'
  #   puts phone[1..10]
  # elsif phone.length == 11 && phone[0] != '1'
  #   puts "This is a bad number too"
  # else
  #   puts "This is a bad number again"
  # end


end

# Find the hour with the most registrations
peak_hour = hourly_registrations.max_by { |hour, count| count }

puts "The peak registration hour is #{peak_hour[0]}:00 with #{peak_hour[1]} registrations."
