
# RSpec.describe FormsController do
# 
#   describe "GET /intercampus/123" do
# 
#     # let(:request) { double('request', path: '/intercampus/123') }
# 
#     it "redirects to resolver link" do
#       # sign_in FactoryBot.create(:user)
# puts request.headers
#       
#       get :show, params: { id: '123' }
#       bounce_url = APP_CONFIG[:intercampus][:bounce_url]
#       expect(response).to redirect_to(bounce_url)
#     end
# 
#   end
# end



RSpec.describe "Intercampus Request Service" do

  it "redirects to resolver link" do
    get intercampus_path('123')
    bounce_url = APP_CONFIG[:intercampus][:bounce_url]
    expect(response).to redirect_to(bounce_url)
  end

end