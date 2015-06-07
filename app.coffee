
class Sheet
    
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
        #console.log "app.sheet", app.sheet
        eval("#{@spec.id} = app.sheet['#{@spec.id}'].spec.data")

    fromLocal: (u)->
        app.sheet[@spec.id].spec.data = u


$blab.compute = ()->

    console.log "######## pre-code ########"

    for type of app.component
        for i of app.component[type]
            item = app.component[type][i]
            if item.spec.isSource is "true"
                item.update()

    for sym of app.sheet
        app.sheet[sym].toLocal()
        
    console.log "######## user-code ########"

    # ??? eval app.file["user.coffee"] ???

    fn = (A, x) ->
        A.dot x
    
    b = fn(A, x)

    q = y*z[0][0]

    console.log "######## post-code ########"

    # local vars -> sheets
    for sym of app.sheet
        app.sheet[sym].fromLocal(eval(sym))

    # update sinks
    for c of app.component
        for i of app.component[c]
            item = app.component[c][i]
            item.update() if item.spec.isSink is "true"

class App

    # from dev.json
    dev = $blab.resource "dev"
    token: dev.token
    gistId: dev.gistId
    
    constructor: ->
        
        github = new Github
            token: @token
            auth: "oauth"

        @gist = github.getGist(@gistId)
        
        $("#widget-menu").menu select: (event, ui) ->
            switch ui.item[0].innerHTML
                when "Read" then app.readGist()
                when "Save" then app.saveGist()

        @readGist()

    readGist: ->
        fn = (err, gist) =>
            @file = {}
            @file[gf] = gist.files[gf].content for gf of gist.files
            @build(err,gist)

        @gist.read(fn)

    build: (err,gist) ->

        # toolbox (of component types) 

        @toolbox={}
        types = JSON.parse(@file["toolbox.json"])
        @toolbox[t.id] = $blab[t.id] for t in types

        # (data) sheets

        @sheet = {}
        specs = JSON.parse(@file["sheet.json"])
        @sheet[spec.id] = new Sheet spec for spec in specs 

        # components

        @component = {}
        make = (type) =>
            @component[type] = {}
            for spec in JSON.parse(@file["#{type}.json"])
                @component[type][spec.id] = new @toolbox[type](spec, @sheet, @file)
        make(type) for type of @toolbox

    saveGist: ->

        data =
            "description": "the description for this gist"
            "files":
                "sheet2.json":
                    "content": JSON.stringify(@sheet, null, 2)

        @gist.update(data, (err, gist) -> console.log "save?", err, gist)


app = new App

