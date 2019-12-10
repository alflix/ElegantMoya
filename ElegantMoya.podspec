Pod::Spec.new do |s|

	s.name                  = 'ElegantMoya'
	s.version               = '0.9'
	s.summary               = 'Ganguo Network Kit In Swift'
	s.homepage              = 'https://github.com/alflix/ElegantMoya'
	s.license               = { :type => 'Apache-2.0', :file => 'LICENSE' }
	s.authors               = { 'John' => 'jieyuanz24@gmail.com' }
	s.source                = { :path => '/' }
	
	s.swift_version         = "5.1"
	s.ios.deployment_target = "9.0"
	s.platform              = :ios, '9.0'	
	s.requires_arc          = true
	s.default_subspec 		= 'Core'

	s.subspec 'Core' do |cs|
        cs.dependency 	'Moya'
        cs.dependency 	'Cache'
		cs.dependency 	'MBProgressHUD'
		cs.source_files = 'Source/Core/**/*.swift'
	end

	s.subspec 'RefreshAndEmpty' do |ss|
	    ss.dependency      'ElegantMoya/Core'
        ss.dependency      'GGUI'
	    ss.dependency      'PullToRefreshKit'
	    ss.dependency      'DZNEmptyDataSet'
	    ss.source_files    = 'Source/RefreshAndEmpty/**/*.swift'
	end
end
