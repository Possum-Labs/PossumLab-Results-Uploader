var MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
var config = {
    type: 'line',
    data: {
        labels: ['5/8', '5/11', '5/12', '5/13', '5/14', '5/15', '5/18'],
        datasets: [{
            label: 'Ignored failures',
            borderColor: '#ca3c97',
            backgroundColor: '#ca3c97',
            data: [
                0,
                0,
                1,
                2,
                0,
                0,
                2
            ],
        }, {
            label: 'Reproduced failures',
            borderColor: '#f2637f',
            backgroundColor: '#f2637f',
            data: [
                3,
                8,
                6,
                2,
                4,
                2,
                1
            ],
        }, {
            label: 'New failures',
            borderColor: '#f79c79',
            backgroundColor: '#f79c79',
            data: [
                23,
                43,
                35,
                37,
                41,
                29,
                47
            ],
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        title: {
            display: false,
            text: ''
        },
        tooltips: {
            mode: 'index',
        },
        hover: {
            mode: 'index'
        },
        scales: {
            xAxes: [{
                scaleLabel: {
                    display: true,
                    labelString: 'Date'
                }
            }],
            yAxes: [{
                stacked: true,
                scaleLabel: {
                    display: true,
                    labelString: 'Count'
                }
            }]
        }
    }
};

window.onload = function () {
    var ctx = document.getElementById('historic-chart').getContext('2d');
    window.myLine = new Chart(ctx, config);
};

$(function () { $('#path-results').jstree(); });
