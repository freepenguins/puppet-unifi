# frozen_string_literal: true

require 'spec_helper'

describe 'Unifi::Property' do
  ['unifi.https.port', 'portal.http.port', 'unifi.G1GC.enabled', 'db.mongo_uri', 'a-b.c_d', '1x'].each do |name|
    it { is_expected.to allow_value(name) }
  end

  ['', 'unifi http.port', 'unifi/http.port', "unifi.http.port'x", 'unifi.http.port"x', '.hidden', '-flag', "a\nb", 'a=b'].each do |name|
    it { is_expected.not_to allow_value(name) }
  end
end
