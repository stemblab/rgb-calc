


$("#widget-menu").menu select: (event, ui) ->
    console.log "ui type?", ui.item[0].innerHTML
    return

$("#tabs").tabs()


marked.setOptions
    renderer: new (marked.Renderer)
    gfm: true
    tables: true
    breaks: false
    pedantic: false
    sanitize: true
    smartLists: true
    smartypants: false

class Widget

    constructor: ->

    update: ->
        
    stringify: ->
        JSON.stringify(@spec)


class Markdown extends Widget

    constructor: (@spec) ->
    
        container = $("##{@spec.id}")
        container.html(marked(@spec.md))
        
        
class Sheet extends Widget
    
    constructor: (@spec) ->
        @spec.data ?= [[0]]
        @spec.colHeaders ?= ("c#{k}" for k in [0...@spec.data[0].length])
        @spec.rowHeaders ?= ("r#{k}" for k in [0...@spec.data.length])

    rowJson: ->
        x = {}
        x[rh] = @spec.data[k] for rh, k in @spec.rowHeaders
        return x

    labelRows: ->
        ([@spec.rowHeaders[m]].concat row for row, m in @spec.data)

    toLocal: ->
        eval("#{@spec.id} = $blab.sheet['#{@spec.id}'].spec.data")

    fromLocal: (u)->
        $blab.sheet[@spec.id].spec.data = u


class PlotXY extends Widget

    constructor: (@spec) ->
        @sheets = ($blab.sheet[id] for id in @spec.sheetIds)
        defaults = {}
        @chart = c3.generate(
            bindto: $("##{@spec.id}")[0]
            data: $.extend({}, defaults, @spec.data, @getCols())
        )

    getCols: ->
        cols = []
        cols.push c for c in sheet.labelRows() for sheet in @sheets
        columns: cols

    update: ->
        @chart.load(@getCols())

class Table extends Widget
    
    constructor: (@spec) ->

        randPos = (range, offset)->
            "#{Math.round((Math.random()*range+offset)*100)}%"
        @spec.x ?= randPos(0.8, 0.1)
        @spec.y ?= randPos(0.8, 0.1)
        
        @sheet = $blab.sheet[@spec.id]
        container = $("##{@spec.id}")
        container.append("<div class='hot'></div>")
        container.css("position", "absolute")
        #x = Math.round(Math.random()*100)
        #y = Math.round(Math.random()*100)
        container.css("left", @spec.x)
        container.css("top", @spec.y)

        hot = $("##{@spec.id} .hot")
        @defaults =
            data: @sheet.spec.data
            afterChange: (change, source) =>
                compute() if source is "edit" and @sheet.spec.compute
            columns: ({type: 'numeric'} for k in [1..@sheet.spec.data[0].length])
            rowHeaders: @sheet.spec.rowHeaders
            colHeaders: @sheet.spec.colHeaders
            contextMenu: false
        @table = new Handsontable hot[0], $.extend({}, @defaults, @spec)

    update: ->
        @table.loadData @sheet.spec.data
        @table.render()
        

class Slider extends Widget

    constructor: (@spec) ->

        @sheet = $blab.sheet[@spec.id]

        @container = $("##{@spec.id}")
        @container.append("<div class='slider'></div>")
        @container.append("<div class='label'></div>")
        @container.append("<input type='text' readonly class='report'>")
        @report = @container.find('.report')

        @container.draggable()
        @container.on 'drag', (event) =>
            $('#myInput').val event.pageX + ',' + event.pageY
            @spec.X = event.pageX
            @spec.Y = event.pageY

        defaults =
            width: 500
            value: 1
            min: 0
            max: 10
            step: 1
            change: (event, ui) =>
                @report.val ui.value
                compute()

        settings = $.extend({}, defaults, @spec)

        @container.find('.label').html(@sheet.spec.rowHeaders[0])
        @container.css("width", settings.width)

        @slider = @container.find('.slider')
        @slider.slider settings

        @report.val @slider.slider("value")

    update: ->
        @sheet.spec.data[0][0] =  @slider.slider("value")
   
