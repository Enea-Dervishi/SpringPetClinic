agent{
  checkoutSCM()
  dxclient.xmlaccess {
        hostname = 'mock-dx-server.dxclient-test.svc.cluster.local'
        dxUsername = credentials('dx-test-username')
        dxPassword = credentials('dx-test-password')
        dxProtocol = 'http'
        dxPort = '9080'
        xmlFile = '/tmp/test-config.xml'
        stageName = 'Test XMLAccess'
  }
  dxclient.deploy_application {
    hostname = 'mock-dx-server.dxclient-test.svc.cluster.local'
    dxUsername = credentials('dx-test-username')
    dxPassword = credentials('dx-test-password')
    dxProtocol = 'http'
    dxPort = '9080'
    applicationFile = '/tmp/test.ear'
    applicationName = 'TestApp'
    stageName = 'Test Deploy Application'
  }
  dxclient.deploy_theme {
    hostname = 'mock-dx-server.dxclient-test.svc.cluster.local'
    dxUsername = credentials('dx-test-username') 
    dxPassword = credentials('dx-test-password')
    dxProtocol = 'http'
    dxPort = '9080'
    themeName = 'TestTheme'
    themePath = '/tmp/themes/TestTheme'
    stageName = 'Test Deploy Theme'
  }
}
