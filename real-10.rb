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

      if object.last_modified < cutoff_time
        msg = "Delete       "
        #s3.delete_object(bucket: bucket_name, key: object.key)
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

