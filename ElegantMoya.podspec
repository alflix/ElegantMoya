Pod::Spec.new do |s|

	s.name = 'ElegantMoya'
	s.version = '0.9'
	s.summary = 'Ganguo Network Kit In Swift'
	s.homepage = 'https://www.ganguotech.com/'
	s.license	 = { :type => "Copyright", :text => "Copyright 2019" }
	s.authors = { 'John' => 'jieyuanz24@gmail.com' }
	s.source = { :path => '/' }

	s.swift_version = "5.1"
	s.ios.deployment_target = "9.0"
	s.platform = :ios, '9.0'	
	s.requires_arc = true
	s.default_subspec = 'Core'

	s.subspec 'Core' do |cs|
        cs.dependency 'Moya'
        cs.dependency 'Cache'
		cs.dependency 'MBProgressHUD+Ganguo'
		cs.source_files  = 'Source/Core/**/*.swift'
	end

	s.subspec 'Uploader' do |ss|
	    ss.dependency      'ElegantMoya/Core'
	    ss.dependency      'AlamofireImage'
	    ss.source_files  = 'Source/Uploader/*.swift'
	end

	s.subspec 'RefreshAndEmpty' do |ss|
	    ss.dependency      'ElegantMoya/Core'
        ss.dependency      'GGUI'
	    ss.dependency      'PullToRefreshKit'
	    ss.dependency      'DZNEmptyDataSet'
	    ss.source_files  = 'Source/RefreshAndEmpty/**/*.swift'
	end
end
