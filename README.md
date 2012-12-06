# factor-graph 
This project's goal is to create a MATLAB/C++ framework for inference on Forney-style factor graphs.

Currently only gaussian distributions are supported.


# Factor graphs

TODO: general description

# Example (MATLAB)

The example considered will be a simple Kalman Filter (available in `examples/kalmanFilter.m`).

```
x_n = x_{n-1} + e_n
y_n = x_n + u_n
```

First, we need to create factor nodes themselves:

```Matlab
% input from the previous step, unobserved
xin = ffg.EvidenceNode;
%
xout = ffg.EvidenceNode;
% 
n = ffg.EvidenceNode;
% observed variable
y = ffg.EvidenceNode;
e = ffg.EqualityNode;
a = ffg.AddNode;
u = ffg.EvidenceNode;
b = ffg.AddNode;
```

Then, we need to connect them as the model requires. In this framework, we can do that with `ffg.Network`.

```Matlab
% creating the network itself
nwk = ffg.Network;
% connecting edges
nwk.addEdge(xin, e);
nwk.addEdge(e, b);
nwk.addEdge(u, b);
nwk.addEdge(b, xout);
nwk.addEdge(a, y);
nwk.addEdge(n, a);
```

Note, that each connection is directed. For each call `nwk.addEdge(a,b)`, underneath we 
are adding an _outgoing_ connection to _a_ and _incoming_ to _b_. If we want to specify
another type of connection (which nodes should support!), we could use `nwk.addEdgeTagged(a,b,tagForA,tagForB)`.

Now, that we have our network, we need to specify the order in which the messages are being
propagated (schedule). Simply create a cell array with pairs of nodes:

```Matlab
schedule = {xin, e, n, a, y, a, a, e, e, b, u, b, b, xout};
nwk.setSchedule(schedule);
```

Then, initialisation with dummy messages (Gauss messages can be created with `ffg.gaussMessage(mean,var,type)`.

```Matlab
xout.receive(ffg.gaussMessage(1+randn()*sd, sd^2, 'VARIANCE'));
n.receive(ffg.gaussMessage(0, sd2, 'VARIANCE'));
u.receive(ffg.gaussMessage(1.0, 0, 'VARIANCE'));
```

Finally, adaptive filtering, by observing yet another evidence (`y.receive`),
and passing unobserved estimation to the next step. To make a single passing step (single schedule pass),
we call `nwk.makeStep`.

```Matlab
for i = 1:N_ITERATIONS
  xin.receive(msg);
  y.receive(struct('mean', samples(i), 'var',0, 'type', 'VARIANCE'));
  nwk.makeStep();         
  msg = xout.evidence();
end
```


# Extension (MATLAB)
The framework provides basic means for extension. If you want to define a custom node
representing arbitrary table (for now only for Gaussian messages), you can use `ffg.CustomNode`.
This class has method `setFunction`, that takes the name of the function implementing 
your logic.

The function should has three parameters: 
* `from`- double - sender id
* `to` - double - receiver id
* `msgs` - array of structs with fields:
    - `mean` - mean vector
	- `var` - variance matrix
	- `connection` - the type of connection 'INCOMING'|'OUTGOING'|'estimate'
	- `from` - the sender of the message
	- `type` - the type of the message 'VARIANCE'|'PRECISION'


An example of such a function is `examples/customnode_function_gauss.m`

# Development
The major part of the C++ codebase has lots of comments. The examples of how to use it can be
found [here](https://github.com/psycharo/factor-graph/tree/master/cpp-factor-graph/tests).

The base class for nodes is `FactorNode`. You will probably need to use one of the following 
fields to create your own nodes:
```
// the list of all nodes
std::map<int, FactorNode*> m_nodes;
// incoming connections
std::set<int> m_incoming;
// outgoing connections
std::set<int> m_outgoing;
// custom connections
std::map<int, std::string> m_connections;
```

`m_nodes` is contains all the nodes indexed by their ids. Every node has its own unique id that is stored 
in a static variable of `FactorNode`.

`m_incoming` and `m_outgoing` for each node contain ids of the nodes that
have an edge to the node with the corresponding direction; they are useful since most of the nodes
have only two types of connections (e.g. for addition factor node summands will be incoming 
connections, and the result will be an outgoing one). 

For other types of connections, `m_connections` should be used. It contains a list of connection tags (strings) indexed
by ids (the backward mapping (tag --> id) might be added later if necessary). An example of using
this would be `EstimateMultiplicationNode`, where an additional type of connection is necessary (`ESTIMATED_TAG`).

We did this so generic on purpose (and might generalize it a bit more). It allows nodes to be as independent as possible: nodes
are not aware of other node's types.

To create a node with custom behavior, one should provide own implementation of the node's function:
```c++
virtual GaussianMessage function(int to, const MessageBox &msgs) = 0;
```

It constructs a message to a specific node. To do that, we need only to know the receiver - `to` and 
the messages that have been received from node's connections `msgs`, which underneath is a map (id --> message). 




# TODO
* Gradient descent
* EM algorithm
* Variational Bayes
* ? discrete variables
