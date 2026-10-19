# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'the module hierarchy' do
  let(:paths) { YAML.safe_load_file(File.expand_path('../../hiera.yaml', __dir__))['hierarchy'].first['paths'] }

  it 'looks up the OS release, then its codename, then the OS name and family' do
    expect(paths).to eq([
                          'os/%{facts.os.name}/%{facts.os.name}-%{facts.os.release.major}.yaml',
                          'os/%{facts.os.name}/%{facts.os.distro.codename}.yaml',
                          'os/%{facts.os.name}.yaml',
                          'os/%{facts.os.family}.yaml',
                        ])
  end
end
