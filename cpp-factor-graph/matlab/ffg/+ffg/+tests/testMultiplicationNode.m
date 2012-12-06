function test_suite = testMultiplicationNode
initTestSuite;

function testForward

DIM = 3;

nwk = ffg.Network;
x = ffg.EvidenceNode;
y = ffg.EvidenceNode;

MATRIX = randn(DIM, DIM);
A = ffg.MultiplicationNode;
A.setMatrix(MATRIX);

nwk.addEdge(x, A);
nwk.addEdge(A, y);

% input
INPUT_MSG = ffg.gaussMessage(randn(1, DIM), randn(DIM, DIM), 'VARIANCE');
%

x.propagate(INPUT_MSG);

RESULT_MSG = y.evidence();

MEAN_EXPECTED = MATRIX * INPUT_MSG.mean';
VAR_EXPECTED = MATRIX * INPUT_MSG.var * MATRIX';


assertElementsAlmostEqual(RESULT_MSG.mean', MEAN_EXPECTED);
assertElementsAlmostEqual(RESULT_MSG.var, VAR_EXPECTED);

function testBackward

DIM = 3;

nwk = ffg.Network;
x = ffg.EvidenceNode;
y = ffg.EvidenceNode;

MATRIX = randn(DIM, DIM);
A = ffg.MultiplicationNode;
A.setMatrix(MATRIX);

nwk.addEdge(x, A);
nwk.addEdge(A, y);

% for now backward message only supports mean
INPUT_MSG = ffg.gaussMessage(randn(1, DIM), randn(DIM, DIM), 'VARIANCE'); 

y.propagate(INPUT_MSG);

RESULT_MSG = x.evidence();

VAR_EXPECTED = inv(MATRIX' * inv(INPUT_MSG.var) * MATRIX);
MEAN_EXPECTED = VAR_EXPECTED * MATRIX' * inv(INPUT_MSG.var) * INPUT_MSG.mean';

assertElementsAlmostEqual(RESULT_MSG.mean', MEAN_EXPECTED);
assertElementsAlmostEqual(RESULT_MSG.var, VAR_EXPECTED);




    
    
