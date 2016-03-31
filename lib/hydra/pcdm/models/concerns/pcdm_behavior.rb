module Hydra::PCDM
  module PcdmBehavior
    extend ActiveSupport::Concern
    included do
      ordered_aggregation :members,
                          has_member_relation: Vocab::PCDMTerms.hasMember,
                          class_name: 'ActiveFedora::Base',
                          type_validator: type_validator,
                          through: :list_source
      indirectly_contains :related_objects, has_member_relation: RDF::Vocab::ORE.aggregates,
                                            inserted_content_relation: RDF::Vocab::ORE.proxyFor, class_name: 'ActiveFedora::Base',
                                            through: 'ActiveFedora::Aggregation::Proxy', foreign_key: :target,
                                            type_validator: Validators::PCDMObjectValidator
    end

    module ClassMethods
      def type_validator
        @type_validator ||= Validators::CompositeValidator.new(
          super,
          Validators::PCDMValidator,
          Validators::AncestorValidator
        )
      end
    end

    def member_of
      return [] if id.nil?
      ActiveFedora::Base.where(member_ids_ssim: id)
    end

    def ordered_member_ids
      ordered_member_proxies.map(&:target_id)
    end

    def objects
      members.select(&:pcdm_object?)
    end

    def object_ids
      objects.map(&:id)
    end

    def ordered_objects
      ordered_members.to_a.select(&:pcdm_object?)
    end

    def ordered_object_ids
      ordered_objects.map(&:id)
    end

    def in_collections
      member_of.select(&:pcdm_collection?).to_a
    end

    def in_collection_ids
      in_collections.map(&:id)
    end

    def ancestor?(record)
      ancestor_checker.ancestor?(record)
    end

    def ancestor_checker
      @ancestor_checker ||= ::Hydra::PCDM::AncestorChecker.new(self)
    end
  end
end
