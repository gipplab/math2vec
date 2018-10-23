(function() {
  var __hasProp = {}.hasOwnProperty;

  window.x = function(xpath) {
    return document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
  };

  define(['jquery', 'constants'], function($, Constants) {
    var AnnotationInserter, high_unicode_re, unicode_length, unicode_substring;
    high_unicode_re = /[\ud800-\udbff](?=[\udc00-\udfff])/g;
    unicode_length = function(str) {
      var len;
      high_unicode_re.lastIndex = 0;
      len = str.length;
      while (high_unicode_re.exec(str)) {
        len--;
      }
      return len;
    };
    unicode_substring = function(str, from, to) {
      var limit, m;
      high_unicode_re.lastIndex = 0;
      limit = to || from;
      while ((m = high_unicode_re.exec(str)) && high_unicode_re.lastIndex <= limit) {
        if (high_unicode_re.lastIndex <= from) {
          from++;
        }
        if (to) {
          to++;
        }
      }
      return str.substring(from, to);
    };
    return AnnotationInserter = (function() {
      function AnnotationInserter(data, $iframe_doc) {
        var standoff, _i, _len, _ref;
        this.$iframe_doc = $iframe_doc;
        this.start_node = this.$iframe_doc[0].documentElement;
        this.offset = 0;
        this.generate_stylesheet(data.types);
        this.mark_node_positions(this.start_node);
        this.start_nodes = this.collect_start_nodes();
        _ref = data.standoffs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          standoff = _ref[_i];
          this.create_annotation_for(standoff);
        }
      }

      AnnotationInserter.prototype.collect_start_nodes = function() {
        return $(this.start_node).find("[" + Constants.DISPLACEMENT_ATTRIBUTE + "]").addBack(this.start_node);
      };

      AnnotationInserter.prototype.generate_stylesheet = function(types) {
        var $head, a, b, colour, css, g, match, r, style_tag, style_text, type;
        css = [];
        this.$iframe_doc.find("style[" + Constants.REPLACEMENT_ATTRIBUTE + "]").remove();
        for (type in types) {
          if (!__hasProp.call(types, type)) continue;
          colour = types[type];
          if (match = colour.match(/([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})?/i)) {
            r = parseInt(match[1], 16);
            g = parseInt(match[2], 16);
            b = parseInt(match[3], 16);
            a = match[4] ? parseInt(match[4], 16) / 255.0 : Constants.DEFAULT_OPACITY;
            css.push("." + Constants.ANNOTATION_ATTRIBUTE + "-" + type + "{background-color:rgba(" + r + "," + g + "," + b + "," + a + ");}");
            css.push("." + Constants.ANNOTATION_ATTRIBUTE + "-" + type + "[" + Constants.ACTIVE_ATTRIBUTE + "]{background-color:rgba(" + r + "," + g + "," + b + ",1);}");
          }
        }
        $head = this.$iframe_doc.find('head');
        style_tag = "<style " + Constants.REPLACEMENT_ATTRIBUTE + "='' type='text/css'/>";
        style_text = css.join('');
        return $(style_tag).text(style_text).prependTo($head);
      };

      AnnotationInserter.prototype.mark_node_positions = function(node) {
        var child, offset_memo, replacement, _i, _j, _len, _len1, _ref, _ref1;
        node[Constants.PROPERTY] = {
          b: this.offset
        };
        if (node.nodeType === node.TEXT_NODE) {
          this.offset += unicode_length(node.textContent);
        } else if (node.getAttribute && (replacement = node.getAttribute(Constants.REPLACEMENT_ATTRIBUTE)) !== null) {
          if (node.getAttribute(Constants.DISPLACEMENT_ATTRIBUTE) !== null) {
            offset_memo = this.offset;
            _ref = node.childNodes;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              child = _ref[_i];
              this.mark_node_positions(child);
            }
            this.offset = offset_memo + unicode_length(replacement);
          } else {
            this.offset += unicode_length(replacement);
          }
        } else {
          _ref1 = node.childNodes;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            child = _ref1[_j];
            this.mark_node_positions(child);
          }
        }
        node[Constants.PROPERTY].e = this.offset;
        if (node.setAttribute) {
          return node.setAttribute('s', "" + node[Constants.PROPERTY].b + "-" + node[Constants.PROPERTY].e);
        }
      };

      AnnotationInserter.prototype.find_correct_node = function(standoff, extent) {
        var displaced_extent, result;
        result = null;
        displaced_extent = 0;
        this.start_nodes.each((function(_this) {
          return function(_, start_node) {
            var displacement, displacement_amount;
            displacement = start_node.getAttribute(Constants.DISPLACEMENT_ATTRIBUTE);
            displacement_amount = parseInt(displacement, 10) - start_node[Constants.PROPERTY].b;
            displaced_extent = [extent[0] - (displacement_amount || 0), extent[1] - (displacement_amount || 0)];
            result = _this.drill_into_daughter_for(standoff, displaced_extent, start_node);
            if (result) {
              return false;
            }
          };
        })(this));
        return [result, displaced_extent];
      };

      AnnotationInserter.prototype.create_annotation_for = function(standoff) {
        var containing_node, extent, left_daughter_index, result, right_daughter_index, wrapping_indices, _i, _len, _ref, _ref1, _results;
        _ref = standoff[2];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          extent = _ref[_i];
          _ref1 = this.find_correct_node(standoff, extent), result = _ref1[0], extent = _ref1[1];
          if (!result) {
            continue;
          }
          containing_node = result[0], left_daughter_index = result[1], right_daughter_index = result[2];
          wrapping_indices = {
            b: left_daughter_index + 1,
            e: right_daughter_index
          };
          this.wrap_nodes(standoff, containing_node, wrapping_indices);
          this.drill_into_daughter_for(standoff, extent, containing_node, 1, true);
          _results.push(this.drill_into_daughter_for(standoff, extent, containing_node, 0, true));
        }
        return _results;
      };

      AnnotationInserter.prototype.add_annotation_attribute = function(node, ann_id, ann_type) {
        var present_annotations;
        present_annotations = node.getAttribute(Constants.ANNOTATION_ATTRIBUTE);
        present_annotations = present_annotations != null ? "" + present_annotations + " " + ann_id : ann_id;
        node.setAttribute(Constants.ANNOTATION_ATTRIBUTE, present_annotations);
        return $(node).addClass("" + Constants.ANNOTATION_ATTRIBUTE + "-" + ann_type);
      };

      AnnotationInserter.prototype.drill_into_daughter_for = function(standoff, extent, node, side, bottom) {
        var ann, child, child_count, child_index, child_node, child_pos, daughter_index, indices, inside, left_daughter_index, pos, real_child_index, text, wrap_node, _i, _j, _ref, _ref1, _ref2, _ref3, _ref4;
        pos = node[Constants.PROPERTY];
        if (node.nodeType === node.TEXT_NODE) {
          ann = {
            b: side === 1 ? pos.b : extent[0],
            e: side === 0 ? pos.e : extent[1]
          };
          if (ann.b === ann.e) {
            return;
          }
          if (ann.b !== pos.b) {
            text = unicode_substring(node.textContent, 0, ann.b - pos.b);
            child_node = document.createTextNode(text);
            child_node[Constants.PROPERTY] = {
              b: pos.b,
              e: ann.b
            };
            node.parentNode.insertBefore(child_node, node);
          }
          wrap_node = this.make_wrap_node(node, standoff);
          wrap_node[Constants.PROPERTY] = ann;
          node[Constants.PROPERTY] = ann;
          node.parentNode.insertBefore(wrap_node, node);
          if (ann.e !== pos.e) {
            text = unicode_substring(node.textContent, ann.e - pos.b);
            child_node = document.createTextNode(text);
            child_node[Constants.PROPERTY] = {
              b: ann.e,
              e: pos.e
            };
            node.parentNode.insertBefore(child_node, node);
          }
          node.textContent = unicode_substring(node.textContent, ann.b - pos.b, ann.e - pos.b);
          node.parentNode.removeChild(node);
          wrap_node.appendChild(node);
          return null;
        } else if (side != null) {
          daughter_index = null;
          child_count = node.childNodes.length;
          for (child_index = _i = 0; 0 <= child_count ? _i < child_count : _i > child_count; child_index = 0 <= child_count ? ++_i : --_i) {
            real_child_index = side ? child_index : child_count - child_index - 1;
            child = node.childNodes[real_child_index];
            child_pos = child[Constants.PROPERTY];
            inside = side ? (child_pos.b < (_ref = extent[1]) && _ref <= child_pos.e) : (child_pos.b <= (_ref1 = extent[0]) && _ref1 < child_pos.e);
            if (inside) {
              this.drill_into_daughter_for(standoff, extent, child, side);
              daughter_index = real_child_index;
              break;
            }
          }
          if (daughter_index == null) {
            console.warn("Error: " + (side ? 'right' : 'left') + " standoff position " + extent[side] + " is contained in the " + node.nodeName + " at " + pos.b + "-" + pos.e + ", but is not in any of its children.");
          }
          if (!bottom) {
            indices = side ? {
              b: 0,
              e: daughter_index
            } : {
              b: daughter_index + 1,
              e: node.childNodes.length
            };
            return this.wrap_nodes(standoff, node, indices);
          }
        } else if (pos.b === extent[0] && pos.e === extent[1] && node.getAttribute(Constants.REPLACEMENT_ATTRIBUTE)) {
          wrap_node = this.make_wrap_node(node, standoff);
          wrap_node[Constants.PROPERTY] = {
            b: pos.b,
            e: pos.e
          };
          node.parentNode.insertBefore(wrap_node, node);
          wrap_node.appendChild(node);
          return null;
        } else {
          left_daughter_index = null;
          for (child_index = _j = 0, _ref2 = node.childNodes.length; 0 <= _ref2 ? _j < _ref2 : _j > _ref2; child_index = 0 <= _ref2 ? ++_j : --_j) {
            child = node.childNodes[child_index];
            child_pos = child[Constants.PROPERTY];
            if (child_pos.b <= extent[0] && extent[1] <= child_pos.e) {
              return this.drill_into_daughter_for(standoff, extent, child);
            }
            if ((child_pos.b <= (_ref3 = extent[0]) && _ref3 < child_pos.e)) {
              left_daughter_index = child_index;
            } else if ((child_pos.b < (_ref4 = extent[1]) && _ref4 <= child_pos.e)) {
              return [node, left_daughter_index, child_index];
            }
          }
          return null;
        }
      };

      AnnotationInserter.prototype.wrap_nodes = function(standoff, node, indices) {
        var child, child_index, child_pos, wrap_node, _i, _ref, _ref1, _results;
        if (!indices) {
          indices = {
            b: 0,
            e: node.childNodes.length
          };
        }
        _results = [];
        for (child_index = _i = _ref = indices.b, _ref1 = indices.e; _ref <= _ref1 ? _i < _ref1 : _i > _ref1; child_index = _ref <= _ref1 ? ++_i : --_i) {
          child = node.childNodes[child_index];
          child_pos = child[Constants.PROPERTY];
          if (child.nodeType === child.TEXT_NODE) {
            wrap_node = this.make_wrap_node(child, standoff);
            wrap_node[Constants.PROPERTY] = {
              b: child_pos.b,
              e: child_pos.e
            };
            node.insertBefore(wrap_node, child);
            _results.push(wrap_node.appendChild(child));
          } else {
            _results.push(this.wrap_nodes(standoff, child));
          }
        }
        return _results;
      };

      AnnotationInserter.prototype.make_wrap_node = function(node, standoff) {
        var $node, display, wrap_node;
        $node = $(node);
        wrap_node = document.createElement('span');
        this.add_annotation_attribute(wrap_node, standoff[0], standoff[1]);
        display = node.style ? $(node).css('display') : $(node).attr('display');
        if (display) {
          $(wrap_node).css('display', display);
        }
        return wrap_node;
      };

      return AnnotationInserter;

    })();
  });

}).call(this);
