define ['jquery', 'constants'], ($, Constants) ->

  $status = $("##{Constants.STATUS_ELEMENT_ID}")

  class Viewer
    annotations = null
    annotation_index = null
    annotation = null
    type = null

    constructor: (@$iframe) -> # , @css_url) ->
      @load_promise = null
      @load_deferred = null
      @$iframe.load @loaded

    mouseover_handler: (evt) =>
      $attribute_bearers =
        $(evt.target).
        parents("[#{Constants.ANNOTATION_ATTRIBUTE}]").
        addBack("[#{Constants.ANNOTATION_ATTRIBUTE}]")
      seen = {}
      annotations = []
      $attribute_bearers.each (_, element) ->
        ann_id = element.getAttribute(Constants.ANNOTATION_ATTRIBUTE)
        annotations.push(ann_id) unless seen[ann_id]
        seen[ann_id] = true
      annotation_index = 0
      @show_annotation()

    mouseout_handler: (evt) =>
      @hide_annotation()
      annotations = null
      annotation_index = null
      annotation = null

    keypress_handler: (evt) =>
      if evt.which == 32 and annotations
        @hide_annotation()
        annotation_index = (annotation_index + 1) % annotations.length
        @show_annotation()
        evt.preventDefault()

    show_annotation: ->
      annotation = annotations[annotation_index]
      @$iframe_doc.find("[#{Constants.ANNOTATION_ATTRIBUTE}~='#{annotation}']").
        attr(Constants.ACTIVE_ATTRIBUTE, '')
      if annotations.length > 1
        $status.text("#{annotation_index + 1}/#{annotations.length}").show()

    hide_annotation: ->
      @$iframe_doc.find("[#{Constants.ANNOTATION_ATTRIBUTE}~='#{annotation}']").
        removeAttr(Constants.ACTIVE_ATTRIBUTE)
      $status.hide()

    bind: =>
      @$iframe_doc.on 'mouseover', "[#{Constants.ANNOTATION_ATTRIBUTE}]", @mouseover_handler
      @$iframe_doc.on 'mouseout', "[#{Constants.ANNOTATION_ATTRIBUTE}]", @mouseout_handler
      @$iframe_doc.on 'keypress', @keypress_handler

    load: (filename) ->
      @load_deferred?.reject()
      @$iframe.attr('src', filename)
      @load_deferred = $.Deferred()
      @load_promise = @load_deferred.promise()

    loaded: (evt) =>
      @$iframe_doc = @$iframe.contents()
      @bind()
      @load_deferred.resolve() if @load_deferred?
      @load_deferred = null
