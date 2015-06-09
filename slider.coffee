class $blab.Slider extends $blab.Component

    constructor:  (@spec, sheet, file) ->

        super(@spec, sheet, file)
        
        @block.append("<div class='slider'/>")
        @block.append("<div class='label'/>")
        @block.append("<input type='text' readonly class='report'>")

        label = @block.children(".label")
        label.html(@sheet.spec.rowHeaders[0])
        
        @slider = @block.children(".slider")
        @slider.css("position", "absolute")
        @slider.css("left", @spec.x)
        @slider.css("top", @spec.y)
        @slider.css("width", "100px")

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
        @slider.slider settings

        report = @block.children(".report")
        report.val @slider.slider("value")

    update: ->
        @sheet.spec.data[0][0] = @slider.slider("value")
