require File.expand_path('../../helper', __FILE__)

class Reality::Mda::TestCore < Reality::Mda::TestCase
  def test_define_system_using_defaults
    module_type = Reality::Mda.define_system(TestModule) do |r|
      r.model_element(:icon_set)
      r.model_element(:icon, :icon_set)
    end

    assert_equal TestModule, module_type

    assert_true TestModule.const_defined?(:Model), 'TestModule::Model defined'
    assert_true TestModule.const_defined?(:FacetManager), 'TestModule::FacetManager defined'
    assert_true TestModule.const_defined?(:TemplateSetManager), 'TestModule::TemplateSetManager defined'

    # And the models
    assert_true TestModule::Model.const_defined?(:IconSet), 'TestModule::Model::IconSet defined'
    assert_true TestModule::Model.const_defined?(:Icon), 'TestModule::Model::Icon defined'

    # And the Logging
    assert_true TestModule.const_defined?(:Logger), 'TestModule::Logger defined'

    TestModule::FacetManager.facet(:gwt) do |facet|
      facet.enhance(TestModule::Model::IconSet) do
        def self.facet_templates_directory
          File.expand_path("#{File.dirname(__FILE__)}/templates")
        end

        def helper_name
          "#{Reality::Naming.pascal_case(icon_set.name)}Helper"
        end

        def qualified_helper_name
          "#{Reality::Naming.underscore(icon_set.name)}.helpers.#{helper_name}"
        end

        java_artifact(:assets, :helper)
      end
    end

    assert_true TestModule::FacetManager::FacetDefinitions.const_defined?(:GwtIconSetFacet), 'TestModule::FacetManager::FacetDefinitions::GwtIconSetFacet defined'
    assert_false TestModule::FacetManager::FacetDefinitions.const_defined?(:GwtIconFacet), 'TestModule::FacetManager::FacetDefinitions::GwtIconFacet defined'

    # There is no icon_sets defined yet
    assert_equal 0, TestModule.icon_sets.size

    # Test model is hooked up correctly
    TestModule.icon_set(:fa) do |s|
      s.enable_facets(:gwt)
      assert_equal 'fa.helpers.FaHelper', s.gwt.qualified_helper_name
      s.icon(:map_marker)
      s.icon(:cross)
    end

    assert_equal 1, TestModule.icon_sets.size

    icon_set = TestModule.icon_set_by_name(:fa)

    assert_equal :fa, icon_set.name
    assert_equal 2, icon_set.icons.size

    target_dir = self.local_dir

    TestModule::TemplateSetManager.generator.generate(:icon_set, icon_set, target_dir, [:gwt_assets], nil)

    generated_file = "#{target_dir}/main/java/fa/helpers/FaHelper.java"
    assert_true File.exist?(generated_file)
    assert_equal "fa.helpers.FaHelper\n",IO.read(generated_file)
  end
end
