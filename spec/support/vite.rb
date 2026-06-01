RSpec.configure do |config|
  config.before(:each, type: :request) do
    allow_any_instance_of(ActionView::Base).to receive(:vite_javascript_tag).and_return("".html_safe)
    allow_any_instance_of(ActionView::Base).to receive(:vite_stylesheet_tag).and_return("".html_safe)
    allow_any_instance_of(ActionView::Base).to receive(:vite_client_tag).and_return("".html_safe)
  end
end
