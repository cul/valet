

RSpec.describe 'Offsite Request Service' do
  it 'bounces unauth user to sign-in page' do
    get offsite_requests_path
    expect(response.body).to redirect_to('http://www.example.com/sign_in')
  end

  it 'asks for bib if none given' do
    sign_in FactoryBot.create(:happyuser)

    get offsite_requests_path
    expect(response).to redirect_to(bib_offsite_requests_path)
  end

  it 'rejects bib with no offsite holdings' do
    sign_in FactoryBot.create(:happyuser)

    get holding_offsite_requests_path, params: { bib_id: '123' }
    expect(request.flash[:error]).to include('has no offsite holdings')
    expect(response).to redirect_to(bib_offsite_requests_path)
  end

  it 'redirects multi-holding bib to holding-selection' do
    sign_in FactoryBot.create(:happyuser)

    params = { bib_id: '1958690' }
    get bib_offsite_requests_path, params: params
    expect(response).to redirect_to(holding_offsite_requests_path(params: params))
  end

  it 'holding-selection form renders correctly' do
    sign_in FactoryBot.create(:happyuser)

    get holding_offsite_requests_path, params: { bib_id: '1958690' }
    expect(response.body).to include('Which holding of this record would you like')
  end

  it 'redirects single-holding bib to new request path' do
    sign_in FactoryBot.create(:happyuser)

    params = { bib_id: '5396605' }
    get holding_offsite_requests_path, params: params
    params = { bib_id: '5396605', mfhd_id: '6224583' }
    expect(response).to redirect_to(new_offsite_request_path(params: params))
  end

  it 'renders item-request form correctly' do
    sign_in FactoryBot.create(:happyuser)

    params = { bib_id: '5396605', mfhd_id: '6224583' }
    get new_offsite_request_path, params: params
    expect(response.body).to include('select one or more items')
  end
end
