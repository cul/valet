

RSpec.describe 'BorrowDirect Request Service' do
  it 'redirects to relais with ISBN' do
    sign_in FactoryBot.create(:user)

    # hardcode expected URL
    relais_url = 'https://bd.relaisd2d.com/?' \
                 'LS=COLUMBIA&PI=123456789&' \
                 'query=isbn%3D9780374275631'
    get borrowdirect_path('9041682')
    expect(response).to redirect_to(relais_url)
  end

  it 'redirects to relais with ISSN' do
    sign_in FactoryBot.create(:user)

    # hardcode expected URL
    relais_url = 'https://bd.relaisd2d.com/?' \
                 'LS=COLUMBIA&PI=123456789&' \
                 'query=issn%3D0070-4717'
    get borrowdirect_path('4485990')
    expect(response).to redirect_to(relais_url)
  end

  it 'redirects to relais with title/author' do
    sign_in FactoryBot.create(:user)

    # hardcode expected URL
    relais_url = 'https://bd.relaisd2d.com/?' \
                 'LS=COLUMBIA&PI=123456789&' \
                 'query=ti%3D%22Piotr%22' \
                 '%20and%20au%3D%22Sokorski%2C%20W%C5%82odzimierz%22'
    get borrowdirect_path('123')
    expect(response).to redirect_to(relais_url)
  end

  it 'redirects to relais for SCSB ReCAP Partner item' do
    sign_in FactoryBot.create(:user)

    # hardcode expected URL
    relais_url = 'https://bd.relaisd2d.com/?' \
                 'LS=COLUMBIA&PI=123456789&' \
                 'query=' \
                 'ti%3D%22A%20national%20public%20labor' \
                 '%20relations%20policy%20for%20tomorrow%22' \
                 '%20and%20' \
                 'au%3D%22Emery%2C%20James%20A.%22'
    get borrowdirect_path('SCSB-1441991')
    expect(response).to redirect_to(relais_url)
  end

  it 'bounces unauth user to sign-in page' do
    get borrowdirect_path('123')
    expect(response.body).to redirect_to('http://www.example.com/sign_in')
  end

  it 'renders error page for non-existant item' do
    sign_in FactoryBot.create(:user)
    # CLIO has no bib id 60
    get borrowdirect_path('60')
    expect(response.body).to include('Cannot find bib record')
  end
end
