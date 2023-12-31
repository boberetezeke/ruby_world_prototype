class Obj
  module Mixins
    module Display
      def fields(cols, display)
        cols.map do |col_info|
          if col_info.is_a?(Hash)
            full_id = col_info.values.first
          else
            full_id = col_info
          end

          if full_id.is_a?(Proc)
            [nil, { title: '', type: :string, width: 20}, full_id]
          else
            d = display
            last_id = full_id
            if full_id.is_a?(Array)
              if full_id.size > 1
                d = eval("Obj::" + camelize(full_id[-2].to_s)).default_display
                last_id = full_id[-1]
              else
                full_id = full_id[0]
                last_id = full_id
              end
            end
            [last_id, d[:fields][last_id], full_id]
          end
        end
      end

      def data_lambda(fields)
        ->(obj){
          fields.map do |id, f, full_id|
            if full_id.is_a?(Proc)
              val = full_id.call(obj)
            elsif full_id.is_a?(Array)
              val = obj
              full_id.each{|sym| val = val&.send(sym) }
            else
              val = obj.send(id)
            end

            case f[:type]
            when :string
              val
            when :integer
              val ? f[:format] % [val] : ''
            when :float
              val ? f[:format] % [val] : ''
            when :datetime
              val ? val.strftime(f[:format] || "%Y-%m-%d %H:%M:%S") : ''
            when :date
              val ? val.strftime(f[:format] || "%Y-%m-%d") : ''
            when :tags
              val ? Array(val).map(&:name).join(', ') : ''
            end
          end
        }
      end
    end
  end
end