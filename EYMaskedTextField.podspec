Pod::Spec.new do |spec|
  spec.name               = 'EYMaskedTextField'
  spec.version            = '0.1.1'
  spec.summary            = 'UITextField with customizable input mask.'
  spec.homepage           = 'https://github.com/seaburg/EYMaskedTextField'
  spec.license            =  { :type => "MIT", :file => "LICENSE" }
  spec.author             =  { "Evgeniy Yurtaev" => "evgeniyyurt@gmail.com" }
  spec.source             =  { :git => 'https://github.com/seaburg/EYMaskedTextField.git', :tag => '0.1.1' }
  spec.source_files       = 'EYMaskedTextField/*'
  spec.platform           = :ios, "6.0"
  spec.requires_arc       = true
end
