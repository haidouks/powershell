function highChart_SplitLines($title,$subtitle,$categories,$series,$metric,$toolTip,$outputPath)
{
    $html = @"
<!DOCTYPE html>
<html>
<head>
<script type="text/javascript" src="C:\temp\jquery-3.1.1.min.js"></script>
<script type='text/javascript'>//<![CDATA[
`$(function () {
    Highcharts.chart('container', {
        title: {
            text: '$title',
            x: -20 //center
        },
        subtitle: {
            text: '$subtitle',
            x: -20
        },
        xAxis: {
            categories: $categories
        },
        yAxis: {
            title: {
                text: '$metric'
            },
            plotLines: [{
                value: 0,
                width: 1,
                color: '#808080'
            }]
        },
        tooltip: {
            valueSuffix: '$toolTip'
        },
        legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0
        },
        credits: {
            enabled: false
        },
        series: $series
    });
});
//]]> 

</script>
</head>
<body>
  <script src="https://code.highcharts.com/highcharts.js"></script>
  <script src="https://code.highcharts.com/modules/exporting.js"></script>
  <div id="container" style="min-width: 310px; height: 400px; margin: 0 auto"></div>
</body>
</html>
"@
    $html|out-file -FilePath $outputPath -Encoding utf8 -Force
}

write-host "Creating sample datas"
$categories = ("Jan","Feb","Mar") | ConvertTo-Json
$data1 = (2,15,5)
$data2 = (3,7,6)
$serie1 = @{
name = 'istanbul'
data = $data1
} 
$serie2 = @{
name = 'canakkale'
data = $data2
}
$series = New-Object System.Collections.ArrayList
$series.Add($serie1)
$series.Add($serie2)

highChart_SplitLines -title "Deneme - Title" -subtitle "Denem - subtitle" -categories $categories -series ($series|ConvertTo-Json) -metric "Temperature (°C)" -toolTip "°C" -outputPath C:\temp\asd.html
