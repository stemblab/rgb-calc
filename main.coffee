#!vanilla

# Convert RGB to #hex value

rgbToHex = (r, g, b) ->
    '#' + ((1 << 24) + (r << 16) + (g << 8) + (b | 0)).toString(16).slice(1)

# Convert #hex to rgb value

hexToRgb = (hex) ->
    hex = hex.slice(1)
    {
        r: parseInt(hex.substr(0, 2), 16)
        g: parseInt(hex.substr(2, 2), 16)
        b: parseInt(hex.substr(4, 2), 16)
    }

# Gey YIQ contrast for #hex color

getContrastYIQ = (hex) ->
    hex = hexToRgb(hex)
    yiq = (hex.r * 299 + hex.g * 587 + hex.b * 114) / 1000
    if yiq >= 128 then 'black' else 'white'

hexRenderer = (instance, td, row, col, prop, value, cellProperties) ->
    Handsontable.TextCell.renderer.apply this, arguments
    style = td.style
    # Apply new styles
    style.background = value
    style.color = getContrastYIQ(value)
    return


$('#exampleGrid').handsontable
    data: [[0, 0, 0, '#000000']]
    fillHandle: false
    minSpareCols: 0
    minSpareRows: 0
    colHeaders: ['R', 'G', 'B', 'HEX']
    colWidths: [70, 70, 70, 150]
    columns: [{}, {}, {}, { renderer: hexRenderer }]
    beforeChange: (changes, source) ->
        if source == 'convert'
            return
        r = undefined
        g = undefined
        b = undefined
        hex = undefined
        i = undefined
        len = undefined
        value = undefined
        i = 0
        len = changes.length
        while i < len
            value = changes[i][3]
            if changes[i][1] == 3
                if !/^#?([\da-f]{6}|[\da-f]{3})$/i.test(value)
                    changes[i] = null
                    i++
                    continue
                if value.indexOf('#') == -1
                    value = changes[i][3] = '#' + value
                if value.length == 4
                    value = value.split('')
                    value = changes[i][3] = '#' + value[1] + value[1] + value[2] + value[2] + value[3] + value[3]
                hex = hexToRgb(value)
                hot.setDataAtCell 0, 0, hex.r, 'convert'
                hot.setDataAtCell 0, 1, hex.g, 'convert'
                hot.setDataAtCell 0, 2, hex.b, 'convert'
            else
                if !$.isNumeric(value)
                    changes[i] = null
                    i++
                    continue
                if value < 0
                    value = changes[i][3] = 0
                if value > 255
                    value = changes[i][3] = 255
                # Get updated RGB values
                r = hot.getDataAtCell(0, 0)
                g = hot.getDataAtCell(0, 1)
                b = hot.getDataAtCell(0, 2)
                switch changes[i][1]
                    when 0
                        r = value
                    when 1
                        g = value
                    when 2
                        b = value
                # Update hex color
                hot.setDataAtCell 0, 3, rgbToHex(r, g, b), 'convert'
                i++
        return


hot = $('#exampleGrid').handsontable('getInstance')

