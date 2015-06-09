class $blab.Markdown extends $blab.Component

    marked.setOptions
        renderer: new marked.Renderer
        gfm: true
        tables: true
        breaks: false
        pedantic: false
        sanitize: true
        smartLists: true
        smartypants: false
    
    constructor: (@spec, sheet, file) ->

        super(@spec, sheet, file)
        
        @md = file[@spec.fileName]
        @main.html marked(@md)
        
