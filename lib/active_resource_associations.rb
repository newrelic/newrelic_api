# This mixin defines ActiveRecord style associations (like has_many) for ActiveResource objects.
# ActiveResource objects using this mixin must define the method 'query_params'.
module ActiveResourceAssociations #:nodoc:
  class << self
    protected
    def included(base)
      class << base
        # a special ActiveResource implementation of has_many
        def has_many(*associations)
          associations.to_a.each do |association|
            define_method association do |*args|
              val = attributes[association.to_s] # if we've already fetched the relationship in the initial fetch, return it
              return val if val

              options = args.extract_options!
              type = args.first || :all

              begin
                # look for the class definition within the current class
                clazz = ( self.class.name + '::' + association.to_s.camelize.singularize).constantize
              rescue
                # look for the class definition in the NRAPI module
                clazz = ( "#{self.class.parent.name}::" + association.to_s.camelize.singularize).constantize
              end
              params = (options[:params] || {}).update(self.query_params)
              options[:params] = params
              clazz.find(type, options)
            end
          end
        end
      end
    end
  end

end