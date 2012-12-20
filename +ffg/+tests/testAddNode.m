function test_suite = testAddNode()
%TESTADDNODE testing ffg.AddNode
initTestSuite;

function testForward
%TESTFORWARD case for forward message (the result knowing all summands)

    nwk = ffg.Network;
    node = ffg.AddNode;
    a = ffg.EvidenceNode;
    b = ffg.EvidenceNode;
    c = ffg.EvidenceNode;
    nwk.addEdge(a, node);
    nwk.addEdge(b, node);
    nwk.addEdge(node, c);
    
    msgA = ffg.gaussMessage(10, 5, 'VARIANCE');
    msgB = ffg.gaussMessage(20, 4, 'VARIANCE');
    
    a.propagate(msgA);
    b.propagate(msgB);

    EXPECTED_MEAN_C = msgA.mean + msgB.mean;
    EXPECTED_VAR_C = msgA.var + msgB.var;

    msg = c.evidence();
    assertEqual(size(msg.mean,2), 1);
    assertElementsAlmostEqual(msg.mean, EXPECTED_MEAN_C);
    assertElementsAlmostEqual(msg.var, EXPECTED_VAR_C);



function testBackward
%TESTFORWARD case for backward message (one of the summands knowing result)

    nwk = ffg.Network;
    node = ffg.AddNode;
    a = ffg.EvidenceNode;
    b = ffg.EvidenceNode;
    c = ffg.EvidenceNode;
    nwk.addEdge(a, node);
    nwk.addEdge(b, node);
    nwk.addEdge(node, c);

    
    msgC = ffg.gaussMessage(10, 5, 'VARIANCE');
    msgB = ffg.gaussMessage(20, 4, 'VARIANCE');
    
    c.propagate(msgC);
    b.propagate(msgB);

    EXPECTED_MEAN_A = msgC.mean - msgB.mean;
    EXPECTED_VAR_A = msgC.var + msgB.var;
    
    msg = a.evidence();
    assertEqual(size(msg.mean,2), 1);
    
    assertElementsAlmostEqual(msg.mean, EXPECTED_MEAN_A);
    assertElementsAlmostEqual(msg.var, EXPECTED_VAR_A);


