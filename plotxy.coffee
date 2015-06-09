class $blab.PlotXY extends $blab.Component

    constructor: (@spec, sheet, file) ->

        super(@spec, sheet, file)
        
        defaults = {}

        @chart = c3.generate(
            bindto: @main[0]
            data: $.extend({}, defaults, @spec.data, @getCols())
        )

    getCols: ->
        cols = []
        cols.push c for c in sheet.labelRows() for sheet in @sheet
        columns: cols

    update: ->
        @chart.load(@getCols())

