require 'test_helper'

class OffsiteRequestsControllerTest < ActionController::TestCase
  setup do
    @offsite_request = offsite_requests(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:offsite_requests)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create offsite_request' do
    assert_difference('OffsiteRequest.count') do
      post :create, offsite_request: {}
    end

    assert_redirected_to offsite_request_path(assigns(:offsite_request))
  end

  test 'should show offsite_request' do
    get :show, id: @offsite_request
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @offsite_request
    assert_response :success
  end

  test 'should update offsite_request' do
    patch :update, id: @offsite_request, offsite_request: {}
    assert_redirected_to offsite_request_path(assigns(:offsite_request))
  end

  test 'should destroy offsite_request' do
    assert_difference('OffsiteRequest.count', -1) do
      delete :destroy, id: @offsite_request
    end

    assert_redirected_to offsite_requests_path
  end
end
