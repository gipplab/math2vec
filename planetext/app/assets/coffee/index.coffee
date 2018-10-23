$ ->
  if editing
    $('#datasets').on 'click', '.delete-dataset', (evt) ->
      evt.stopPropagation()
      $link = $(this).closest('a')
      href = $link.attr('href')
      name = $link.text()
      name2 = prompt("Please type in \"#{name}\" to confirm deletion:")
      if name == name2
        $.ajax
          url: href
          type: 'delete'
          success: ->
            $link.remove()
      false

    $('#new-dataset-name').keydown (evt) ->
      if evt.keyCode == 13
        name = $(this).val()
        $.ajax
          url: "#{app_url}/new/#{name}"
          type: 'put'
          data:
            name: name
          success: ->
            $a = $('<a class="dataset">').text(name).
                attr('href', "#{app_url}/dataset/#{name}").
                attr('rel', name)
            $i = $('<input class="delete-dataset" type="button" value="Delete">').appendTo($a)
            $('.new-dataset').val('').before($a)

    exts = ['xml', 'xhtml', 'html']
    check_files = (files, callback) ->
      count = 0
      for file in files
        return false unless match = file.name.match /\.([^./]+)$/
        return false if exts.indexOf(match[1]) == -1
        callback(count++, file)
      true

    jQuery_xhr_factory = $.ajaxSettings.xhr
    upload = (files, $target, dataset) ->
      form = new FormData()
      if !check_files(files, (index, file) -> form.append(index, file))
        $target.css('background', '').addClass('failure')
        return

      # perform upload
      $.ajax
        url: "#{app_url}/dataset/#{dataset}/upload"
        data: form
        type: "POST"
        contentType: false
        processData: false
        xhr: ->
          req = jQuery_xhr_factory()
          req.upload.addEventListener "progress", this.progressUpload, false
          req
        progressUpload: (evt) ->
          progress = Math.round(100 * evt.loaded / evt.total)
          $target.css('background', "linear-gradient(to right, rgba(255,255,255,0.30) 0%,rgba(0,0,255,0.30) #{progress}%,rgba(0,0,0,0) #{progress}%,rgba(0,0,0,0) 100%)")
        success: ->
          $target.css('background', '').addClass('success')
        error: ->
          $target.css('background', '').addClass('failure')

    $(document).on 'dragover', (evt) ->
      evt.preventDefault()
    $(document).on 'dragover', '.dataset', (evt) ->
      evt.originalEvent.dataTransfer.dropEffect = "copy"
      evt.preventDefault()
    $(document).on 'dragenter', '.dataset', (evt) ->
      evt.originalEvent.dataTransfer.dropEffect = "copy"
      $(evt.target).addClass('dragover')
      evt.preventDefault()
    $(document).on 'dragleave', '.dataset', (evt) ->
      $(evt.target).removeClass('dragover')
      evt.preventDefault()
    $(document).on 'drop', '.dataset', (evt) ->
      evt.preventDefault()
      evt.stopPropagation()
      $target = $(evt.target).removeClass('dragover')
      if evt.originalEvent.dataTransfer?.files?.length
        return unless $target[0].nodeName == 'A'
        dataset = $target.attr('rel')
        upload(evt.originalEvent.dataTransfer.files, $target, dataset)
    $(document).on 'drop', '*', (evt) ->
      setTimeout clearDragState, 1000
      evt.preventDefault()

    clearDragState = ->
      $('.failure').removeClass('failure')
      $('.success').removeClass('success')
