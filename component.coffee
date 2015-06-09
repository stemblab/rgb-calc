
class $blab.Component

    constructor: (@spec, sheet, file) ->

        if @spec.sheetIds
            @sheet = (sheet[id] for id in @spec.sheetIds)
        else
            @sheet = sheet[@spec.id]
        blockType = @constructor.name
        blockId = "#{blockType}-#{@spec.id}"
        container = $("##{@spec.containerId}")
        container.append("<div id='#{blockId}' class='block'/>")
        @block = container.children("##{blockId}")
        
    update: ->
        
    stringify: ->
        JSON.stringify(@spec)

