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

  def filter_tasks(records)
    puts "filtering tasks"
    new_records = []
    records.each do |record|
      new_record = {}
      record.each do |key, value| 
        #puts value
        if value.is_a?(String)
          new_value = value.to_s.slice!(0..255)
          new_record[key.to_s] = new_value
          #puts new_record
        else
          new_record[key.to_s] = value
        end
      end
      new_records.push(new_record)
    end
    return new_records
  end


  def get_records_for(sobject)
    puts "retrieving records for #{sobject}"
    puts "sobject to string = " + sobject.to_s
    records =  @client.materialize(sobject.to_s).all
    puts records.count
    paged_records = []
    # SalesForce returns data in pages of 250(? SHAWUN CONFIRM?) records at a time, add all the records to a new array
    retrieve_records = Proc.new {|record| paged_records.push(record.attributes)}

    records.map(&retrieve_records)
    n = 0
    while records.next_page?
      puts "#{sobject} records while loop"
      puts "#{sobject} records #{n} - #{n + paged_records.count}"
      if sobject == "Task"
        task_records = filter_tasks(paged_records)
        rjpush(task_records, sobject)
      else
        puts "pushing non-tasks"
        #puts paged_records
        rjpush(paged_records, sobject)
      end
      n = n + paged_records.count

      paged_records = []
      records = records.next_page
      records.map(&retrieve_records)
    end

    puts "#{sobject} out of while loop"
    if sobject == "Task"
      task_records = filter_tasks(paged_records)
      rjpush(task_records, sobject)
    else
      puts "pushing non-tasks"
      #puts paged_records
      rjpush(paged_records, sobject)
    end
  end

  def rjpush(object_array, sobject)
      formatted_records = object_array.map{|record| format_record(record) }
      #puts formatted_records
      sobject = sobject.gsub("__", "_")
      if @rj_client.authenticated?
          puts "#{sobject} - starting rj push"
          puts formatted_records
          response = @rj_client.pushData(sobject, formatted_records)
          puts response
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
