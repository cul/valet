
RSpec.describe 'ReCAP Loan' do
  
  
  it 'presents item-selection and delivery-location form' do
    sign_in FactoryBot.create(:happyuser)
    get recap_loan_path('101', '118')

    # Item Selection
    expect(response.body).to include( 'Please select one or more items' )
    # Specific barcodes should be listed
    expect(response.body).to include( 'CU08414130' )
    expect(response.body).to include( 'CU08414149' )
 
    # Delivery Location
    expect(response.body).to include( 'Please select campus delivery location' )
    # - specific delivery locations in drop-down menu
    expect(response.body).to include( 'Butler Library' )
    expect(response.body).to include( 'Health Sciences Library' )
  end
  
  
  it 'non-offsite bib gives error message' do
    sign_in FactoryBot.create(:happyuser)
    get recap_loan_path('123', '144')
    expect(response.body).to include( 'Bib ID 123 is not eligble for service Offsite Loan' )
  end


  it 'redirects blocked patron to failure page' do
    sign_in FactoryBot.create(:blockeduser)
    get recap_loan_path('101', '118')
    expect(response).to redirect_to( APP_CONFIG[:recap_loan][:ineligible_url] )
  end

end


