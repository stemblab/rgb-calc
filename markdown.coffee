
class Component

    constructor: ->

    update: ->
        
    stringify: ->
        JSON.stringify(@spec)


class $blab.Markdown extends Component

    marked.setOptions
        renderer: new marked.Renderer
        gfm: true
        tables: true
        breaks: false
        pedantic: false
        sanitize: true
        smartLists: true
        smartypants: false
    
    constructor: (@spec, @sheet, @file) ->

        console.log "spec", @spec
        
        container = $("##{@spec.id}")
        container.html marked(@file[@spec.file])
        
