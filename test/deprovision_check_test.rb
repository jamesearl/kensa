require_relative 'helper'

class DeprovisionTest < Test::Unit::TestCase
  include Heroku::Kensa

  def setup
    @manifest = Manifest.new(:method => "post").skeleton
    @manifest['api']['password'] = 'secret'
    base_url = @manifest['api']['test']['base_url'].chomp("/")
    base_url += "/heroku/resources" unless base_url =~ %r{/heroku/resources\z}
    base_url += "/123"
    @uri = URI.parse(base_url)
    Artifice.activate_with(ProviderServer)
    super
  end

  def teardown
    super
    Artifice.deactivate
  end

  def resource(user = nil, pass = nil)
    RestClient::Resource.new(@uri.to_s, user, pass)
  end

  def authed_resource
    resource(@manifest['id'], @manifest['api']['password'])
  end

  test "requires quthentication" do
    assert_raises RestClient::Unauthorized do
      resource.delete({})
    end

    assert_raises RestClient::Unauthorized do
      resource('incorrect-user', 'incorrect-pass').delete
    end

    assert_raises RestClient::Unauthorized do
      resource(@manifest['id'], 'incorrect-pass').delete
    end

    assert_raises RestClient::Unauthorized do
      resource('incorrect-user', @manifest['api']['password']).delete
    end

    assert_nothing_raised RestClient::Unauthorized do
      authed_resource.delete
    end
  end

  test "returns 200 response" do
    response = authed_resource.delete
    assert_equal 200, response.code
  end
end

class DeprovisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  context "with SSO post" do
    setup do
      @data = Manifest.new(:method => "post").skeleton.merge :id => 123
      @responses = [
        [200, ""],
        [401, ""],
      ]
    end

    def check ; DeprovisionCheck ; end

    test "valid on 200" do
      assert_valid do |check|
        kensa_stub :delete, check, @responses
      end
    end

    test "status other than 200" do
      @responses[0] = [500, ""]
      assert_invalid do |check|
        kensa_stub :delete, check, @responses
      end
    end

    test "runs auth check" do
      @responses[1] = [200, ""]
      assert_invalid do |check|
        kensa_stub :delete, check, @responses
      end
    end
  end
end
