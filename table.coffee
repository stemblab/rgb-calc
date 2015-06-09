class $blab.Table extends $blab.Component
    
    constructor: (@spec, sheet, file) ->

        @sheet = sheet[@spec.id]

        container = $("##{@spec.containerId}")
        container.append("<div id='Table-#{@spec.id}' class='hot'></div>")

        hot = $("#Table-#{@spec.id}")
        hot.css("position", "absolute")
        hot.css("left", @spec.x)
        hot.css("top", @spec.y)

        defaults =
            data: @sheet.spec.data
            afterChange: (change, source) =>
                $blab.compute() if source is "edit" and @spec.compute
            columns: ({type: 'numeric'} for k in [1..@sheet.spec.data[0].length])
            rowHeaders: @sheet.spec.rowHeaders
            colHeaders: @sheet.spec.colHeaders
            contextMenu: false
            
        @table = new Handsontable hot[0], $.extend({}, defaults, @spec)

    update: ->
        @table.loadData @sheet.spec.data
        @table.render()
        
