require "test_helper"

class Admin::VerificationsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get admin_verifications_create_url
    assert_response :success
  end
end
