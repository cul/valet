

RSpec.describe 'ILL Scan' do


  it 'presents campus-selection form' do
    sign_in FactoryBot.create(:happyuser)
    get ill_scan_path('123')
    expect(response.body).to include('Please select your campus')
  end


  it 'redirects MBUTS-campus patrons to ezproxy/illiad (book chapter)' do
    sign_in FactoryBot.create(:happyuser)

    params = { id: '123', campus: 'mbuts' }
    post ill_scan_index_path, params: params

    expect(response).to redirect_to('https://ezproxy.cul.columbia.edu/login?url=https://columbia.illiad.oclc.org/illiad/zcu/illiad.dll?Action=10&ESPNumber=3777209&Form=23&ISSN=&PhotoItemAuthor=Sokorski%2C+W%C5%82odzimierz&PhotoItemEdition=Wyd.+1.&PhotoItemPlace=Warszawa&PhotoItemPublisher=Pan%CC%81stwowy+Instytut+Wydawniczy&PhotoJournalTitle=Piotr&PhotoJournalYear=1976.&notes=http%3A%2F%2Fclio.columbia.edu%2Fcatalog%2F123')
  end

  it 'redirects MBUTS-campus patrons to ezproxy/illiad (article)' do
    sign_in FactoryBot.create(:happyuser)

    params = { id: '101', campus: 'mbuts' }
    post ill_scan_index_path, params: params

    expect(response).to redirect_to('https://ezproxy.cul.columbia.edu/login?url=https://columbia.illiad.oclc.org/illiad/zcu/illiad.dll?Action=10&CallNumber=Z732.V5+V55&ESPNumber=2172527&Form=22&ISSN=0363-3500&PhotoArticleAuthor=Vermont.+Department+of+Libraries&PhotoJournalTitle=Biennial+report+of+the+Vermont+Department+of+Libraries&notes=http%3A%2F%2Fclio.columbia.edu%2Fcatalog%2F101')
  end

  it 'redirects MCC-campus patrons to ezproxy/illiad' do
    sign_in FactoryBot.create(:happyuser)

    params = { id: '123', campus: 'mcc' }
    post ill_scan_index_path, params: params

    expect(response).to redirect_to('https://ezproxy.cul.columbia.edu/login?url=https://columbia.illiad.oclc.org/illiad/zcu/illiad.dll?Action=10&ESPNumber=3777209&Form=23&ISSN=&PhotoItemAuthor=Sokorski%2C+W%C5%82odzimierz&PhotoItemEdition=Wyd.+1.&PhotoItemPlace=Warszawa&PhotoItemPublisher=Pan%CC%81stwowy+Instytut+Wydawniczy&PhotoJournalTitle=Piotr&PhotoJournalYear=1976.&notes=http%3A%2F%2Fclio.columbia.edu%2Fcatalog%2F123')
  end

  it 'redirects TC-campus patrons to Law website' do
    sign_in FactoryBot.create(:happyuser)

    params = { id: '123', campus: 'tc' }
    post ill_scan_index_path, params: params

    expect(response).to redirect_to('https://library.tc.columbia.edu/p/request-materials')
  end

  it 'redirects Law-campus patrons to Law website' do
    sign_in FactoryBot.create(:happyuser)

    params = { id: '123', campus: 'law' }
    post ill_scan_index_path, params: params

    expect(response).to redirect_to('http://www.law.columbia.edu/library/services')
  end


  it 'redirects blocked patron to failure page' do
    sign_in FactoryBot.create(:blockeduser)
    get ill_scan_path('123')
    expect(response).to redirect_to( APP_CONFIG[:ill_scan][:ineligible_url] )
  end


end



