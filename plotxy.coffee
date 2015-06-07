class Component

    constructor: ->

    update: ->
        
    stringify: ->
        JSON.stringify(@spec)

class $blab.PlotXY extends Component

    constructor: (@spec, sheet) ->
        #@sheets = (app.sheet[id] for id in @spec.sheetIds)
        @sheets = (sheet[id] for id in @spec.sheetIds)
        defaults = {}
        @chart = c3.generate(
            bindto: $("##{@spec.id}")[0]
            data: $.extend({}, defaults, @spec.data, @getCols())
        )

    getCols: ->
        cols = []
        cols.push c for c in sheet.labelRows() for sheet in @sheets
        columns: cols

    update: ->
        @chart.load(@getCols())

