project 'SignalR.Client.ObjC/SignalR.Client.ObjC.xcodeproj'
workspace 'SignalR.Client.ObjC'

abstract_target "SignalR.Client.iOSModule" do
    use_frameworks!
    platform :ios, '10.0'
    
    pod 'AFNetworking', '4.0.1'
    pod 'SocketRocket', '0.5.1'
    
    target "SignalR.Client.iOS" do
    end
    
    target "SignalR.Client.iOSTests" do
        pod 'OCMock'
    end
end

abstract_target "SignalR.Client.OSXModule" do
    use_frameworks!
    platform :osx, '10.10'
    
    pod 'AFNetworking', '4.0.1'
    pod 'SocketRocket', '0.5.1'
    
    target "SignalR.Client.OSX" do
    end
    
    target "SignalR.Client.OSXTests" do
        pod 'OCMock'
    end
end
