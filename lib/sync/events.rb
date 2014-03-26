class SyncEvents

  def initialize(salesforce_client)
    @client = salesforce_client
  end

  def filter_sobjects(skipped_tables)
    @client.list_sobjects.reject {|sobject|
      skipped_tables.include?(sobject)
    }
  end

  def get_records_for(sobject)
    puts "retrieving records for #{sobject}"

    records =  @client.materialize(sobject.to_s).all
    paged_records = []

    # SalesForce returns data in pages of 250(? SHAWUN CONFIRM?) records at a time, add all the records to a new array
    retrieve_records = Proc.new {|record| paged_records.push(record.attributes) }

    records.map(&retrieve_records)

    while records.next_page?
      records = records.next_page
      records.each(&retrieve_records)
    end

    paged_records
  end

  def self.format_record(record)
    primary_keys = { "keys" => ["Id"] }
    formatted_record = primary_keys.merge(record)
    formatted_record.map do |key, value|
      if value == []
        formatted_record[key] = nil
      end
    end
    formatted_record
  end
end
