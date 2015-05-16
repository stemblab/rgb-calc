class Widget

    constructor: ->

    update: ->
        
    stringify: ->
        JSON.stringify(@spec)


class Sheet
    
    constructor: (@spec, @data, @colHeaders, @rowHeaders) ->

        @data ?= [[0]]
        numCols = @data[0].length
        numRows = @data.length

        @colHeaders ?= ("c#{k}" for k in [0...numCols])
        @rowHeaders ?= ("r#{k}" for k in [0...numRows])

    rowJson: ->
        x = {}
        x[rh] = @data[k] for rh, k in @rowHeaders
        return x

    labelRows: ->
        ([@rowHeaders[m]].concat row for row, m in @data)

    toLocal: ->
        eval("#{@spec.id} = $blab.sheet['#{@spec.id}'].data")

    fromLocal: (u)->
        $blab.sheet[@spec.id].data = u

    stringify: ->
        s = JSON.stringify(@spec)
        d = JSON.stringify(@data)
        r = JSON.stringify(@rowHeaders)
        c = JSON.stringify(@colHeaders)
        "{spec:#{s}, data:#{d}, rowHeaders:#{r}, colHeaders:#{c}}"



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
            data: @sheet.data
            afterChange: (change, source) =>
                compute() if source is "edit" and @spec.compute
            columns: ({type: 'numeric'} for k in [1..@sheet.data[0].length])
            rowHeaders: @sheet.rowHeaders
            colHeaders: @sheet.colHeaders
            contextMenu: false

        @table = new Handsontable container, $.extend({}, @defaults, @spec.table)

    update: ->
        @table.loadData @sheet.data
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
        @sheet.data[0][0] =  @slider.slider("value")
   
## From GUI

# sheets

$blab.sheet = []
sh = (id, data) -> new Sheet {id:id}, data #{id:id, data:data}

$blab.sheet["A"] = sh "A", [[1,2],[3,4]]

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

tab = (id) -> new Table {id:id, compute:true, table: {rowHeaders: false}}
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

console.log $blab.slider["z"].stringify()

# user code

compute = ()->

    ## pre-code

    # refresh sink sheets
    for sl of $blab.slider
        $blab.slider[sl].update()

    #console.log "z???", $blab.sheet["z"].data

    # local copy of vars 
    for sh of $blab.sheet
        #console.log "sh", sh
        $blab.sheet[sh].toLocal()

    ## user code

    fn = (A, x) ->
        A.dot x
    
    b = fn(A, x)

    q = y*z[0][0]

    #console.log "y", y

    #y = [[1, 2, 3, 4, 5, 6],[6, 5, 4, 3, 2, 1]]

    #console.log "y", y
    #console.log "q", q

    ## post code

    console.log "######## post-code ########"

    # update stuff

    for s of $blab.sheet
        $blab.sheet[s].fromLocal(eval(s))

    for t of $blab.table
        $blab.table[t].update()

    #console.log "blab-figure", $blab.figure
    for f of $blab.figure
        #console.log "start", f
        $blab.figure[f].update()
        #console.log "stop", f

compute()

