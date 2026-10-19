# frozen_string_literal: true

require 'spec_helper'

# Every manifest in examples/ compiles, on each supported OS.
Dir[File.expand_path('../../examples/*.pp', __dir__)].sort.each do |example|
  describe "examples/#{File.basename(example)}", type: :host do
    let(:pre_condition) { File.read(example) }

    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
