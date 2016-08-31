
require 'fog'
require 'open-uri'


$envs = ['dev', 'integration', 'qa', 'staging', 'production']

def get_env(environment)

	return environments.find("name:#{environment}").first
end 


def deploy_integration(environment)
    
	time =  Time.new.strftime("%Y%m%d%H%M%S")

	@client = Fog::Storage.new(
	  :provider => '',
	  :rackspace_username => '',
	  :rackspace_api_key => '',
	  :rackspace_region => 'LON'
	)

	filename =  'site-' + time + '.tar.gz' 
	giturl = 'https://api.github.com/repos/kash999/site/tarball/master'
    
  #download and upload to rs files
  
	d = @client.directories.get('site-data')
	open(giturl,"Authorization" => 'token xxxxxxxxxxxxxxx') do |uri|
	    	 d.files.create(:key => filename, :body => uri.read)
	end

    puts "#{filename} uploaded ...... site to rs"
	env =  get_env(environment)
	env.default_attributes['apps']['site'] = filename
	env.save

	run_chef(environment)
end

# simple multi thread to run chef client on given nodes
# requie knife on server with ssh 
def run_chef(environment)
	nodes.find("recipe:site AND chef_environment:#{environment}").each do |n|
    	puts "chef client runing on #{environment} - "  + n.ipaddress
    	Thread.new { %x[ ssh "#{n.ipaddress}" 'sudo chef-client'] }
    end
end

def deploy_to_rest(environment)

   penv =  get_env($envs[$envs.index(environment)-1])
   cenv =  get_env(environment)
   
   if penv.default_attributes['apps']['site'] != cenv.default_attributes['apps']['site'] or cenv.default_attributes['apps'][site'].nil? 
   	  cenv.default_attributes['apps']['site'] = penv.default_attributes['apps'][site']
   	  cenv.save
   	  run_chef(environment)
      puts "done update #{environment}" 
   end  
end

if ARGV[2].nil?
    puts "please specify any environment"
    exit 1
end

denv = ARGV[2]
chk_forced = ARGV[3]

if $envs.include?(denv)

    if denv and chk_forced == 'forced'
    	deploy_integration(denv)
    elsif denv == 'integration' 
       deploy_integration('integration')
    else
       deploy_to_rest(denv)
    end 
    
end

exit 0
