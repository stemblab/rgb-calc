
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
        md = (err, gist) =>
            container.html marked(gist.files[@spec.id+".md"].content)
        broadsheet.gist.read md
        
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
        eval("#{@spec.id} = broadsheet.sheet['#{@spec.id}'].spec.data")

    fromLocal: (u)->
        broadsheet.sheet[@spec.id].spec.data = u


class PlotXY extends Widget

    constructor: (@spec) ->
        @sheets = (broadsheet.sheet[id] for id in @spec.sheetIds)
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
        
        @sheet = broadsheet.sheet[@spec.id]

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

        @sheet = broadsheet.sheet[@spec.id]

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
    slider: Slider

# user code


compute = ()->

    console.log "######## pre-code ########"

    for type of broadsheet.component
        for i of broadsheet.component[type]
            item = broadsheet.component[type][i]
            console.log "item", item
            if item.spec.isSource is "true"
                item.update()

    for sym of broadsheet.sheet
        broadsheet.sheet[sym].toLocal()
        
    console.log "######## user-code ########"

    fn = (A, x) ->
        A.dot x
    
    b = fn(A, x)

    q = y*z[0][0]

    console.log "######## post-code ########"

    # local vars -> sheets
    for sym of broadsheet.sheet
        broadsheet.sheet[sym].fromLocal(eval(sym))

    # update sinks
    for c of broadsheet.component
        for i of broadsheet.component[c]
            item = broadsheet.component[c][i]
            item.update() if item.spec.isSink is "true"

    # update netlist
    broadsheet.updateNetlist()    

class Broadsheet

    # from dev.json
    dev = $blab.resource "dev"
    token: dev.token
    gistId: dev.gistId
    
    constructor: ->

        @editor = ace.edit("editor")
        @editor.setTheme("ace/theme/textmate")
        @editor.getSession().setMode("ace/mode/json")
        @editor.setOptions
            fontSize: "14pt"

        github = new Github
            token: @token
            auth: "oauth"

        @gist = github.getGist(@gistId)
        
        $("#widget-menu").menu select: (event, ui) ->
            switch ui.item[0].innerHTML
                when "Read" then broadsheet.readGist()
                when "Save" then broadsheet.saveGist()

    updateNetlist: ->
        @netlist = {}
        for c of broadsheet.component
            @netlist[c] = {}
            for i of broadsheet.component[c]
                item = broadsheet.component[c][i]
                @netlist[c][i] = item.spec
        console.log "netlst", @netlist

    readGist: ->
        fn = (err, gist) =>
            console.log "gist", gist
            @build(err,gist)
        @gist.read(fn)

    build: (err,gist) ->

        # sheets

        @sheet = {}
        console.log "sheetJsn?", JSON.parse(gist.files["sheet.json"].content)
        fn = (x) -> x
        sheetJson = JSON.parse(gist.files["sheet.json"].content)
        
        console.log "????", sheetJson
        
        for sym of sheetJson
            @sheet[sym] = new toolbox["sheet"] sheetJson[sym]

        # components

        @component = {}
        netJson = JSON.parse(gist.files["netlist.json"].content)

        make = (item) =>
            @component[item] = {}
            for sym of netJson[item]
                @component[item][sym] = new toolbox[item] netJson[item][sym]

        for item of netJson
            make(item)

        # netlist

        @updateNetlist()
        

    saveGist: ->

        data =
            "description": "the description for this gist"
            "files":
                "netlist2.json":
                    "content": JSON.stringify(@netlist, null, 2)
                "sheet2.json":
                    "content": JSON.stringify(@sheet, null, 2)

        @gist.update(data, (err, gist) -> console.log "save?", err, gist)


broadsheet = new Broadsheet

