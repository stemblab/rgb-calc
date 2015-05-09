
# A BlabSheet is an array of data augmented with row and column names
# (i.e., how spreadsheets look. Better name?). If row/col names aren't
# given, defaults are applied. Data can be extracted by various
# methods: for instance, JSON data with the row headings as keys
# (rowJson). The data provided by the methods is suitable for
# digestion by other table/plotting classes.

class BlabSheet
    
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

    
# BlabC3 is a convenience wrapper for c3.js; it takes a BlabSheet as
# its argument. There are various other charting libraries (nvd3 for
# d3.js) and these can be simularly wrapped.

class BlabC3

    constructor: (@sheet) ->

        @chart = c3.generate(
          bindto: '#chart'
          data: json: @sheet.rowJson()
          )

    load: ->
        @chart.load(json: @sheet.rowJson())


# BlabHandsontable = wrapper for handsontable.js

class BlabHandsontable
    
    constructor: (@spec) ->

        @sheet = @spec.sheet
        @data = @sheet.data

        @table = new Handsontable $("#"+@spec.id)[0],
            data: @data
            startRows: @data.length
            startCols: @data[0].length
            rowHeaders: @sheet.rowHeaders
            colHeaders: @sheet.colHeaders 
            contextMenu: true
            columns: ({type: 'numeric'} for k in [1..@data[0].length])

    render: -> @table.render()
        
    setData: (data) ->
        @table.loadData data
        @render()
        
    afterChange: (@callback) ->
        @table.addHook 'afterChange', => @callback()


class BlabSlider

    constructor: (@sheet, @spec) ->

        @container = $("#"+@spec.id)
        @container.css("width", @spec.width)

        @container.append("<div class='slider'></div>")
        @slider = @container.find('.slider')

        @container.append("<div class='label'></div>")
        @label = @container.find('.label')
        @label.html(@sheet.rowHeaders[0])

        @container.append("<input type='text' readonly class='report'>")
        @report = @container.find('.report')

        @slider.slider
            value: 100
            min: 0
            max: 500
            step: 50
            slide: (event, ui) =>
                @report.val ui.value
                @sheet.data[0][0] = ui.value
                
        @report.val @slider.slider('value')

   
## From GUI

# sheets

sh = (id, data) -> new BlabSheet {id:id, data:data}
$blab.sheet =
    A: sh "A", [[1,2],[3,4]]
    x: sh "x", [[5],[6]]
    b: sh "b", [[0],[0]]
    y: sh "y", [[30, 200, 100, 400, 150, 250],[50,  20,  10,  40,  15,  25]]
    z: sh "z", [[50]]

$blab.sheet['y'].rowHeaders = ['dA','dB']
$blab.sheet['y'].colHeaders = ['i','ii','iii','iv','v','vi']

# slider

$blab.slider = []
$blab.slider["z"] = new BlabSlider $blab.sheet["z"], {id: "z", width: 500}

# tables

tab = (id) -> new BlabHandsontable {sheet:$blab.sheet[id], id:id}
$blab.table =
    A: tab "A"
    x: tab "x"
    b: tab "b"
    y: tab "y"

# figures

$blab.figure = []  
$blab.figure['y'] = new BlabC3 $blab.sheet['y'] 

# slider

$blab.slider = []

    
## user coffeescript

# For convenience

sheet = $blab.sheet
table = $blab.table
figure = $blab.figure
for s, d of sheet
    eval(s + " = sheet['" + s + "'].data") # !!! local vars !!!

# User code
fn = (A, x) ->
    A.dot x
    
compute = ->
    b = fn(A, x)
    table['b'].setData b

compute()

# table updates
table['A'].afterChange (-> compute())
table['x'].afterChange (-> compute())
table['y'].afterChange (-> figure['y'].load())
