
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

class PlotXY

    constructor: (@spec) ->
        
        @spec.data["columns"] = @getCols() # c3-style data

        @chart = c3.generate(
            bindto: $("##{@spec.id}")[0]
            data: @spec.data
        )

    getCols: ->
        cols = []
        cols.push c for c in sheet.labelRows() for sheet in @spec.data.sheets
        columns: cols

    update: ->
        @chart.load(@getCols())

    stringify: ->
        JSON.stringify($blab.figure[@spec.id]["spec"])

class Table

    constructor: (@spec) ->

        sheet = $blab.sheet[@spec.id]

        data = sheet.data
        numRows = data.length
        numCols = data[0].length
        container = $("[data-sym=#{@spec.id}][data-type='table']")[0]

        @table = new Handsontable container,
            data: data
            startRows: numRows
            startCols: numCols
            rowHeaders: sheet.rowHeaders
            colHeaders: sheet.colHeaders 
            contextMenu: true
            columns: ({type: 'numeric'} for k in [1..numCols])
            afterChange: (change, source) =>
                compute() if source is "edit" and @spec.compute

    update: ->
        @table.loadData $blab.sheet[@spec.id].data
        @table.render()
        
    stringify: ->
        JSON.stringify($blab.table[@spec.id]["spec"])


class Slider

    constructor: (@spec) ->

        @spec.width ?= 500
        @spec.value ?= 1
        @spec.min ?= 0
        @spec.max ?= 10
        @spec.step ?= 1

        sheet = $blab.sheet[@spec.id]
        
        container = $("[data-sym=#{@spec.id}][data-type='slider']")
        container.css("width", @spec.width)
        container.append("<div class='slider'></div>")
        container.append("<div class='label'></div>")
        container.append("<input type='text' readonly class='report'>")

        label = container.find('.label')
        label.html(sheet.rowHeaders[0])

        report = container.find('.report')

        @slider = container.find('.slider')
        @slider.slider
            value: @spec.value
            min: @spec.min
            max: @spec.max
            step: @spec.step
            change: (event, ui) =>
                report.val ui.value
                compute() if @spec.compute
                
        report.val @slider.slider("value")

    update: ->
        $blab.sheet[@spec.id].data[0][0] =  @slider.slider("value")

    stringify: ->
        JSON.stringify($blab.slider[@spec.id]["spec"])
   
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
    width: 500
    value: 1
    min: 0
    max: 10
    step: 1
    compute: true

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
    data:
        sheets: [$blab.sheet["q"]]
        x: ""
        types: 
            one: 'area'
            two: 'area-spline'

fig2 =  -> new PlotXY
    id: "fig2"
    data:
        sheets: [$blab.sheet["x1"], $blab.sheet["q"]]
        x: "r0"
        types: 
            one: 'spline'
            two: 'line'

$blab.figure =
    fig1: fig1()
    fig2: fig2()


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

