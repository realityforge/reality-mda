#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Reality #nodoc
  module Mda #nodoc
    Reality::Logging.configure(Reality::Mda, ::Logger::WARN)

    class << self
      def define_system(module_type, options = {})
        model_container_key = options[:model_container_key] || :Model
        facet_container_key = options[:facet_container_key] || :FacetManager
        template_set_container_key = options[:template_set_container_key] || :TemplateSetManager

        module_type.class_eval <<-RUBY
  Reality::Logging.configure(#{module_type}, ::Logger::WARN)

  module #{template_set_container_key}
    class << self
      include Reality::Generators::TemplateSetContainer
    end
  end

  module ArtifactDSL
    include Reality::Generators::ArtifactDSL

    def template_set_container
      #{module_type}::#{template_set_container_key}
    end
  end

  module #{facet_container_key}
    extend Reality::Facets::FacetContainer
  end

  #{module_type}::#{facet_container_key}.extension_manager.singleton_extension(ArtifactDSL)

  module #{model_container_key}
  end
        RUBY

        model_container = module_type.const_get(model_container_key)
        facet_container = module_type.const_get(facet_container_key)
        template_set_container = module_type.const_get(template_set_container_key)

        repository = Reality::Model::Repository.new(module_type.name,
                                                    model_container,
                                                    :instance_container => module_type,
                                                    :facet_container => facet_container,
                                                    :log_container => module_type) do |r|
          yield r
        end

        root_elements = repository.model_elements.select { |e| e.container_key.nil? }
        if 1 != root_elements.size
          Reality::Mda.error("The Reality::Mda library only supports models with a single root element. Actual root elements include: #{root_elements.collect { |e| e.key }.inspect}")
        end

        Reality::Facets.copy_targets_to_generator_target_manager(template_set_container, facet_container)

        root_element = root_elements[0]
        default_descriptor_name = options[:default_descriptor_name] || "#{root_element.key}.rb"
        build_container_key = options[:build_container_key] || :Build
        buildr_prefix = options[:buildr_prefix] || root_element.key
        module_type.class_eval <<-RUBY
class #{build_container_key}
  class << self
    include Reality::Generators::Rake::BuildTasksMixin

    def default_descriptor_filename
      '#{default_descriptor_name}'
    end

    def generated_type_path_prefix
      :#{buildr_prefix}
    end

    def root_element_type
      :#{root_element.key}
    end

    def log_container
      #{module_type.name}
    end
  end

  class GenerateTask < Reality::Generators::Rake::BaseGenerateTask
    def initialize(root_element_key, key, generator_keys, target_dir, buildr_project = nil)
      super(root_element_key, key, generator_keys, target_dir, buildr_project)
    end

    protected

    def default_namespace_key
      :#{buildr_prefix}
    end

    def template_set_container
      #{template_set_container.name}
    end

    def instance_container
      #{module_type.name}
    end

    def root_element_type
      :#{root_element.key}
    end

    def log_container
      #{module_type.name}
    end
  end

  class LoadDescriptor < Reality::Generators::Rake::BaseLoadDescriptor
    protected

    def default_namespace_key
      :#{root_element.key}
    end

    def log_container
      #{module_type.name}
    end
  end
end
        RUBY
      end
    end
  end
end
