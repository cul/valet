
RSpec.describe 'ReCAP Scan' do
  
  it 'presents item-selection and citation form' do
    sign_in FactoryBot.create(:happyuser)
    get recap_scan_path('101', '118')

    # Item Selection
    expect(response.body).to include( 'Please select an item' )
    # Specific barcodes should be listed
    expect(response.body).to include( 'CU08414130' )
    expect(response.body).to include( 'CU08414149' )
 
    # Delivery Location
    expect(response.body).to include( 'Please enter citation details' )
    # - specific fields in the citation
    expect(response.body).to include( 'Chapter/Article Title' )
    expect(response.body).to include( 'Start Page' )
  end
  
  
  it 'non-offsite bib gives error message' do
    sign_in FactoryBot.create(:happyuser)
    get recap_scan_path('123', '144')
    expect(response.body).to include( 'Bib ID 123 is not eligble for service Offsite Scan' )
  end
  
  it 'redirects blocked patron to failure page' do
    sign_in FactoryBot.create(:blockeduser)
    get recap_scan_path('101', '118')
    expect(response).to redirect_to( APP_CONFIG[:recap_scan][:ineligible_url] )
  end
  
end


