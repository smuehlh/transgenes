Chart.defaults.global.legend.display = false;
Chart.defaults.global.animation = false;
Chart.defaults.global.tooltips.displayColors = false;
Chart.defaults.global.elements.point.backgroundColor = "rgb(51, 122, 183)"; // Bootstrap primary color
Chart.defaults.line.showLines = false;
var chartOptions = {
    scales: {
        xAxes: [{
            gridLines: {
                display: false,
                color: "rgba(0, 0, 0, 0.5)"
            },
            scaleLabel: {
                display: true,
                labelString: 'Position in Gene (codons)'
            }
        }],
        yAxes: [{
            gridLines: {
                display: false,
                color: "rgba(0, 0, 0, 0.5)"
            },
            scaleLabel: {
                display: true,
                labelString: '% GC3'
            }
        }]
    },
    tooltips: {
        enabled: true,
        mode: 'single',
        callbacks: {
            label: function(tooltipItems, data) {
                return tooltipItems.yLabel.toFixed(2) + '% GC3';
            },
            title: function(tooltipItems, data) {
                return 'Pos ' + tooltipItems[0].xLabel;
            },
        }
    }
};