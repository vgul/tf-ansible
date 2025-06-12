#!/usr/bin/env ruby

require 'aws-sdk-s3'
require 'time'
require 'open3'
require 'json'

def terraform_output_value(key, tf_dir = "./tf")
  cmd = "terraform -chdir=#{tf_dir} output -json"
  stdout, stderr, status = Open3.capture3(cmd)

  if status.success?
    data = JSON.parse(stdout)
    return data.dig(key, "value")
  else
    warn "Terraform error: #{stderr}"
    return nil
  end
end


# main
bucket_name = terraform_output_value("ruby_scaffold")

puts "Bucket: #{bucket_name}"

s3 = Aws::S3::Client.new()

days_threshold = 30
keep_latest = 10
keepers = [] # array for most new files (number: keep latest)
cutoff_time = Time.now - (days_threshold * 24 * 60 * 60)
continuation_token = nil

# first pass; collect only 'keep_latest' fils
loop do
  response = s3.list_objects_v2(
    bucket: bucket_name,
    continuation_token: continuation_token
  )

  response.contents.each do |object|
    ### Mock part
    def object.last_modified
      datetime_str = self.key.match(/^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2})/)&.captures&.first
      if datetime_str
        Time.parse(datetime_str.gsub("_", " ")) #.utc
      else
        (defined?(super) ? super() : Time.now) #.utc
      end
    end
    ### END Mock
    current_entry = { key: object.key, last_modified: object.last_modified }
    #puts(current_entry)

    if keepers.size < keep_latest
      keepers << current_entry
      keepers.sort_by! { |e| e[:last_modified] }
    elsif object.last_modified > keepers.first[:last_modified]
      keepers.shift
      keepers << current_entry
      keepers.sort_by! { |e| e[:last_modified] }
    end
  end

  continuation_token = response.next_continuation_token
  break unless continuation_token
end


# second pass; old files deletion
continuation_token = nil
loop do
  response = s3.list_objects_v2(
    bucket: bucket_name,
    continuation_token: continuation_token
  )

  response.contents.each do |object|
    if keepers.any? { |e| e[:key] == object.key }  # skip keept
      last_modified = keepers.find { |e| e[:key] == object.key }[:last_modified]
      msg = "Keep (top %2d)" % [ keep_latest ]

    else

      ### Mock part
      def object.last_modified
        datetime_str = self.key.match(/^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2})/)&.captures&.first
        if datetime_str
          Time.parse(datetime_str.gsub("_", " ")) #.utc
        else
          (defined?(super) ? super() : Time.now) #.utc
        end
      end
      ### END Mock


      if object.last_modified < cutoff_time
        msg = "Delete       "
        s3.delete_object(bucket: bucket_name, key: object.key)
      else
        msg = "Keep         "
      end
      last_modified = object.last_modified

    end
    puts "#{msg}: #{last_modified}\t\t#{object.key}"
  end

  continuation_token = response.next_continuation_token
  break unless continuation_token
end

