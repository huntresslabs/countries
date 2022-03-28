# frozen_string_literal: true

module ISO3166
  module CountryFinderMethods
    FIND_BY_REGEX = /^find_(all_)?(country_|countries_)?by_(.+)/.freeze
    SEARCH_TERM_FILTER_REGEX = /\(|\)|\[\]|,/.freeze

    def search(query)
      country = new(query.to_s.upcase)
      country&.valid? ? country : nil
    end

    def [](query)
      search(query)
    end

    def find_all_by(attribute, val)
      attributes, lookup_value = parse_attributes(attribute, val)

      ISO3166::Data.cache.select do |_, v|
        country = Country.new(v)
        attributes.any? do |attr|
          Array(country.send(attr)).any? do |n|
            lookup_value === cached(n) { parse_value(n) }
          end
        end
      end
    end

    def method_missing(method_name, *arguments)
      matches = method_name.to_s.match(FIND_BY_REGEX)
      return_all = matches[1]
      super unless matches

      if matches[3] == 'names'
        if RUBY_VERSION =~ /^3\.\d\.\d/
          warn "DEPRECATION WARNING: 'find_by_name' and 'find_*_by_name' methods are deprecated, please refer to the README file for more information on this change.", uplevel: 1, category: :deprecated
        else
          warn "DEPRECATION WARNING: 'find_by_name' and 'find_*_by_name' methods are deprecated, please refer to the README file for more information on this change.", uplevel: 1
        end
        matches = matches.to_a
        matches[3] = 'unofficial_names'
      end

      countries = find_by(matches[3], arguments[0], matches[2])
      return_all ? countries : countries.last
    end

    def respond_to_missing?(method_name, include_private = false)
      matches = method_name.to_s.match(FIND_BY_REGEX)
      if matches && matches[3]
        instance_methods.include?(matches[3].to_sym)
      else
        super
      end
    end

    protected

    def find_by(attribute, value, obj = nil)
      find_all_by(attribute.downcase, value).map do |country|
        obj.nil? ? country : new(country.last)
      end
    end

    def parse_attributes(attribute, val)
      raise "Invalid attribute name '#{attribute}'" unless searchable_attribute?(attribute.to_sym)

      attributes = Array(attribute.to_s)
      if attribute.to_s == 'name'
        if RUBY_VERSION =~ /^3\.\d\.\d/
          warn "DEPRECATION WARNING: 'find_by_name' and 'find_*_by_name' methods are deprecated, please refer to the README file for more information on this change.", uplevel: 1, category: :deprecated
        else
          warn "DEPRECATION WARNING: 'find_by_name' and 'find_*_by_name' methods are deprecated, please refer to the README file for more information on this change.", uplevel: 1
        end
        # 'find_by_name' and 'find_*_by_name' will be changed for 5.0
        # The addition of 'iso_short_name' here ensures the behaviour of 4.1 is kept for 4.2
        attributes = %w[iso_short_name unofficial_names translated_names]
      elsif attribute.to_s == 'any_name'
        attributes = %w[iso_long_name iso_short_name unofficial_names translated_names]
      end

      [attributes, parse_value(val)]
    end

    def parse_value(value)
      value = value.gsub(SEARCH_TERM_FILTER_REGEX, '') if value.respond_to?(:gsub)
      strip_accents(value)
    end

    def searchable_attribute?(attribute)
      searchable_attributes.include?(attribute.to_sym)
    end

    def searchable_attributes
      # Add name and names until we complete the deprecation of the finders
      instance_methods - UNSEARCHABLE_METHODS + [:name, :names, :any_name]
    end
  end
end
