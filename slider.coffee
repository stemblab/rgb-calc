class $blab.Slider extends $blab.Component

    constructor:  (@spec, sheet, file) ->

        super(@spec, sheet, file)
        
        @block.append("<div class='label'/>")
        @block.append("<input type='text' readonly class='report'>")

        label = @block.children(".label")
        label.html(@sheet.spec.rowHeaders[0])
        
        @block.css("width", "100px")

        defaults =
            width: 500
            value: 1
            min: 0
            max: 10
            step: 1
            change: (event, ui) ->
                report.val ui.value
                $blab.compute()

        settings = $.extend({}, defaults, @spec)
        @main.slider settings

        report = @block.children(".report")
        report.val @main.slider("value")

    update: ->
        @sheet.spec.data[0][0] = @main.slider("value")
