# A sample Guardfile
# More info at http://github.com/guard/guard#readme
#

guard 'rspec' do
  watch('^spec/(.*)_spec.rb')
  watch('^lib/(.*)\.rb') { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('^lib/kns_email_endpoint/(.*)\.rb') { |m| "spec/kns_email_endpoint/lib/#{m[1]}_spec.rb" }
end

