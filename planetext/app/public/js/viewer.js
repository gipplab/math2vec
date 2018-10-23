(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['jquery', 'constants'], function($, Constants) {
    var $status, Viewer;
    $status = $("#" + Constants.STATUS_ELEMENT_ID);
    return Viewer = (function() {
      var annotation, annotation_index, annotations, type;

      annotations = null;

      annotation_index = null;

      annotation = null;

      type = null;

      function Viewer($iframe) {
        this.$iframe = $iframe;
        this.loaded = __bind(this.loaded, this);
        this.bind = __bind(this.bind, this);
        this.keypress_handler = __bind(this.keypress_handler, this);
        this.mouseout_handler = __bind(this.mouseout_handler, this);
        this.mouseover_handler = __bind(this.mouseover_handler, this);
        this.load_promise = null;
        this.load_deferred = null;
        this.$iframe.load(this.loaded);
      }

      Viewer.prototype.mouseover_handler = function(evt) {
        var $attribute_bearers, seen;
        $attribute_bearers = $(evt.target).parents("[" + Constants.ANNOTATION_ATTRIBUTE + "]").addBack("[" + Constants.ANNOTATION_ATTRIBUTE + "]");
        seen = {};
        annotations = [];
        $attribute_bearers.each(function(_, element) {
          var ann_id;
          ann_id = element.getAttribute(Constants.ANNOTATION_ATTRIBUTE);
          if (!seen[ann_id]) {
            annotations.push(ann_id);
          }
          return seen[ann_id] = true;
        });
        annotation_index = 0;
        return this.show_annotation();
      };

      Viewer.prototype.mouseout_handler = function(evt) {
        this.hide_annotation();
        annotations = null;
        annotation_index = null;
        return annotation = null;
      };

      Viewer.prototype.keypress_handler = function(evt) {
        if (evt.which === 32 && annotations) {
          this.hide_annotation();
          annotation_index = (annotation_index + 1) % annotations.length;
          this.show_annotation();
          return evt.preventDefault();
        }
      };

      Viewer.prototype.show_annotation = function() {
        annotation = annotations[annotation_index];
        this.$iframe_doc.find("[" + Constants.ANNOTATION_ATTRIBUTE + "~='" + annotation + "']").attr(Constants.ACTIVE_ATTRIBUTE, '');
        if (annotations.length > 1) {
          return $status.text("" + (annotation_index + 1) + "/" + annotations.length).show();
        }
      };

      Viewer.prototype.hide_annotation = function() {
        this.$iframe_doc.find("[" + Constants.ANNOTATION_ATTRIBUTE + "~='" + annotation + "']").removeAttr(Constants.ACTIVE_ATTRIBUTE);
        return $status.hide();
      };

      Viewer.prototype.bind = function() {
        this.$iframe_doc.on('mouseover', "[" + Constants.ANNOTATION_ATTRIBUTE + "]", this.mouseover_handler);
        this.$iframe_doc.on('mouseout', "[" + Constants.ANNOTATION_ATTRIBUTE + "]", this.mouseout_handler);
        return this.$iframe_doc.on('keypress', this.keypress_handler);
      };

      Viewer.prototype.load = function(filename) {
        var _ref;
        if ((_ref = this.load_deferred) != null) {
          _ref.reject();
        }
        this.$iframe.attr('src', filename);
        this.load_deferred = $.Deferred();
        return this.load_promise = this.load_deferred.promise();
      };

      Viewer.prototype.loaded = function(evt) {
        this.$iframe_doc = this.$iframe.contents();
        this.bind();
        if (this.load_deferred != null) {
          this.load_deferred.resolve();
        }
        return this.load_deferred = null;
      };

      return Viewer;

    })();
  });

}).call(this);
