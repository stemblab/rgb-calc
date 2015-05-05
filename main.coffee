
# Browser creates a Symbol object.  A symbol could be a table (with
# headers) or a matrix, or some array of numeric(?) data. The
# important attributes of a Symbol are its data and view. Symbol.data
# is an Array object. Symbol.view is a displayed object in the DOM
# (e.g., handontable).

class Symbol
    
    constructor: (@id, @data) ->
        
        @view = new Handsontable $("#"+@id)[0],
            data: @data
            startRows: @data.length
            startCols: @data[0].length
            rowHeaders: true
            colHeaders: true 
            contextMenu: true
            columns: ({type: 'numeric'} for k in [1..@data[0].length])
        
        @view.afterChange = => @change() if @change 
            
    render: -> @view.render()
        
    setData: (data) ->
        @view.loadData data
        @render()
        
    afterChange: (@callback) ->
        @view.addHook 'afterChange', => @callback()

# From GUI
symbol = (id, data) -> new Symbol id, data
$blab.sym =
    A: symbol "A", [[1,2],[3,4]]
    x: symbol "x", [[5],[6]]
    b: symbol "b", [[]]

# In user coffeescript

# For convenience
sym = $blab.sym
A = sym['A'].data
x = sym['x'].data
b = sym['b'].data

# User code
fn = (A, x) ->
    A.dot x
    
compute = ->
    b = fn(A, x)
    sym['b'].setData b

# Auto-compute after changing A and x
sym['A'].afterChange (-> compute())
sym['x'].afterChange (-> compute())

# compute from browser
#$("#comp").on "click", => compute()

compute()


#---------------------SCRAP---------------------------------#


###
class Table

    constructor: (@spec) ->

        @hot = $(@spec.id).handsontable
            data: @spec.data
            startRows: @spec.data.length
            startCols: @spec.data[0].length
            rowHeaders: true
            colHeaders: true 
            contextMenu: true

    render: ->

        $(@spec.id).handsontable('getInstance').render()



data = []
table = []

data['A'] = [[1,2],[3,4]]
data['x'] = [[5],[6]]
data['b'] = [[]]

table['A'] = new Table {id:"#A", data:data['A']}
table['x'] = new Table {id:"#x", data:data['x']}
table['b'] = new Table {id:"#b", data:data['b']}
b = data['A'].dot data['x']
#data['b'] = b
data['b'][0] = b[0]
data['b'][1] = b[1] 
table['b'].render()
###

    
###        

Array::table = (spec) ->
    $(spec.id).handsontable({
    data: this
    startRows: this[0].length,
    startCols: this.length,
    minRows: 1,
    minCols: 1,
    rowHeaders: true,
    colHeaders: spec.colHeaders,
    minSpareRows: 0,
    contextMenu: true
    })

data = []

data['z'] = [[0, 1, 2, 3, 4],[5, 6, 7, 8, 9]]
data['z'].table
    id: "#" + 'z'
    colHeaders: ['i','ii','iii','iv','v']

$("#z").draggable()

data['y'] = [[0, 0, 0, 0, 0],[0, 0, 0, 0, 0]]
data['y'].table
    id: "#" + 'y'
    colHeaders: true


console.log "z", data['z']

eval("z=data['z']")

console.log "zzz", z

$("#step10").on "click", => 
    #console.log "z", data['z']
    for r in [0...data['z'].length]
        for c in [0...data['z'][0].length]
            data['y'][r][c] = data['z'][r][c]
    console.log "data y", data['y']
    $('#y').handsontable('getInstance').render()
    console.log "????????"

###


#hotInstance = $("#hot").handsontable('getInstance');
#console.log "hotInstance", hotInstance
#console.log "data", hotInstance.data
#container.handsontable({data:[x]})
#container.handsontable('getInstance').render()


###

container = $("#hot")

container.handsontable

container.handsontable({
    startRows: 5,
    startCols: 5,
    minRows: 5,
    minCols: 5,
    maxRows: 10,
    maxCols: 10,
    rowHeaders: true,
    colHeaders: true,
    minSpareRows: 1,
    contextMenu: true
    })


    
console.log "hot", hot


$("#step10").on "click", => 
    x = [0.1, 1, 2, 3, 4]
    console.log "x", x
    #hotInstance = $("#hot").handsontable('getInstance');
    #console.log "hotInstance", hotInstance
    #console.log "data", hotInstance.data
    container.handsontable({data:[x]})
    container.handsontable('getInstance').render()

#y = 2*x
#data = [x, y]

# Convert RGB to #hex value

rgbToHex = (r, g, b) ->
    '#' + ((1 << 24) + (r << 16) + (g << 8) + (b | 0)).toString(16).slice(1)

# Convert #hex to rgb value

hexToRgb = (hex) ->
    hex = hex.slice(1)
    {
        r: parseInt(hex.substr(0, 2), 16)
        g: parseInt(hex.substr(2, 2), 16)
        b: parseInt(hex.substr(4, 2), 16)
    }

# Gey YIQ contrast for #hex color

getContrastYIQ = (hex) ->
    hex = hexToRgb(hex)
    yiq = (hex.r * 299 + hex.g * 587 + hex.b * 114) / 1000
    if yiq >= 128 then 'black' else 'white'

hexRenderer = (instance, td, row, col, prop, value, cellProperties) ->
    Handsontable.TextCell.renderer.apply this, arguments
    console.log "this", this
    style = td.style
    # Apply new styles
    style.background = value
    style.color = getContrastYIQ(value)
    return


$('#exampleGrid').handsontable
    data: [[0, 0, 0, '#000000']]
    fillHandle: false
    minSpareCols: 0
    minSpareRows: 0
    colHeaders: ['R', 'G', 'B', 'HEX']
    colWidths: [70, 70, 70, 150]
    columns: [{}, {}, {}, { renderer: hexRenderer }]
    beforeChange: (changes, source) ->
        if source == 'convert'
            return
        r = undefined
        g = undefined
        b = undefined
        hex = undefined
        i = undefined
        len = undefined
        value = undefined
        i = 0
        len = changes.length
        while i < len
            value = changes[i][3]
            if changes[i][1] == 3
                if !/^#?([\da-f]{6}|[\da-f]{3})$/i.test(value)
                    changes[i] = null
                    i++
                    continue
                if value.indexOf('#') == -1
                    value = changes[i][3] = '#' + value
                if value.length == 4
                    value = value.split('')
                    value = changes[i][3] = '#' + value[1] + value[1] + value[2] + value[2] + value[3] + value[3]
                hex = hexToRgb(value)
                hot.setDataAtCell 0, 0, hex.r, 'convert'
                hot.setDataAtCell 0, 1, hex.g, 'convert'
                hot.setDataAtCell 0, 2, hex.b, 'convert'
            else
                if !$.isNumeric(value)
                    changes[i] = null
                    i++
                    continue
                if value < 0
                    value = changes[i][3] = 0
                if value > 255
                    value = changes[i][3] = 255
                # Get updated RGB values
                r = hot.getDataAtCell(0, 0)
                g = hot.getDataAtCell(0, 1)
                b = hot.getDataAtCell(0, 2)
                switch changes[i][1]
                    when 0
                        r = value
                    when 1
                        g = value
                    when 2
                        b = value
                # Update hex color
                hot.setDataAtCell 0, 3, rgbToHex(r, g, b), 'convert'
                i++
        return


hot = $('#exampleGrid').handsontable('getInstance')

###
