
require 'sync/events'
require 'databasedotcom'
require 'rjmetrics_client'
require 'enumerator'


task :sync_events => :environment do
	client = Databasedotcom::Client.new
	client.authenticate :username => ENV["SF_USERNAME"], :password => ENV["SF_PASSWORD"]  #=> "the-oauth-token"
<<<<<<< HEAD
	skipped_tables = ["LeadFeed", "AccountFeed", "ContactHistory", "LoginHistory", "OpportunityHistory", "LeadHistory" ]
	rj_client = RJMetricsClient.new(ENV["RJ_ID"].to_i, ENV["RJ_KEY"])
=======
	skipped_tables = ["ActivityHistory", "AccountHistory" "LeadFeed", "AccountFeed", "ContactHistory", "LoginHistory", "OpportunityHistory", "LeadHistory" ]
	rj_client = Client.new(ENV["RJ_ID"].to_i, ENV["RJ_KEY"])
>>>>>>> 30b95203462fb0aacf22b9faf66131437b491fba
	if rj_client.authenticated?
	    puts 'authed!'
	else
	    puts 'not authed'
	end

  syncer = SyncEvents.new(client, rj_client)

  relevant_tables = syncer.filter_sobjects(skipped_tables)

  puts relevant_tables.count

  relevant_tables.map do |sobject|
    records = []
    puts sobject + " in the task.rake file"
    begin
      records = syncer.get_records_for(sobject)
    rescue
      puts 'Cannot be queried'
    end

  end
end
