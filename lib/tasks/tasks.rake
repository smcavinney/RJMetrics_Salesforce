
require 'sync/events'
require 'databasedotcom'
require 'rjmetrics_client'
require 'enumerator'


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

  syncer = SyncEvents.new(client, rj_client)

  relevant_tables = syncer.filter_sobjects(skipped_tables)
  relevant_tables = [relevant_tables[0]]

  relevant_tables.map do |sobject|
    records = []

    begin
      records = syncer.get_records_for(sobject)
    rescue
      puts 'Cannot be queried'
    end

  end
end
