(function() {
  $(function() {
    var check_files, clearDragState, exts, jQuery_xhr_factory, upload;
    if (editing) {
      $('#datasets').on('click', '.delete-dataset', function(evt) {
        var $link, href, name, name2;
        evt.stopPropagation();
        $link = $(this).closest('a');
        href = $link.attr('href');
        name = $link.text();
        name2 = prompt("Please type in \"" + name + "\" to confirm deletion:");
        if (name === name2) {
          $.ajax({
            url: href,
            type: 'delete',
            success: function() {
              return $link.remove();
            }
          });
        }
        return false;
      });
      $('#new-dataset-name').keydown(function(evt) {
        var name;
        if (evt.keyCode === 13) {
          name = $(this).val();
          return $.ajax({
            url: "" + app_url + "/new/" + name,
            type: 'put',
            data: {
              name: name
            },
            success: function() {
              var $a, $i;
              $a = $('<a class="dataset">').text(name).attr('href', "" + app_url + "/dataset/" + name).attr('rel', name);
              $i = $('<input class="delete-dataset" type="button" value="Delete">').appendTo($a);
              return $('.new-dataset').val('').before($a);
            }
          });
        }
      });
      exts = ['xml', 'xhtml', 'html'];
      check_files = function(files, callback) {
        var count, file, match, _i, _len;
        count = 0;
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          file = files[_i];
          if (!(match = file.name.match(/\.([^./]+)$/))) {
            return false;
          }
          if (exts.indexOf(match[1]) === -1) {
            return false;
          }
          callback(count++, file);
        }
        return true;
      };
      jQuery_xhr_factory = $.ajaxSettings.xhr;
      upload = function(files, $target, dataset) {
        var form;
        form = new FormData();
        if (!check_files(files, function(index, file) {
          return form.append(index, file);
        })) {
          $target.css('background', '').addClass('failure');
          return;
        }
        return $.ajax({
          url: "" + app_url + "/dataset/" + dataset + "/upload",
          data: form,
          type: "POST",
          contentType: false,
          processData: false,
          xhr: function() {
            var req;
            req = jQuery_xhr_factory();
            req.upload.addEventListener("progress", this.progressUpload, false);
            return req;
          },
          progressUpload: function(evt) {
            var progress;
            progress = Math.round(100 * evt.loaded / evt.total);
            return $target.css('background', "linear-gradient(to right, rgba(255,255,255,0.30) 0%,rgba(0,0,255,0.30) " + progress + "%,rgba(0,0,0,0) " + progress + "%,rgba(0,0,0,0) 100%)");
          },
          success: function() {
            return $target.css('background', '').addClass('success');
          },
          error: function() {
            return $target.css('background', '').addClass('failure');
          }
        });
      };
      $(document).on('dragover', function(evt) {
        return evt.preventDefault();
      });
      $(document).on('dragover', '.dataset', function(evt) {
        evt.originalEvent.dataTransfer.dropEffect = "copy";
        return evt.preventDefault();
      });
      $(document).on('dragenter', '.dataset', function(evt) {
        evt.originalEvent.dataTransfer.dropEffect = "copy";
        $(evt.target).addClass('dragover');
        return evt.preventDefault();
      });
      $(document).on('dragleave', '.dataset', function(evt) {
        $(evt.target).removeClass('dragover');
        return evt.preventDefault();
      });
      $(document).on('drop', '.dataset', function(evt) {
        var $target, dataset, _ref, _ref1;
        evt.preventDefault();
        evt.stopPropagation();
        $target = $(evt.target).removeClass('dragover');
        if ((_ref = evt.originalEvent.dataTransfer) != null ? (_ref1 = _ref.files) != null ? _ref1.length : void 0 : void 0) {
          if ($target[0].nodeName !== 'A') {
            return;
          }
          dataset = $target.attr('rel');
          return upload(evt.originalEvent.dataTransfer.files, $target, dataset);
        }
      });
      $(document).on('drop', '*', function(evt) {
        setTimeout(clearDragState, 1000);
        return evt.preventDefault();
      });
      return clearDragState = function() {
        $('.failure').removeClass('failure');
        return $('.success').removeClass('success');
      };
    }
  });

}).call(this);
