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
        
        @block.append("<div class='markdown'/>")
        markdown = @block.children(".markdown")
        
        @md = file[@spec.fileName]
        markdown.html marked(@md)
        
