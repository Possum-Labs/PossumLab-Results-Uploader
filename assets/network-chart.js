
var dotgraph = `
digraph {
    node [shape=box, fontsize=16, color=#edd9a3, fontcolor=black]
    edge [length=150, color=gray, fontcolor=black, color=#edd9a3]
  
    Ordered -> Canceled[label=""]; 
    Ordered -> Processed[label=""];
    Processed -> Canceled[label=""];
    Processed -> Shipped[label=""];
    Shipped -> Recieved[label=""];
    Recieved -> Returned[label=""];
    Unpaid -> Canceled[label="", color=#f2637f];
    Unpaid -> Pending[label=""];
    Pending -> Unpaid[label=""];
    Pending -> Paid[label="", color=#ca3c97];
    Paid -> Refunded[label="", color=#ca3c97];
  
    Paid[
      fontcolor=white,
      color=#ca3c97,
    ]
  
    Refunded [
      fontcolor=white,
      color=#ca3c97,
    ]
  
    Canceled [
      fontcolor=white,
      color=#f2637f,
    ]
    
  }
`;

$(window).load(draw);

var label = `
<div>
    <span class="ignored">
        <object 
        type="image/svg+xml" 
        data="repeat_five-24px.svg" 
        class="icon-24"
        fill="currentColor">
            5 repeat failures
        </object>
        1
    </span>

    <span class="repeatable">
        <i class="material-icons md-24">repeat_one</i>2
    </span>
    
    <span class="warning">
        <i class="material-icons md-24">warning</i>5
    </span>

    <span class="improve">
        <i class="material-icons md-24">trending_down</i>
    </span>
</div>
`;

var data = {};
var network = {};

function draw () {
    var container = document.getElementById('network-chart');
    var options = {
        physics: {
            stabilization: {
                enabled: true,
                iterations: 1000,
                updateInterval: 25
            },
            barnesHut: {
                springLength: 200
            }
        }
    };
    
    network = new vis.Network(container, data, options);

    try {
      $('#error').html('');

      // Provide a string with data in DOT language
      data = vis.parseDOTNetwork(dotgraph);
      network.on("stabilizationIterationsDone", positionLabels);
      network.setData(data);
      
    }
    catch (err) {
      // show an error message
      $('#error').html(err.toString());
    }
 
    
  }

function positionLabels(sender)
{
    data.nodes.forEach(element => {
        positionNodeLabel(element.id+"-Stats", element.id);
    });
    data.edges.forEach(element => {
        console.log(element.from+"-"+element.from+"-Stats");
        positionEdgeLabel(element.from+"-"+element.from+"-Stats", element.id);
    });
}


function positionNodeLabel(labelId, nodeId)
{
    var { x: nodeX, y: nodeY } = network.canvasToDOM(
        network.getPositions([nodeId])[nodeId]
      );
    positionLabel(labelId, nodeX, nodeY)
}

function positionEdgeLabel(labelId, nodeId)
{
    var { x: edgeX, y: edgeY } = network.canvasToDOM(
        network.getPositions([nodeId])[nodeId]
      );
    positionLabel(labelId, edgeX, edgeY)
}

function positionLabel(labelId, x, y)
{
    var e = document.getElementById(labelId);

    e.style.position = "absolute";
    e.style.top = y + "px";
    e.style.left = x + "px";
  
}