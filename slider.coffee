
class Component

    constructor: ->

    update: ->
        
    stringify: ->
        JSON.stringify(@spec)


class $blab.Slider extends Component

    constructor: (@spec, sheet) ->

        @sheet = sheet[@spec.id]

        @container = $("##{@spec.id}")
        @container.append("<div class='slider'></div>")
        @container.append("<div class='label'></div>")
        @container.append("<input type='text' readonly class='report'>")
        @report = @container.find('.report')

        @container.draggable()
        @container.on 'drag', (event) =>
            $('#myInput').val event.pageX + ',' + event.pageY
            @spec.X = event.pageX
            @spec.Y = event.pageY

        defaults =
            width: 500
            value: 1
            min: 0
            max: 10
            step: 1
            change: (event, ui) =>
                @report.val ui.value
                $blab.compute()

        settings = $.extend({}, defaults, @spec)

        @container.find('.label').html(@sheet.spec.rowHeaders[0])
        @container.css("width", settings.width)

        @slider = @container.find('.slider')
        @slider.slider settings

        @report.val @slider.slider("value")

    update: ->
        @sheet.spec.data[0][0] =  @slider.slider("value")
