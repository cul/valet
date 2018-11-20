
RSpec.describe "Recall / Hold Request Service" do

  it "redirects to Voyager for checked-out item" do
    # Pick a bib that's extremely likely to be charged
    bib = '9041682'
    get recall_hold_path(bib)
    voyager_url = APP_CONFIG[:recall_hold][:voyager_url] + bib
    expect(response).to redirect_to(voyager_url)
  end

  it "renders error page for available item" do
    # Pick a bib that's extremely unlikely to be circulating
    bib = '3'
    get recall_hold_url(bib)
    expect(response.body).to include("All available copies of this bib are available")
  end

  it "renders error page for non-existant item" do
    # CLIO has no bib id 60
    get recall_hold_url('60')
    expect(response.body).to include("Cannot find bib record")
  end

end