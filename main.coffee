class Widget

    constructor: ->

    update: ->
        
    stringify: ->
        JSON.stringify(@spec)


class Sheet extends Widget
    
    constructor: (@spec) ->

        @spec.data ?= [[0]]
        @colHeaders ?= ("c#{k}" for k in [0...@spec.data[0].length])
        @rowHeaders ?= ("r#{k}" for k in [0...@spec.data.length])

    rowJson: ->
        x = {}
        x[rh] = @spec.data[k] for rh, k in @rowHeaders
        return x

    labelRows: ->
        ([@rowHeaders[m]].concat row for row, m in @spec.data)

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

        @sheet = $blab.sheet[@spec.id]
        container = $("[data-sym=#{@spec.id}][data-type='table']")[0]

        @defaults =
            data: @sheet.spec.data
            afterChange: (change, source) =>
                compute() if source is "edit" and @sheet.spec.compute
            columns: ({type: 'numeric'} for k in [1..@sheet.spec.data[0].length])
            rowHeaders: @sheet.rowHeaders
            colHeaders: @sheet.colHeaders
            contextMenu: false

        @table = new Handsontable container, $.extend({}, @defaults, @spec)

    update: ->
        @table.loadData @sheet.spec.data
        @table.render()
        

class Slider extends Widget

    constructor: (@spec) ->

        @sheet = $blab.sheet[@spec.id]

        @container = $("[data-sym=#{@spec.id}][data-type='slider']")
        @container.append("<div class='slider'></div>")
        @container.append("<div class='label'></div>")
        @container.append("<input type='text' readonly class='report'>")
        @report = @container.find('.report')

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
    
        @container.find('.label').html(@sheet.rowHeaders[0])
        @container.css("width", settings.width)
        
        @slider = @container.find('.slider')
        @slider.slider settings

        @report.val @slider.slider("value")

    update: ->
        @sheet.spec.data[0][0] =  @slider.slider("value")
   
## From GUI

# sheets

$blab.sheet = []
sh = (id, data) -> new Sheet {id:id, data:data, compute: true}

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

$blab.sheet['y'].rowHeaders = ['dA','dB']
$blab.sheet['y'].colHeaders = ['i','ii','iii','iv','v','vi']

$blab.sheet['q'].rowHeaders = ['one','two']
$blab.sheet['q'].colHeaders = ['i','ii','iii','iv','v','vi']

# slider

slid = (id) -> new Slider
    id:id
    value: 3

$blab.slider =
    z: slid "z"

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

# user code


compute = ()->

    console.log "######## pre-code ########"

    # refresh sink sheets
    for sl of $blab.slider
        $blab.slider[sl].update()

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

compute()

