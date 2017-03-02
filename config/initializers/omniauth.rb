# 
# # CUIT server setting here:
# #     http://cuit.columbia.edu/cas-authentication#Configuration_Options
# 
# Rails.application.config.middleware.use OmniAuth::Builder do
# 
#   provider :cas,
#     host: 'cas.columbia.edu',
#     login_url:  '/cas/login',
#     logout_url: '/cas/logout',
#     service_validate_url: '/cas/samlValidate'
#     # disable_ssl_verification: true
# 
# end
# 
# 
