define ['jquery','annotation_inserter'], ($, AnnotationInserter) ->
  class Paper
    constructor: (@viewer) ->

    insert_annotations: =>
      new AnnotationInserter(@data, @viewer.$iframe_doc)

    load_document: ->
      @viewer.load(@filename)

    load_data: ->
      $.ajax
        url: "#{@basename}.#{@ext}"
        dataType: @ext == 'ann' : 'text' : 'json'
        success: (@data) =>
          @convert_brat_annotations() if @ext == "ann"
        error: =>
          console.warn "Error loading #{@basename}.#{@ext}"

    load_types: ->
      $.ajax
        url: "#{@dir}/types.json"
        dataType: 'json'
        success: (@types) =>
        error: =>
          console.warn "Error loading #{@dir}/types.json"

    clear: ->
      @viewer.$iframe_doc.find("[kmcs-a]").each ->
        $(this.childNodes[0]).unwrap()

    load: (filename, @data, callback) -> # instead of data, can give "ann"/"json"
      if filename
        @filename = filename
        # TODO don't need docext
        [_, @basename, @dir, @docext] = filename.match(/^((?:(.*)\/)?[^\/]*)\.([^.]+)$/)
        @types = null
      if typeof(@data) == "string"
        @ext = @data
        @data = null
      else if !@data
        @ext = "ann"

      actions = []
      if filename
        actions.push(@load_document())
      else
        @clear()
      unless @data
        actions.push(@load_data())
      if @ext == "ann"
        actions.push(@load_types())

      $.when(actions...).then =>
        @data.types = @types if @types
        @insert_annotations()
        callback(@viewer.$iframe_doc) if callback

    convert_brat_annotations: ->
      lines = @data.split(/\n/)
      @data =
        standoffs: standoffs = []
      for line in lines
        if /^T/.test(line)
          [id, body, content] = line.split("\t")
          [_, type, extent_body] = body.match(/^(\S*)\s(.*)$/)
          extents = ((parseInt(pos, 10) for pos in extent.split(' ')) for extent in extent_body.split(';'))
          standoffs.push [id, type, extents]
