
require 'databasedotcom'
require 'rjmetrics_client'


def rjpush(object_array, sobject, rj_client)
    sobject = sobject.gsub("__", "_")
    if rj_client.authenticated?
        return rj_client.pushData(sobject, object_array)
        puts "created"
    else
        puts 'rj not authenticated'
    end
end


task :sync_events => :environment do
	client = Databasedotcom::Client.new
	client.authenticate :username => ENV["SF_USERNAME"], :password => ENV["SF_PASSWORD"]  #=> "the-oauth-token"
	skipped_tables = ["LeadFeed", "AccountFeed", "ContactHistory", "LoginHistory", "OpportunityHistory", "LeadHistory" ]
	rj_client = Client.new(ENV["RJ_ID"].to_i, ENV["RJ_KEY"])
	if rj_client.authenticated?
	    puts 'authed!'
	else
	    puts 'not authed'
	end
	client.list_sobjects.each do |sobject|
	    unless skipped_tables.include?(sobject)
	        puts "starting import of #{sobject}"
	        begin
	            object_array = []
	            records =  client.materialize("#{sobject}").all
	            records_with_pages = []
	        # SalesForce returns data in pages of 2000 records at a time, add all the records to a new array
	        records.each do |record|
	            records_with_pages.push(record.attributes)
	        end
	        while records.next_page?
	            records = records.next_page
	            records.each do |record|
	                records_with_pages.push(record.attributes)
	            end

	        end
	        # Add the keys field to each record for the import api
	        records_with_pages.each do |record|
	            hash = { "keys" => ["Id"] }
	            #puts record
	            hash = hash.merge(record)
	            hash.each do |key, value|
	                if value == []
	                    hash[key] = nil
	                else

	                end
	            end
	            #puts hash
	            # Add total result with correct keys field to the object array to push to RJM
	            object_array.push(hash)

	        end

	        puts object_array.count
	        if object_array.count > 5000
	            puts "Large Query, is this needed?"
	        end
	        total_records = object_array.count
	        # pushing all records in objectst that have less that 100 records
	        if total_records < 101 && total_records > 0
	            puts "rows 0 through #{total_records}"
	            rjpush(object_array, sobject, rj_client)
	        else
	            # pushing 100 records at a time for objectst that have more that 100 records
	            i = 99
	            first_record = 0
	            while total_records >= i + 1
	                short_array = object_array[first_record..i]
	                puts "rows #{first_record} through #{i}"
	                rjpush(short_array, sobject, rj_client)
	                i = i + 100
	                first_record = first_record + 100
	            end
	            # pushing the trailing records
	            short_array = object_array[first_record..total_records]
	            puts "rows #{first_record} through #{total_records}"
	            rjpush(short_array, sobject, rj_client)
	        end

	        rescue
	          puts 'Cannot be queried'
	        end

	    end
	end
end
