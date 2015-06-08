class $blab.Slider extends $blab.Component

    constructor: (@spec, sheet) ->

        @sheet = sheet[@spec.id]

        container = $("##{@spec.containerId}")
        container.append("<div class='box'></div>")

        box = container.children(".box")
        box.append("<div class='slider'></div>")
        box.append("<div class='label'></div>")
        box.append("<input type='text' readonly class='report'>")

        label = box.children(".label")
        label.html(@sheet.rowHeaders[0])
        
        @slider = box.children(".slider")
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

        report = box.children(".report")
        report.val @slider.slider("value")

    update: ->
        @sheet.data[0][0] = @slider.slider("value")
