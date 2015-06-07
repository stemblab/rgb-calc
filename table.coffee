
class Component

    constructor: ->

    update: ->
        
    stringify: ->
        JSON.stringify(@spec)

class $blab.Table extends Component
    
    constructor: (@spec, sheet) ->

        randPos = (range, offset)->
            "#{Math.round((Math.random()*range+offset)*100)}%"
        @spec.x ?= randPos(0.8, 0.1)
        @spec.y ?= randPos(0.8, 0.1)
        
        @sheet = sheet[@spec.id]

        container = $("##{@spec.id}")
        container.append("<div class='hot'></div>")
        container.css("position", "absolute")
        container.css("left", @spec.x)
        container.css("top", @spec.y)

        hot = $("##{@spec.id} .hot")
        @defaults =
            data: @sheet.spec.data
            afterChange: (change, source) =>
                $blab.compute() if source is "edit" and @sheet.spec.compute
            columns: ({type: 'numeric'} for k in [1..@sheet.spec.data[0].length])
            rowHeaders: @sheet.spec.rowHeaders
            colHeaders: @sheet.spec.colHeaders
            contextMenu: false
        @table = new Handsontable hot[0], $.extend({}, @defaults, @spec)

    update: ->
        @table.loadData @sheet.spec.data
        @table.render()
        
