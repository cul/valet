

RSpec.describe "BorrowDirect Request Service" do

  it "redirects to relais with ISBN" do
    sign_in FactoryBot.create(:user)

    # hardcode expected URL
    relais_url = 'https://bd.relaisd2d.com/?' + 
                 'LS=COLUMBIA&PI=123456789&' + 
                 'query=isbn%3D9780374275631'
    get borrowdirect_path('9041682')
    expect(response).to redirect_to(relais_url)
  end

  it "redirects to relais with ISSN" do
    sign_in FactoryBot.create(:user)

    # hardcode expected URL
    relais_url = 'https://bd.relaisd2d.com/?' + 
                 'LS=COLUMBIA&PI=123456789&' + 
                 'query=issn%3D0070-4717x'
    get borrowdirect_path('4485990')
    expect(response).to redirect_to(relais_url)
  end

  it "redirects to relais with title/author" do
    sign_in FactoryBot.create(:user)

    # hardcode expected URL
    relais_url = 'https://bd.relaisd2d.com/?' + 
                 'LS=COLUMBIA&PI=123456789&' + 
                 'query=ti%3DPiotr%20and%20au%3DSokorski%2C%20W%C5%82odzimierz'
    get borrowdirect_path('123')
    expect(response).to redirect_to(relais_url)
  end

end



