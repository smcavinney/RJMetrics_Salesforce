
require 'sync/events'
require 'databasedotcom'
require 'rjmetrics_client'
require 'enumerator'

def rjpush(object_array, sobject, rj_client)
    sobject = sobject.gsub("__", "_")
    if rj_client.authenticated?
        puts "created"
        return rj_client.pushData(sobject, object_array)
    else
        puts 'rj not authenticated'
    end
end


task :sync_events => :environment do
	client = Databasedotcom::Client.new
	client.authenticate :username => ENV["SF_USERNAME"], :password => ENV["SF_PASSWORD"]  #=> "the-oauth-token"
	skipped_tables = ["LeadFeed", "AccountFeed", "ContactHistory", "LoginHistory", "OpportunityHistory", "LeadHistory" ]
	#rj_client = Client.new(ENV["RJ_ID"].to_i, ENV["RJ_KEY"])
	rj_client = RJMetricsClient.new(2, "3d1f18ca548fb694b11ae4c309060f5d")
	if rj_client.authenticated?
	    puts 'authed!'
	else
	    puts 'not authed'
	end

  syncer = SyncEvents.new(client)

  relevant_tables = syncer.filter_sobjects(skipped_tables)
  relevant_tables = [relevant_tables[0]]

  relevant_tables.map{|sobject|
    records = []

    begin
      records = syncer.get_records_for(sobject)
    rescue
      puts 'Cannot be queried'
    end

    formatted_records = records.map{|record| SyncEvents.format_record(record) }

    if formatted_records.count > 5000
      puts "Large Query #{formatted_records.count} records, is this needed?"
    end

    formatted_records.each_slice(100) {|records_to_push|
      rjpush(records_to_push, sobject, rj_client)
    }
  }
end
