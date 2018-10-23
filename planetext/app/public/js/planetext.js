(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['jquery', 'viewer', 'paper'], function($, Viewer, Paper) {
    var init_step;
    init_step = function() {
      var $attr, $dragged, $iframe, $inserted_row, $instance, $selects, $tag, $value, $word, COLUMN_KEYCODES, SELECTS, autosubmit, changes, delay_update_instances, delay_update_timer, delete_inserted_row, drag_mode, dragged_element_original_text, dragged_selector, drop_ok, fill_instances_by_word, get_selector, insert_row_timer, is_ctrl_down, is_mac, last_file, move_selector, move_vertically, num_selects, original_column, paper, scroll_into_ul_view, scroll_into_view, submit_changes, viewer;
      is_mac = window.navigator.platform === 'MacIntel';
      is_ctrl_down = function(evt) {
        if (is_mac) {
          return evt.metaKey;
        } else {
          return evt.ctrlKey;
        }
      };
      $tag = $('#tag');
      $attr = $('#attr');
      $word = $('#word');
      $value = $('#value');
      $instance = $('#instance');
      $iframe = $('iframe');
      $selects = $('.selects');
      autosubmit = $('#autosubmit').prop('checked');
      changes = [];
      viewer = new Viewer($iframe, app_url + 'css/papervu.css');
      fill_instances_by_word = function() {
        var $li, attr, data, index, matching, selected_attr, selected_tag, str, unique_values, words, _i, _len, _ref;
        matching = null;
        selected_tag = $tag.find('li.selected').text();
        if (!selected_tag) {
          return {};
        }
        selected_attr = $attr.find('li.selected').text();
        attr = unknowns[selected_tag][selected_attr];
        words = $word.find('li.selected');
        if (!words.length) {
          words = $word.find('li.selectcursor');
        }
        words.each(function() {
          var index, word, word_instances, _i, _len, _ref, _results, _results1;
          word = this.textContent;
          word_instances = attr[0][word];
          if (matching) {
            _results = [];
            for (index in matching) {
              if (_ref = parseInt(index, 10), __indexOf.call(word_instances, _ref) < 0) {
                _results.push(delete matching[index]);
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          } else {
            matching = {};
            _results1 = [];
            for (_i = 0, _len = word_instances.length; _i < _len; _i++) {
              index = word_instances[_i];
              _results1.push(matching[index] = true);
            }
            return _results1;
          }
        });
        if (!matching) {
          return {};
        }
        unique_values = {};
        _ref = Object.keys(matching);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          index = _ref[_i];
          data = attr[1][index];
          str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
          $li = $('<li>').text(str).appendTo($instance);
          if (data[0] === data[1]) {
            $li.addClass('empty');
          }
          unique_values[attr[1][index][3]] = true;
        }
        $instance.children().first().addClass('selected');
        return unique_values;
      };
      $selects.on('customselect', '.uniselect', function(evt, params) {
        var $li;
        $li = $(params.li);
        $li.closest('ul').find('li.selected').removeClass('selected');
        return $li.addClass('selected');
      });
      $selects.on('customselect', '.multiselect', function(evt, params) {
        var $li, $ul, selected;
        $li = $(params.li);
        $ul = $li.closest('ul');
        if (!params.noselect) {
          $ul.find('li.selectcursor').removeClass('selectcursor');
          $li.addClass('selectcursor');
          if (!params.ctrl) {
            $li.closest('ul').find('li.selected').removeClass('selected');
          }
          selected = $li.hasClass('selected');
          if (!selected) {
            return $li.addClass('selected');
          } else if (params.ctrl) {
            return $li.removeClass('selected');
          }
        }
      });
      $('#tag, #attr, #word').on('update', function(evt) {
        return $('#selector').text(get_selector());
      });
      $('#independent, #decoration, #object, #metainfo').on('update', function(evt) {
        return $('#selector').text($(evt.target).find('li.selected').text());
      });
      $selects.on('click', '.uniselect, .multiselect', function(evt) {
        var $ul;
        evt.stopPropagation();
        $ul = $(evt.target);
        $ul.find('li.selected').removeClass('selected');
        return $ul.trigger('update');
      });
      $selects.on('click', '.uniselect > li, .multiselect > li', function(evt) {
        var $ul;
        evt.stopPropagation();
        $ul = $(evt.target).closest('ul');
        $ul.trigger('customselect', {
          li: evt.target,
          ctrl: is_ctrl_down(evt)
        });
        return $ul.trigger('update');
      });
      $tag.on('update', function(evt) {
        var $li, attr, attr_name, data, known, selected_tag, str, _i, _len, _ref, _ref1;
        $attr.empty();
        $word.empty();
        $value.empty();
        $instance.empty();
        selected_tag = $tag.find('li.selected').text();
        if (selected_tag) {
          known = {};
          _ref = unknowns[selected_tag];
          for (attr_name in _ref) {
            attr = _ref[attr_name];
            if (attr_name !== '') {
              $('<li draggable="true">').text(attr_name).appendTo($attr);
            }
            _ref1 = attr[1];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              data = _ref1[_i];
              str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
              if (!known[str]) {
                $li = $('<li>').text(str).appendTo($instance);
                if (data[0] === data[1]) {
                  $li.addClass('empty');
                }
                known[str] = true;
              }
            }
          }
        }
        return delay_update_instances();
      });
      $attr.on('update', function(evt) {
        var $li, attr, attr_word, data, index, known, selected_attr, selected_tag, str, _i, _len, _ref;
        $word.empty();
        $value.empty();
        $instance.empty();
        selected_attr = $attr.find('li.selected').text();
        if (selected_attr) {
          selected_tag = $tag.find('li.selected').text();
          if (!selected_tag) {
            return;
          }
          attr = unknowns[selected_tag][selected_attr];
          known = {};
          for (attr_word in attr[0]) {
            $('<li draggable="true">').text(attr_word).appendTo($word);
            _ref = attr[0][attr_word];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              index = _ref[_i];
              data = attr[1][index];
              str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
              if (!known[str]) {
                $li = $('<li>').text(str).appendTo($instance);
                if (data[0] === data[1]) {
                  $li.addClass('empty');
                }
                known[str] = true;
              }
            }
          }
        }
        return delay_update_instances();
      });
      $word.on('update', function() {
        var unique_values, value, _i, _len, _ref;
        $value.empty();
        $instance.empty();
        unique_values = fill_instances_by_word();
        _ref = Object.keys(unique_values);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          value = _ref[_i];
          $('<li>').text(value).appendTo($value);
        }
        return delay_update_instances();
      });
      $value.on('update', function() {
        var $li, attr, data, known, selected_attr, selected_tag, selected_value, str, _i, _len, _ref;
        $instance.empty();
        selected_value = $value.find('li.selected').text();
        if (selected_value) {
          selected_tag = $tag.find('li.selected').text();
          selected_attr = $attr.find('li.selected').text();
          attr = unknowns[selected_tag][selected_attr];
          known = {};
          _ref = attr[1];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            data = _ref[_i];
            if (data[3] === selected_value) {
              str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
              if (!known[str]) {
                $li = $('<li>').text(str).appendTo($instance);
                if (data[0] === data[1]) {
                  $li.addClass('empty');
                }
                known[str] = true;
              }
            }
          }
        }
        fill_instances_by_word();
        return delay_update_instances();
      });
      delay_update_timer = null;
      delay_update_instances = function() {
        clearTimeout(delay_update_timer);
        return delay_update_timer = setTimeout(function() {
          return $instance.trigger('update');
        }, 300);
      };
      scroll_into_view = function($el) {
        var pos, third_of_height;
        third_of_height = $iframe.height() / 3;
        pos = $el.offset().top - $el.scrollTop();
        return $iframe[0].contentWindow.scrollTo(0, Math.max(0, pos - third_of_height));
      };
      last_file = null;
      paper = null;
      $instance.on('update', function() {
        var file, from, match, selected_instance, to, url, _;
        selected_instance = $instance.find('li.selected').text();
        if (!selected_instance) {
          selected_instance = $instance.find('li').first().text();
        }
        if (selected_instance) {
          match = /^(.*) \((\d+)-(\d+)\)$/.exec(selected_instance);
          _ = match[0], file = match[1], from = match[2], to = match[3];
          url = file === last_file ? null : (paper = new Paper(viewer), last_file = file, dataset_url + '/file/' + file);
          return paper.load(url, {
            types: {
              Instance: '#ff9999ff'
            },
            standoffs: [['T1', 'Instance', [[from, to]]]]
          }, function($iframe_doc) {
            var $el;
            $el = $iframe_doc.find('[kmcs-a]').first();
            if ($el.length) {
              return scroll_into_view($el);
            }
          });
        } else {
          return $iframe.attr('src', 'about:blank');
        }
      });
      SELECTS = ['tag', 'attr', 'word', 'value', 'instance', 'independent', 'decoration', 'object', 'metainfo'];
      COLUMN_KEYCODES = {
        85: false,
        73: 'independent',
        68: 'decoration',
        79: 'object',
        77: 'metainfo',
        48: false,
        49: 'independent',
        50: 'decoration',
        51: 'object',
        52: 'metainfo'
      };
      num_selects = SELECTS.length;
      $('.selects ul:not(#options)').on('keydown', function(evt) {
        var $this, pass_through;
        pass_through = false;
        $this = $(this);
        switch (evt.keyCode) {
          case 37:
            $this.trigger('movehorizontally', -1);
            break;
          case 39:
            $this.trigger('movehorizontally', +1);
            break;
          case 38:
            $this.trigger('movevertically', -1);
            break;
          case 40:
            $this.trigger('movevertically', +1);
            break;
          case 32:
            $this.trigger('togglecurrent');
            break;
          case 13:
            if (!autosubmit) {
              submit_changes();
            }
            break;
          default:
            pass_through = true;
        }
        if (!pass_through) {
          evt.stopPropagation();
          return evt.preventDefault();
        }
      });
      move_vertically = function($ul, dir, klass) {
        var $li, $next_li;
        $li = $();
        if (klass === 'selectcursor') {
          $li = $ul.find('li.selectcursor');
        }
        if (!$li.length) {
          $li = $ul.find('li.selected').first();
        }
        if (!$li.length) {
          $li = $ul.find('li:first-child');
        }
        $next_li = dir === +1 ? $li.next() : dir === -1 ? $li.prev() : $li;
        if ($next_li.length) {
          $li.removeClass(klass);
          $next_li.addClass(klass);
          $ul.trigger('update');
          return scroll_into_ul_view($next_li);
        }
      };
      scroll_into_ul_view = function($el) {
        var el, par, par_bottom, par_top, pos;
        par = $el.closest('ul')[0];
        el = $el[0];
        par_top = par.scrollTop;
        par_bottom = par_top + par.clientHeight - el.clientHeight;
        pos = el.offsetTop - par.offsetTop;
        if (pos < par_top) {
          return el.scrollIntoView(true);
        } else if (pos > par_bottom) {
          return el.scrollIntoView(false);
        }
      };
      $selects.on('movevertically', '.uniselect', function(evt, dir) {
        return move_vertically($(this), dir, 'selected');
      });
      $selects.on('movevertically', '.multiselect', function(evt, dir) {
        return move_vertically($(this), dir, 'selectcursor');
      });
      $selects.on('movehorizontally', 'ul', function(evt, dir) {
        var $next_ul, current_index, next_id;
        current_index = SELECTS.indexOf($(this).prop('id'));
        next_id = SELECTS[(current_index + num_selects + dir) % num_selects];
        $next_ul = $("#" + next_id);
        $next_ul.focus();
        $next_ul.trigger('movevertically', 0);
        return $next_ul.trigger('update');
      });
      $selects.on('togglecurrent', '.multiselect', function(evt, dir) {
        var $li, $ul;
        $ul = $(this);
        $li = $ul.find('li.selectcursor');
        $li.toggleClass('selected');
        return $ul.trigger('update');
      });
      get_selector = function() {
        var selected_attr, selected_tag, selected_words;
        selected_tag = $tag.find('li.selected').text();
        selected_attr = $attr.find('li.selected').text();
        selected_words = $word.find('li.selected').map(function() {
          return $(this).text();
        });
        if (!selected_words.length) {
          selected_words = $word.find('li.selectcursor').map(function() {
            return $(this).text();
          });
        }
        if (selected_words.length) {
          return "" + selected_tag + "[" + selected_attr + ": " + (selected_words.get().join(' ')) + "]";
        } else if (selected_attr.length) {
          return "" + selected_tag + "[" + selected_attr + "]";
        } else {
          return selected_tag;
        }
      };
      $inserted_row = $();
      move_selector = function(selector, current_column, $target) {
        var $ul, change, pos, target_column, target_tagged;
        $ul = $target.closest('ul');
        target_column = $ul.prop('id');
        target_tagged = $ul.closest('.selects').hasClass('tagged');
        if (target_tagged) {
          if (!$target.hasClass('inserted')) {
            delete_inserted_row();
            $inserted_row = $('<li class="inserted"></li>').appendTo($ul);
          }
          $inserted_row.text(dragged_selector);
        } else {
          target_column = null;
        }
        pos = $target.hasClass('inserted') ? $target.index() : -1;
        $("#" + current_column).find('li.selected').remove();
        if (current_column !== 'independent' && current_column !== 'decoration' && current_column !== 'object' && current_column !== 'metainfo') {
          current_column = null;
        }
        change = {
          previous: current_column,
          column: target_column,
          pos: pos,
          selector: selector
        };
        changes.push(change);
        if (autosubmit) {
          return submit_changes();
        }
      };
      submit_changes = function() {
        var data;
        data = {
          changes: JSON.stringify(changes)
        };
        $.post(dataset_url + '/step', data, (function() {
          return location.reload(true);
        }));
        return changes = [];
      };
      dragged_element_original_text = null;
      insert_row_timer = null;
      $dragged = null;
      drop_ok = false;
      dragged_selector = null;
      original_column = null;
      drag_mode = null;
      delete_inserted_row = function() {
        $inserted_row.remove();
        return $inserted_row = $();
      };
      $('#tag, #attr, #word').on('dragstart', 'li', function(evt) {
        var $ul, noselect;
        $('#independent, #decoration, #object, #metainfo').addClass('droppable');
        drop_ok = false;
        $dragged = $(evt.target);
        $ul = $dragged.closest('ul');
        original_column = $ul.prop('id');
        noselect = $dragged.hasClass('selected');
        $ul.trigger('customselect', {
          li: $dragged,
          noselect: noselect
        });
        $ul.trigger('update');
        dragged_element_original_text = $dragged.text();
        dragged_selector = get_selector();
        return $dragged.text(dragged_selector);
      });
      $('#independent, #decoration, #object, #metainfo').on('dragstart', 'li', function(evt) {
        var $ul, noselect;
        drop_ok = false;
        $dragged = $(evt.target);
        $ul = $dragged.closest('ul');
        original_column = $ul.prop('id');
        noselect = $dragged.hasClass('selected');
        $ul.trigger('customselect', {
          li: $dragged,
          noselect: noselect
        });
        dragged_selector = $dragged.text();
        return $("#tag, #attr, #word, #independent, #decoration, #object, #metainfo").addClass('droppable');
      });
      $selects.on('drag', 'li', function(evt) {
        if (dragged_element_original_text) {
          $dragged = $(evt.target);
          $dragged.text(dragged_element_original_text);
          return dragged_element_original_text = null;
        }
      });
      $selects.on('dragover', '.droppable, .droppable li', function(evt) {
        return evt.preventDefault();
      });
      $selects.on('dragenter', 'li:not(.inserted)', function(evt) {
        if ($(evt.target).closest('.selects').hasClass('untagged')) {
          return;
        }
        clearTimeout(insert_row_timer);
        return insert_row_timer = setTimeout((function() {
          delete_inserted_row();
          return $inserted_row = $('<li class="inserted">&nbsp;</li>').insertBefore(evt.target);
        }), 500);
      });
      $selects.on('dragleave', '.inserted', function(evt) {
        delete_inserted_row();
        clearTimeout(insert_row_timer);
        return insert_row_timer = null;
      });
      $selects.on('drop', '.droppable li, .droppable', function(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        move_selector(dragged_selector, original_column, $(evt.target));
        $inserted_row = $();
        original_column = null;
        return drop_ok = true;
      });
      $selects.on('dragend', function(evt) {
        $('.droppable').removeClass('droppable');
        if (!drop_ok) {
          delete_inserted_row();
        }
        return clearTimeout(insert_row_timer);
      });
      $selects.on('keyup', '#tag, #attr, #word, #independent, #decoration, #object, #metainfo', function(evt) {
        var $target_column, $ul, current_column, effective_current_column, selector, target_column;
        target_column = COLUMN_KEYCODES[evt.which];
        if (target_column === void 0) {
          return;
        }
        $ul = $(evt.target);
        effective_current_column = current_column = $ul.prop('id');
        if (current_column !== 'independent' && current_column !== 'decoration' && current_column !== 'object' && current_column !== 'metainfo') {
          effective_current_column = null;
        }
        if (!(current_column || target_column)) {
          return;
        }
        if (current_column === 'word' && !$ul.find('li.selected').length) {
          $ul.trigger('togglecurrent');
        }
        selector = effective_current_column ? $ul.find('li.selected').text() : get_selector();
        $target_column = $("#" + target_column);
        move_selector(selector, current_column, $target_column);
        $('<li class="inserted"></li>').text(selector).appendTo($target_column);
        evt.preventDefault();
        evt.stopPropagation();
        return false;
      });
      $('#autosubmit').on('change', function(evt) {
        autosubmit = $(evt.target).prop('checked');
        if (autosubmit) {
          submit_changes();
        }
        $('#submit').prop('disabled', autosubmit);
        return $.post(app_url + '/config', {
          autosubmit: autosubmit
        });
      });
      $('#doc_limit_form').on('submit', function(evt) {
        var doc_limit;
        doc_limit = $('#doc_limit').val();
        $.post(app_url + '/config', {
          doc_limit: doc_limit
        }, function() {
          return submit_changes();
        });
        return false;
      });
      $('#submit').click(function(evt) {
        return submit_changes();
      });
      return $tag.focus().find('li:first-child').addClass('selected').trigger('update');
    };
    return {
      init_step: init_step
    };
  });

}).call(this);
