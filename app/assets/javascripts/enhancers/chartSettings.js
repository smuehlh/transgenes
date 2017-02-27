Chart.defaults.global.legend.display = false;
Chart.defaults.global.animation = false;
Chart.defaults.global.elements.point.backgroundColor = "rgb(51, 122, 183)"; // Bootstrap primary color
var chartOptions = {
    scales: {
        xAxes: [{
            gridLines: {
                display: false,
                color: "rgba(0, 0, 0, 0.5)"
            }
        }],
        yAxes: [{
            gridLines: {
                display: false,
                color: "rgba(0, 0, 0, 0.5)"
            }
        }]
    }
};