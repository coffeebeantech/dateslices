module Dateslices
  module Scopes

    Dateslices::FIELDS.each do |field|
      puts "defining method #{field}"
      define_method :"group_by_#{field}" do |*args|
        args = args.dup
        column = args[0].blank? ? 'created_at' : args[0]

        time_filter = case connection.adapter_name
                        when 'SQLite'
                          Dateslices::Sqlite.time_filter(column, field)
                        when 'PostgreSQL', 'PostGIS'
                          Dateslices::Postgresql.time_filter(column, field)
                        when 'MySQL', 'Mysql2'
                          Dateslices::Mysql.time_filter(column, field)
                        else
                          throw "Unknown database adaptor #{connection.adapter_name}"
                        end

        sql = "count(*) as count, #{time_filter} as date_slice"

        x = select(sql).group('date_slice').order('date_slice').collect do |c|
          slice = c['date_slice']
          slice = slice.is_a?(Float) ? slice.to_i.to_s : slice.to_s
          [slice, c['count']]
        end
        Hash[*x.flatten]
      end
    end

  end
end
