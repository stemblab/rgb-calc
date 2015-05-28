
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
        eval("#{@spec.id} = $blab.component.sheet['#{@spec.id}'].spec.data")

    fromLocal: (u)->
        $blab.component.sheet[@spec.id].spec.data = u


class PlotXY extends Widget

    constructor: (@spec) ->
        @sheets = ($blab.component.sheet[id] for id in @spec.sheetIds)
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
        
        @sheet = $blab.component.sheet[@spec.id]

        container = $("##{@spec.id}")
        container.append("<div class='hot'></div>")
        container.css("position", "absolute")
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

        @sheet = $blab.component.sheet[@spec.id]

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

toolbox =
    sheet: Sheet    
    figure: PlotXY
    table: Table
    markdown: Markdown
   

# user code


compute = ()->

    console.log "######## pre-code ########"

    # refresh sink
    for sl of $blab.slider
        $blab.slider[sl].update()
        console.log $blab.slider[sl].stringify()

    # local copy of vars
    for sym of $blab.component.sheet
        $blab.component.sheet[sym].toLocal()

    console.log "######## user-code ########"

    fn = (A, x) ->
        A.dot x
    
    b = fn(A, x)

    q = y*z[0][0]

    console.log "######## post-code ########"

    $blab.spec = {}
    for c of $blab.component
        $blab.spec[c] = {}
        for i of $blab.component[c]
            $blab.spec[c][i] = $blab.component[c][i].spec
            if c == "sheet"
                $blab.component.sheet[i].fromLocal(eval(i))
            else
                $blab.component[c][i].update()

    console.log ">>>", JSON.stringify($blab.spec)
    

loadgist = (gistid, filename) ->

    $.ajax(
        url: "https://api.github.com/gists/#{gistid}"
        type: 'GET'
        dataType: 'jsonp'

    ).success((gistdata) ->
        specs = JSON.parse(gistdata.data.files[filename].content)
        build = (w) ->
            $blab["component"][w] = {}
            $blab["component"][w][spec.id] = new toolbox[w] spec for spec in specs[w]

        $blab["component"] = {}

        for spec of specs
            build(spec)

        compute()
        
    ).error (e) ->
        # ajax error
        return

loadgist("f673df3f600fdeb17608", "app.json")


