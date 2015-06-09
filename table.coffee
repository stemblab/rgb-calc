class $blab.Table extends $blab.Component
    
    constructor: (@spec, sheet, file) ->

        super(@spec, sheet, file)

        defaults =
            data: @sheet.spec.data
            afterChange: (change, source) =>
                $blab.compute() if source is "edit" and @spec.compute
            columns: ({type: 'numeric'} for k in [1..@sheet.spec.data[0].length])
            rowHeaders: @sheet.spec.rowHeaders
            colHeaders: @sheet.spec.colHeaders
            contextMenu: false
            
        @table = new Handsontable @main[0], $.extend({}, defaults, @spec)

    update: ->
        @table.loadData @sheet.spec.data
        @table.render()
        
