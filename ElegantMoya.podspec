Pod::Spec.new do |s|

	s.name = 'ElegantMoya'
	s.version = '0.9'
	s.summary = 'Ganguo Network Kit In Swift'
	s.homepage = 'https://www.ganguotech.com/'
	s.license	 = { :type => "Copyright", :text => "Copyright 2019" }
	s.authors = { 'John' => 'john@ganguo.hk' }
	s.source = { :path => '/' }

	s.swift_version = "5.0"
	s.ios.deployment_target = "10.0"
	s.platform = :ios, '10.0'	
	s.source_files = "Source/**/*.swift"
	s.requires_arc = true
	s.default_subspec = 'Core'

	s.subspec 'Core' do |cs|	
		cs.dependency 'GGUI/Core'
		cs.dependency 'GGUI/MBProgressHUD'
		cs.dependency 'Moya'
		cs.dependency 'Cache'
		cs.source_files  = 'Source/Core/**/*.swift'
	end

	s.subspec 'Uploader' do |ss|
	    ss.dependency      'ElegantMoya/Core'
	    ss.dependency      'AlamofireImage'
	    ss.source_files  = 'Source/Uploader/*.swift'
	end

	s.subspec 'RefreshAndEmpty' do |ss|
	    ss.dependency      'ElegantMoya/Core'
	    ss.dependency      'GGUI/PullToRefreshKit'
	    ss.dependency      'DZNEmptyDataSet'
	    ss.source_files  = 'Source/RefreshAndEmpty/*.swift'
	end
end
