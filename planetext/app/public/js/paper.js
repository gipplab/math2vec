(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['jquery', 'annotation_inserter'], function($, AnnotationInserter) {
    var Paper;
    return Paper = (function() {
      function Paper(viewer) {
        this.viewer = viewer;
        this.insert_annotations = __bind(this.insert_annotations, this);
      }

      Paper.prototype.insert_annotations = function() {
        return new AnnotationInserter(this.data, this.viewer.$iframe_doc);
      };

      Paper.prototype.load_document = function() {
        return this.viewer.load(this.filename);
      };

      Paper.prototype.load_data = function() {
        return $.ajax({
          url: "" + this.basename + "." + this.ext,
          dataType: this.ext === {
            'ann': {
              'text': 'json'
            }
          },
          success: (function(_this) {
            return function(data) {
              _this.data = data;
              if (_this.ext === "ann") {
                return _this.convert_brat_annotations();
              }
            };
          })(this),
          error: (function(_this) {
            return function() {
              return console.warn("Error loading " + _this.basename + "." + _this.ext);
            };
          })(this)
        });
      };

      Paper.prototype.load_types = function() {
        return $.ajax({
          url: "" + this.dir + "/types.json",
          dataType: 'json',
          success: (function(_this) {
            return function(types) {
              _this.types = types;
            };
          })(this),
          error: (function(_this) {
            return function() {
              return console.warn("Error loading " + _this.dir + "/types.json");
            };
          })(this)
        });
      };

      Paper.prototype.clear = function() {
        return this.viewer.$iframe_doc.find("[kmcs-a]").each(function() {
          return $(this.childNodes[0]).unwrap();
        });
      };

      Paper.prototype.load = function(filename, data, callback) {
        var actions, _, _ref;
        this.data = data;
        if (filename) {
          this.filename = filename;
          _ref = filename.match(/^((?:(.*)\/)?[^\/]*)\.([^.]+)$/), _ = _ref[0], this.basename = _ref[1], this.dir = _ref[2], this.docext = _ref[3];
          this.types = null;
        }
        if (typeof this.data === "string") {
          this.ext = this.data;
          this.data = null;
        } else if (!this.data) {
          this.ext = "ann";
        }
        actions = [];
        if (filename) {
          actions.push(this.load_document());
        } else {
          this.clear();
        }
        if (!this.data) {
          actions.push(this.load_data());
        }
        if (this.ext === "ann") {
          actions.push(this.load_types());
        }
        return $.when.apply($, actions).then((function(_this) {
          return function() {
            if (_this.types) {
              _this.data.types = _this.types;
            }
            _this.insert_annotations();
            if (callback) {
              return callback(_this.viewer.$iframe_doc);
            }
          };
        })(this));
      };

      Paper.prototype.convert_brat_annotations = function() {
        var body, content, extent, extent_body, extents, id, line, lines, pos, standoffs, type, _, _i, _len, _ref, _ref1, _results;
        lines = this.data.split(/\n/);
        this.data = {
          standoffs: standoffs = []
        };
        _results = [];
        for (_i = 0, _len = lines.length; _i < _len; _i++) {
          line = lines[_i];
          if (/^T/.test(line)) {
            _ref = line.split("\t"), id = _ref[0], body = _ref[1], content = _ref[2];
            _ref1 = body.match(/^(\S*)\s(.*)$/), _ = _ref1[0], type = _ref1[1], extent_body = _ref1[2];
            extents = (function() {
              var _j, _len1, _ref2, _results1;
              _ref2 = extent_body.split(';');
              _results1 = [];
              for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
                extent = _ref2[_j];
                _results1.push((function() {
                  var _k, _len2, _ref3, _results2;
                  _ref3 = extent.split(' ');
                  _results2 = [];
                  for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
                    pos = _ref3[_k];
                    _results2.push(parseInt(pos, 10));
                  }
                  return _results2;
                })());
              }
              return _results1;
            })();
            _results.push(standoffs.push([id, type, extents]));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      return Paper;

    })();
  });

}).call(this);
