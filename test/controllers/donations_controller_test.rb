require 'test_helper'

class DonationsControllerTest < ActionDispatch::IntegrationTest
  test "we can create a donation" do
    post donations_create_url, params: {donation: {category: DonationCategory::PRODUCE, food_name: 'bananas!!!',
                                                   total_amount:'20 bunches', donor_id: 1, pickup_instructions: 'Front door',
                                                   status: DonationStatus::ACTIVE}}, headers: auth_header({donor_id: 1})
    assert_response :success
    assert_not_nil Donation.find_by_food_name 'bananas!!!'
  end

  test "failed validation causes 422 response" do
    food_name = 'carrots!!!'
    post donations_create_url, params: {donation: { food_name: food_name,
                                                   total_amount:'20 bunches', donor_id: 1, pickup_instructions: 'Front door',
                                                   status: DonationStatus::ACTIVE}}, headers: auth_header({donor_id: 1})
    assert_response 422
    res_obj = JSON.parse @response.body
    assert_equal "Category can't be blank", res_obj['errors'][0], 'should have complained about missing category'
    assert_nil Donation.find_by_food_name food_name
  end

  test "authentication is required" do
    post donations_create_url, params: {donation: {}}
    assert_response :unauthorized
  end

  test "active donations returns 1 record and marks another expired" do
    active_donations = Donation.where status: DonationStatus::ACTIVE
    assert_equal 2, active_donations.size, 'Should have found two donations with status=active, check donations.yml'
    assert_equal ClaimStatus::ACTIVE, Claim.find(2).status, 'Claim status should start as active'
    get '/donations/active', headers: auth_header({donor_id: 1})
    assert_response :success
    active_donations_api = JSON.parse @response.body
    assert_equal 1, active_donations_api.size, 'should have returned one active donation'
    assert_equal 'not expired food', active_donations_api[0]['food_name'], 'returned unexpected active donation, check donations.yml'
    active_donations = Donation.where status: DonationStatus::ACTIVE
    assert_equal 1, active_donations.size, 'Accessing the active donations through the api should have marked one expired'
    now_expired_claim = Claim.find(2)
    assert_equal ClaimStatus::EXPIRED, now_expired_claim.status, 'This claim should have been expired'
  end


  test "update donation status succeeds" do
    patch '/donations/2/update', params: {donation: {id:2, status:DonationStatus::DELETED}}, headers: auth_header({donor_id: 1})
    assert_response :success
    donation_in_db = Donation.find_by_id(2)
    assert_equal DonationStatus::DELETED, donation_in_db.status, 'should have changed status to deleted'
  end

  test "donations history returns list of closed and expired donations" do
    get '/donations/1/history_donations', headers: auth_header({donor_id: 1})
    assert_response :success
    history = JSON.parse @response.body
    donation_in_db = Donation.where(:donor_id => 1, :status => [DonationStatus::CLOSED, DonationStatus::EXPIRED]).order("updated_at desc")
    assert_equal history.count,donation_in_db.count, 'Incorrect number of donations received in the response'
    donation_in_db.each_with_index do |donation, i|
      assert_equal donation.status, history[i]['status'], "The status of donation: #{history[i]['id']}, is invalid"
    end
  end

<<<<<<< Updated upstream
  test "claims history returns list of closed claims" do
    get '/donations/1/history_claims', headers: auth_header({client_id: 1})
    assert_response :success
    history = JSON.parse @response.body
    claim_in_db = Claim.where(:client_id => 1, :status => [ClaimStatus::CLOSED]).order("updated_at desc")
    assert_equal history.count,claim_in_db.count, 'Incorrect number of claims received in the response'
    claim_in_db.each_with_index do |claim, i|
      assert_equal claim.status, history[i]['status'], "The status of claim: #{history[i]['id']}, is invalid"
    end
  end

=======
>>>>>>> Stashed changes
  test "only updates to donations owned by logged in donor" do
    patch '/donations/2/update', params: {donation: {id:2, status:DonationStatus::DELETED}}, headers: auth_header({donor_id: 2})
    assert_response :unauthorized
  end

  test "make sure that we return the latitude and longitude for a donation" do
    get '/donations/active', headers: auth_header({donor_id: 1})
    active_donations_api = JSON.parse @response.body
    assert_not_nil active_donations_api[0]['donor']['latitude']
  end

  test "claiming a donation adds a claims table record and changes the donation status to claimed" do
    assert_equal DonationStatus::ACTIVE, Donation.find_by_id(2).status, 'Donation status should start as active'
    post '/donations/2/claim', params: {client_id: 1}, headers: auth_header({client_id: 1})
    assert_response :success
    assert_equal 1, Claim.find_by_donation_id(2).client_id, 'there should now be a claims record'
    assert_equal DonationStatus::CLAIMED, Donation.find_by_id(2).status, 'Donation status should now be claimed'
  end

  test "passing client coords includes distance value for donations" do
    get '/donations/active', params: {client_lat: 47.609175 , client_long: -122.325849}, headers: auth_header({client_id: 1})
    res_obj = JSON.parse @response.body
    assert_not_nil res_obj[0]['distance']
  end

  test "passing client coords filters out results that are more than 20 miles away" do
    get '/donations/active', params: {client_lat: 46.609175 , client_long: -122.325849}, headers: auth_header({client_id: 1})
    res_obj = JSON.parse @response.body
    assert_equal [], res_obj, 'should have returned empty array'
  end

end
