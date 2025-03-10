require "test_helper"

class ClientApplicationsTest < ActionDispatch::IntegrationTest
  ##
  # run through the procedure of creating a client application and checking
  # that it shows up on the user's account page.
  def test_create_application
    user = create(:user)

    get "/login"
    assert_response :redirect
    assert_redirected_to login_path(:cookie_test => "true")
    follow_redirect!
    assert_response :success
    post "/login", :params => { "username" => user.email, "password" => "test", :referer => "/user/#{ERB::Util.u(user.display_name)}" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "users/show"
    get "/account/edit"
    assert_response :success
    assert_template "accounts/edit"

    # check that the form to allow new client application creations exists
    assert_in_heading do
      assert_select "ul.nav.nav-tabs li.nav-item a[href='/user/#{ERB::Util.u(user.display_name)}/oauth_clients']"
    end

    # now we follow the link to the oauth client list
    get "/user/#{ERB::Util.u(user.display_name)}/oauth_clients"
    assert_response :success
    assert_in_body do
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/oauth_clients/new']"
    end

    # now we follow the link to the new oauth client page
    get "/user/#{ERB::Util.u(user.display_name)}/oauth_clients/new"
    assert_response :success
    assert_in_heading do
      assert_select "h1", "Register a new application"
    end
    assert_in_body do
      assert_select "form[action='/user/#{ERB::Util.u(user.display_name)}/oauth_clients']" do
        [:name, :url, :callback_url, :support_url].each do |inp|
          assert_select "input[name=?]", "client_application[#{inp}]"
        end
        ClientApplication.all_permissions.each do |perm|
          assert_select "input[name=?]", "client_application[#{perm}]"
        end
      end
    end

    post "/user/#{ERB::Util.u(user.display_name)}/oauth_clients",
         :params => { "client_application[name]" => "My New App",
                      "client_application[url]" => "http://my.new.app.org/",
                      "client_application[callback_url]" => "http://my.new.app.org/callback",
                      "client_application[support_url]" => "http://my.new.app.org/support" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "oauth_clients/show"
    assert_equal "Registered the information successfully", flash[:notice]

    # now go back to the account page and check its listed under this user
    get "/user/#{ERB::Util.u(user.display_name)}/oauth_clients"
    assert_response :success
    assert_template "oauth_clients/index"
    assert_in_body { assert_select "div>a", "My New App" }
  end

  ##
  # fake client workflow.
  # this acts like a 3rd party client trying to access the site.
  def test_3rd_party_token
    # apparently the oauth gem doesn't really support being used inside integration
    # tests, as its too tied into the HTTP headers and stuff that it signs.
  end

  private

  ##
  # utility method to make the HTML screening easier to read.
  def assert_in_heading(&block)
    assert_select("div.content-heading", &block)
  end

  ##
  # utility method to make the HTML screening easier to read.
  def assert_in_body(&block)
    assert_select("div#content", &block)
  end
end
