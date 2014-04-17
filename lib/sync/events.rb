class SyncEvents

  def initialize(salesforce_client, rj_client)
    @client = salesforce_client
    @rj_client = rj_client
  end

  def filter_sobjects(skipped_tables)
    @client.list_sobjects.reject {|sobject|
      skipped_tables.include?(sobject)
    }
  end

  def get_records_for(sobject)
    puts "retrieving records for #{sobject}"
    puts "sobject to string = " + sobject.to_s
    records =  @client.materialize(sobject.to_s).all
    paged_records = []
    # SalesForce returns data in pages of 250(? SHAWUN CONFIRM?) records at a time, add all the records to a new array
    retrieve_records = Proc.new {|record| paged_records.push(record.attributes)}

    records.map(&retrieve_records)
    n = 0
    while records.next_page?
      puts "#{sobject} records while loop"
      puts "#{sobject} records #{n} - #{n + paged_records.count}"
      rjpush(paged_records, sobject)
      n = n + paged_records.count
      
      paged_records = []
      records = records.next_page
      records.map(&retrieve_records)
    end
  end

  def rjpush(object_array, sobject)
      formatted_records = object_array.map{|record| format_record(record) }
      sobject = sobject.gsub("__", "_")
      if @rj_client.authenticated?
          puts "#{sobject} - starting rj push"
          @rj_client.pushData(sobject, formatted_records)
          puts "created"
      else
          puts 'rj not authenticated'
      end
  end

  def format_record(record)
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
