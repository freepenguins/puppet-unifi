# frozen_string_literal: true

require 'spec_helper'

describe 'Unifi::Environment' do
  it { is_expected.to allow_value({}) }
  it { is_expected.to allow_value({ 'JVM_MAX_HEAP_SIZE' => 2048, 'UNIFI_JVM_EXTRA_OPTS' => '-Dx=y', '_FLAG' => true }) }
  it { is_expected.not_to allow_value({ 'BAD-NAME' => 'x' }) }
  it { is_expected.not_to allow_value({ '1ST' => 'x' }) }
  it { is_expected.not_to allow_value({ 'LIST' => ['a'] }) }
end
