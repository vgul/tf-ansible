#!/usr/bin/env ruby

require 'aws-sdk-s3'
require 'time'

s3 = Aws::S3::Client.new(
  unsigned_operations: [:get_object]
)

## like:
##    aws s3 ls s3://graphchallenge/ --no-sign-request --recursive

bucket_name = 'graphchallenge'

#2024-07-02 - 2017-02-23 = 2686 days
#2025-06-09 - 2024-07-02 = 343 days

days_threshold = 2680
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
      if object.last_modified < cutoff_time
        msg = "Delete"
        # we need authorization
        #s3.delete_object(bucket: bucket_name, key: object.key)
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



