$(function() {
  var MAX_RPS = 4001;
  var MIN_RPS = 800;
  var MIN_CONNECTIONS = 7;
  var MAX_CONNECTIONS = 14;
  var MAX_SR = 100;
  var MIN_SR = 99.991;

  var chartDefaults = {
    millisPerPixel: 60,
    grid: {
      fillStyle: '#fff',
      strokeStyle: '#BFC0CA',
      millisPerLine: 10000,
    },
    labels: {
      fillStyle: '#878787',
      fontSize: 10,
      fontFamily: 'Lato',
      precision: 0
    },
    minValue: 500,
    timestampFormatter:SmoothieChart.timeFormatter
  }

  var $connections = $("td.connections-metric-sum");
  var $requests = $("td.requests-metric-sum");
  var $successRate = $("td.success-metric");
  var $barChart = $(".overlay-bars.bar");
  var $barChartLabel = $(".budget-used");

  var canvas = document.getElementById('linkerd-demo');
  var chart = new SmoothieChart(chartDefaults);

  chart.streamTo(canvas, 2000);
  setInterval(generateRandomData, 2000);

  var requests1 = new TimeSeries();
  var requests2 = new TimeSeries();
  chart.addTimeSeries(requests1, {lineWidth:2,strokeStyle:'#005CFE'});
  chart.addTimeSeries(requests2, {lineWidth:2,strokeStyle:'#0EE290'});

  // Build some initial data so the chart doesn't load empty
  var endTime = Date.now();
  for (var i = 0; i < 10; i++) {
    requests1.append(new Date(endTime - i*3000), randomStat(MIN_RPS, MAX_RPS));
    requests2.append(new Date(endTime - i*3000), randomStat(MIN_RPS, MAX_RPS));
  }

  function generateRandomData() {
    var timestamp = new Date().getTime();

    // requests
    var requests1val = randomStat(MIN_RPS, MAX_RPS);
    var requests2val = randomStat(MIN_RPS, MAX_RPS);
    requests1.append(timestamp, requests1val);
    requests2.append(timestamp, requests2val);
    $requests.text(requests1val + requests2val);

    // connections
    var connections1 = randomStat(MIN_CONNECTIONS, MAX_CONNECTIONS);
    var connections2 = randomStat(MIN_CONNECTIONS, MAX_CONNECTIONS);
    $connections.text(connections1 + connections2);

    // success rate
    $successRate.text(randomStat(99991, 100000) / 1000 + "%");

    // retry budget
    var retryBudgetAvailable = randomStat(15, 20);
    $barChart.width(Math.round(retryBudgetAvailable / 20 * 100) + "%");
    $barChartLabel.text(retryBudgetAvailable + "%");
  }

  function randomStat(min, max) {
    return Math.floor(Math.random() * (max - min) + min);
  }
});
