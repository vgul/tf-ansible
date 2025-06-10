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
cutoff_time = Time.now - (days_threshold * 24 * 60 * 60)
continuation_token = nil

begin
  loop do
    response = s3.list_objects_v2(
      bucket: bucket_name,
      continuation_token: continuation_token,
      #max_keys: 100
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


      if object.last_modified < cutoff_time
        msg = "Delete"
        s3.delete_object(bucket: bucket_name, key: object.key)
      else
        msg = "Remain"
      end
      puts "#{msg}: #{object.last_modified}\t\t#{object.key}"

    end

    break unless response.is_truncated
    continuation_token = response.next_continuation_token
  end
rescue Aws::S3::Errors::ServiceError => e
  puts "Error: #{e.message}"
end



