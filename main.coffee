
# A Sheet is an array of data augmented with row and column names
# (i.e., how spreadsheets look. Better name?). If row/col names aren't
# given, defaults are applied. Data can be extracted by various
# methods: for instance, JSON data with the row headings as keys
# (rowJson). The data provided by the methods is suitable for
# digestion by other table/plotting classes.

class Sheet
    
    constructor: (@spec) ->

        @data = @spec.data

        if @spec.colHeaders?
            @colHeaders = @spec.colHeaders
        else
            @colHeaders = ('c'+k for k in [0...@data[0].length])

        if @spec.rowHeaders?
            @rowHeaders = @spec.rowHeaders
        else
            @rowHeaders = ('r'+k for k in [0...@data.length])

    rowJson: ->
        x = {}
        x[rh] = @data[k] for rh, k in @rowHeaders
        return x

    toLocal: ->
        eval(@spec.id + " = $blab.sheet['" + @spec.id + "'].data")

    fromLocal: ->
        console.log "???", "$blab.sheet['" + @spec.id + "'].data = " + @spec.id
        eval("$blab.sheet['" + @spec.id + "'].data = " + @spec.id)
    

class Plot

    constructor: (@spec) ->

        @sheet = $blab.sheet[@spec.id]

        @chart = c3.generate(
          bindto: $("[data-sym=#{@spec.id}][data-type='figure']")[0]
          data: json: @sheet.rowJson()
        )

    update: ->
        @chart.load(json: @sheet.rowJson())


class Table
    
    constructor: (@spec) ->

        @sheet = $blab.sheet[@spec.id]
        @data = @sheet.data

        @table = new Handsontable $("[data-sym=#{@spec.id}][data-type='table']")[0],
            data: @data
            startRows: @data.length
            startCols: @data[0].length
            rowHeaders: @sheet.rowHeaders
            colHeaders: @sheet.colHeaders 
            contextMenu: true
            columns: ({type: 'numeric'} for k in [1..@data[0].length])
            afterChange: (change, source) ->
                compute() if source is "edit"

    update: ->
        @data = @sheet.data
        @table.loadData @data
        @table.render()
        

class Slider

    constructor: (@sheet, @spec) ->
        
        @container = $("[data-sym=#{@spec.id}][data-type='slider']")
        @container.css("width", @spec.width)

        @container.append("<div class='slider'></div>")
        @slider = @container.find('.slider')

        @container.append("<div class='label'></div>")
        @label = @container.find('.label')
        @label.html(@sheet.rowHeaders[0])

        @container.append("<input type='text' readonly class='report'>")
        @report = @container.find('.report')

        @slider.slider
            value: 1
            min: 0
            max: 10
            step: 1
            slide: (event, ui) =>
                @report.val ui.value
                compute()
                
        @report.val @slider.slider('value')

    update: ->
        $blab.sheet[@spec.id].data[0][0] = @slider.slider('value')

   
## From GUI

# sheets

sh = (id, data) -> new Sheet {id:id, data:data}
$blab.sheet =
    A: sh "A", [[1,2],[3,4]]
    x: sh "x", [[5],[6]]
    b: sh "b", [[0],[0]]
    y: sh "y", [[30, 200, 100, 400, 150, 250],[50,  20,  10,  40,  15,  25]]
    z: sh "z", [[50]]
    q: sh "q", [[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0]]

$blab.sheet['y'].rowHeaders = ['dA','dB']
$blab.sheet['y'].colHeaders = ['i','ii','iii','iv','v','vi']

# slider

slid = (id) -> new Slider $blab.sheet[id], {id:id , width: 500}
$blab.slider =
    z: slid "z"

# tables

tab = (id) -> new Table {id:id}
$blab.table =
    A: tab "A"
    x: tab "x"
    b: tab "b"
    y: tab "y"

# figures

fig = (id) -> new Plot {id:id}

$blab.figure =
    q: fig "q"

# user code

compute = ()->

    ## pre-code

    # refresh sink sheets
    for sl of $blab.slider
        $blab.slider[sl].update()

    # local copy of vars 
    for sh of $blab.sheet
        $blab.sheet[sh].toLocal()

    ## user code

    fn = (A, x) ->
        A.dot x
    
    b = fn(A, x)

    q = y*z[0][0]

    ## post code

    # update stuff
    # 
    for s of $blab.sheet
        eval("$blab.sheet['" + s + "'].data = " + s)
        #$blab.sheet[s].fromLocal()

    for t of $blab.table
        $blab.table[t].update()

    for f of $blab.figure
        $blab.figure[f].update()

compute()

