
class BlabSymbol
    
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

    rowData: ->
        x = {}
        y = $blab.sym['y']
        x[rh] = @data[k] for rh, k in @rowHeaders
        return x


class BlabTable
    
    constructor: (@spec) ->

        @sym = @spec.sym
        @data = @sym.data

        @table = new Handsontable $("#"+@spec.id)[0],
            data: @data
            startRows: @data.length
            startCols: @data[0].length
            rowHeaders: @sym.rowHeaders
            colHeaders: @sym.colHeaders 
            contextMenu: true
            columns: ({type: 'numeric'} for k in [1..@data[0].length])

    render: -> @table.render()
        
    setData: (data) ->
        @table.loadData data
        @render()
        
    afterChange: (@callback) ->
        @table.addHook 'afterChange', => @callback()


class BlabFigure

    constructor: (@sym) ->
        
        @chart = c3.generate(
          bindto: '#chart'
          data: json: @sym.rowData()
          )

    load: ->
        @chart.load(json: @sym.rowData())
        

## From GUI

# symbols

symbol = (id, data) -> new BlabSymbol {id:id, data:data}
$blab.sym =
    A: symbol "A", [[1,2],[3,4]]
    x: symbol "x", [[5],[6]]
    b: symbol "b", [[]]
    y: symbol "y", [[30, 200, 100, 400, 150, 250],[50,  20,  10,  40,  15,  25]]

$blab.sym['y'].rowHeaders = ['dA','dB']
$blab.sym['y'].colHeaders = ['i','ii','iii','iv','v','vi']

# tables

table = (id) -> new BlabTable {sym:$blab.sym[id], id:id}
$blab.tab =
    A: table "A"
    x: table "x"
    b: table "b"
    y: table "y"

# figures

$blab.fig = []  
$blab.fig['fig1'] = new BlabFigure $blab.sym['y'] 
$blab.sym['y'].data = [[30, 200, 100, 0, 150, 250],[50,  20,  10,  40,  15,  25]]
$blab.fig['fig1'].load()
    
## user coffeescript

# For convenience

sym = $blab.sym
tab = $blab.tab

#A = sym['A'].data
#x = sym['x'].data
#b = sym['b'].data

#console.log sym
for s, d of sym
    eval(s + " = sym['" + s + "'].data")

# User code
fn = (A, x) ->
    A.dot x
    
compute = ->
    b = fn(A, x)
    tab['b'].setData b

# Auto-compute after changing A and x
tab['A'].afterChange (-> compute())
tab['x'].afterChange (-> compute())

compute()





