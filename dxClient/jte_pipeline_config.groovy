libraries {
    kubernetes
    git
    dxclient {
        hostname = 'mock-dx-server.dxclient-test.svc.cluster.local'
        dxUsername = credentials('dx-test-username')
        dxPassword = credentials('dx-test-password')
        dxProtocol = 'http'
        dxPort = '9080'
    }
}