## From GUI

# {"id":"A","data":[[1,2],[3,4]],"compute":true}

# sheets

$blab.sheet = []
sh = (id, data) ->
    new Sheet {id:id, data:data, compute: true}

$blab.sheet =
    A: sh "A", [[1,2],[3,4]]
    x: sh "x", [[5],[6]]
    b: sh "b", [[0],[0]]
    y: sh "y", [[30, 200, 100, 400, 150, 250],[50,  20,  10,  40,  15,  25]]
    z: sh "z", [[50]]
    q: sh "q", [[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0]]
    u: sh "u"
    x1: sh "x1", [[30, 50, 100, 230, 300, 310]]
    y1: sh "y1", [[30, 200, 100, 400, 150, 250], [130, 300, 200, 300, 250, 450]]

$blab.sheet['y'].spec.rowHeaders = []
$blab.sheet['y'].spec.colHeaders = []
$blab.sheet['y'].spec.rowHeaders = ['dA','dB']
$blab.sheet['y'].spec.colHeaders = ['i','ii','iii','iv','v','vi']

$blab.sheet['q'].spec.rowHeaders = ['one','two']
$blab.sheet['q'].spec.colHeaders = ['i','ii','iii','iv','v','vi']

# slider

slid = (id) -> new Slider
    id:id
    value: 3

console.log "???"

$blab.slider =
    z: slid "z"

console.log "!!!"

# tables

tab = (id) -> new Table {id:id, compute:true}
$blab.table =
    A: tab "A"
    x: tab "x"
    b: tab "b"
    y: tab "y"

# figures

fig1 =  -> new PlotXY
    id: "fig1"
    sheetIds: ["q"]
    data:
        x: ""
        types: 
            one: 'area'
            two: 'area-spline'

fig2 =  -> new PlotXY
    id: "fig2"
    sheetIds: ["x1", "q"]
    data:
        x: "r0"
        types: 
            one: 'spline'
            two: 'line'

$blab.figure =
    fig1: fig1()
    fig2: fig2()

# markdown

md = """

## markdown

*emphasis*

**bold**

~~strike~~

[marked + mathjax](http://kerzol.github.io/markdown-mathjax/editor.html)

```javascript
var s = "JavaScript syntax highlighting";
alert(s);
```

| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | centered      |   $12 |
| zebra stripes | are neat      |    $1 |


"""

markdn = -> new Markdown
    id: "content"
    md: md 

$blab.markdown =
    md1: markdn()

# user code


compute = ()->

    console.log "######## pre-code ########"

    # refresh sink
    for sl of $blab.slider
        $blab.slider[sl].update()
        console.log $blab.slider[sl].stringify()

    # local copy of vars 
    for sh of $blab.sheet
        $blab.sheet[sh].toLocal()

    console.log "######## user-code ########"

    fn = (A, x) ->
        A.dot x
    
    b = fn(A, x)

    q = y*z[0][0]

    console.log "######## post-code ########"

    console.log "#### sheets ####"
    for s of $blab.sheet
        $blab.sheet[s].fromLocal(eval(s))
        console.log $blab.sheet[s].stringify()

    console.log "#### tables ####"
    for t of $blab.table
        $blab.table[t].update()
        console.log $blab.table[t].stringify()

    console.log "#### figures ####"
    for f of $blab.figure
        $blab.figure[f].update()
        console.log $blab.figure[f].stringify()

    console.log "#### mardowns ####"
    for m of $blab.markdown
        #$blab.markdown[m].update()
        console.log $blab.markdown[m].stringify()


loadgist = (gistid, filename) ->
    $.ajax(
        url: "https://api.github.com/gists/#{gistid}"
        type: 'GET'
        dataType: 'jsonp').success((gistdata) ->
        content = gistdata.data.files[filename].content
        console.log "content???", content
        compute()
        return
    ).error (e) ->
        # ajax error
        return
    return

loadgist("f673df3f600fdeb17608", "gistfile1.json");




