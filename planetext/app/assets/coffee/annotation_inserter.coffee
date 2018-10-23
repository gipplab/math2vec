window.x = (xpath) -> # DEBUG
  document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue

define ['jquery', 'constants'], ($, Constants) ->
  high_unicode_re = /[\ud800-\udbff](?=[\udc00-\udfff])/g
  unicode_length = (str) ->
    high_unicode_re.lastIndex = 0
    len = str.length
    len-- while high_unicode_re.exec(str)
    len
  unicode_substring = (str, from, to) ->
    high_unicode_re.lastIndex = 0
    limit = to || from
    while (m = high_unicode_re.exec(str)) && high_unicode_re.lastIndex <= limit
      from++ if high_unicode_re.lastIndex <= from
      to++ if to
    str.substring(from, to)

  class AnnotationInserter
    constructor: (data, @$iframe_doc) ->
      @start_node = @$iframe_doc[0].documentElement
      @offset = 0
      @generate_stylesheet(data.types)
      @mark_node_positions(@start_node)
      @start_nodes = @collect_start_nodes()
      @create_annotation_for(standoff) for standoff in data.standoffs

    collect_start_nodes: ->
      $(@start_node).
        find("[#{Constants.DISPLACEMENT_ATTRIBUTE}]").
        addBack(@start_node)

    generate_stylesheet: (types) ->
      css = []
      @$iframe_doc.find("style[#{Constants.REPLACEMENT_ATTRIBUTE}]").remove()
      for own type, colour of types
        if match = colour.match(/([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})?/i)
          r = parseInt(match[1], 16)
          g = parseInt(match[2], 16)
          b = parseInt(match[3], 16)
          a = if match[4] then parseInt(match[4], 16) / 255.0 else Constants.DEFAULT_OPACITY
          css.push ".#{Constants.ANNOTATION_ATTRIBUTE}-#{type}{background-color:rgba(#{r},#{g},#{b},#{a});}"
          css.push ".#{Constants.ANNOTATION_ATTRIBUTE}-#{type}[#{Constants.ACTIVE_ATTRIBUTE}]{background-color:rgba(#{r},#{g},#{b},1);}"
      $head = @$iframe_doc.find('head')
      style_tag = "<style #{Constants.REPLACEMENT_ATTRIBUTE}='' type='text/css'/>"
      style_text = css.join('')
      $(style_tag).text(style_text).prependTo($head)

    mark_node_positions: (node) ->
      node[Constants.PROPERTY] =
        b: @offset

      if node.nodeType == node.TEXT_NODE
        @offset += unicode_length(node.textContent)
      else if node.getAttribute and
          (replacement = node.getAttribute(Constants.REPLACEMENT_ATTRIBUTE)) != null
        if node.getAttribute(Constants.DISPLACEMENT_ATTRIBUTE) != null
          offset_memo = @offset
          @mark_node_positions(child) for child in node.childNodes
          @offset = offset_memo + unicode_length(replacement)
        else
          @offset += unicode_length(replacement)
      else
        @mark_node_positions(child) for child in node.childNodes

      node[Constants.PROPERTY].e = @offset
      if node.setAttribute # DEBUG
        node.setAttribute('s', "#{node[Constants.PROPERTY].b}-#{node[Constants.PROPERTY].e}") # DEBUG

    find_correct_node: (standoff, extent) ->
      result = null
      displaced_extent = 0
      @start_nodes.each (_, start_node) =>
        displacement = start_node.getAttribute(Constants.DISPLACEMENT_ATTRIBUTE)
        displacement_amount = parseInt(displacement, 10) - start_node[Constants.PROPERTY].b
        displaced_extent = [
          extent[0] - (displacement_amount || 0)
          extent[1] - (displacement_amount || 0)
        ]
        result = @drill_into_daughter_for(standoff, displaced_extent, start_node)
        if result
          return false
      [result, displaced_extent]

    create_annotation_for: (standoff) ->
      for extent in standoff[2]
        [result, extent] = @find_correct_node(standoff, extent)
        continue unless result
        [containing_node, left_daughter_index, right_daughter_index] = result

        wrapping_indices =
          b: left_daughter_index + 1
          e: right_daughter_index
        @wrap_nodes(standoff, containing_node, wrapping_indices)
        @drill_into_daughter_for(standoff, extent, containing_node, 1, true)
        @drill_into_daughter_for(standoff, extent, containing_node, 0, true)

    add_annotation_attribute: (node, ann_id, ann_type) ->
      present_annotations = node.getAttribute(Constants.ANNOTATION_ATTRIBUTE)
      present_annotations =
        if present_annotations?
          "#{present_annotations} #{ann_id}"
        else
          ann_id
      node.setAttribute(Constants.ANNOTATION_ATTRIBUTE, present_annotations)
      $(node).addClass("#{Constants.ANNOTATION_ATTRIBUTE}-#{ann_type}")

    drill_into_daughter_for: (standoff, extent, node, side, bottom) ->
      pos = node[Constants.PROPERTY]

      if node.nodeType == node.TEXT_NODE
        ann =
          b: if side == 1 then pos.b else extent[0]
          e: if side == 0 then pos.e else extent[1]

        return if ann.b == ann.e

        unless ann.b == pos.b
          text = unicode_substring(node.textContent, 0, ann.b - pos.b)
          child_node = document.createTextNode(text)
          child_node[Constants.PROPERTY] =
            b: pos.b
            e: ann.b
          node.parentNode.insertBefore(child_node, node)

        wrap_node = @make_wrap_node(node, standoff)
        wrap_node[Constants.PROPERTY] = ann
        node[Constants.PROPERTY] = ann
        node.parentNode.insertBefore(wrap_node, node)

        unless ann.e == pos.e
          text = unicode_substring(node.textContent, ann.e - pos.b)
          child_node = document.createTextNode(text)
          child_node[Constants.PROPERTY] =
            b: ann.e
            e: pos.e
          node.parentNode.insertBefore(child_node, node)

        node.textContent = unicode_substring(node.textContent, ann.b - pos.b, ann.e - pos.b)
        node.parentNode.removeChild(node)
        wrap_node.appendChild(node)
        return null
      else if side?
        daughter_index = null
        child_count = node.childNodes.length
        for child_index in [0...child_count]
          real_child_index =
            if side
              child_index
            else
              child_count - child_index - 1
          child = node.childNodes[real_child_index]
          child_pos = child[Constants.PROPERTY]
          inside =
            if side
              # right side
              child_pos.b < extent[1] <= child_pos.e
            else
              # left side
              child_pos.b <= extent[0] < child_pos.e
          if inside
            @drill_into_daughter_for(standoff, extent, child, side)
            daughter_index = real_child_index
            break
        unless daughter_index?
          console.warn "Error: #{if side then 'right' else 'left'} standoff position #{extent[side]} is contained in the #{node.nodeName} at #{pos.b}-#{pos.e}, but is not in any of its children."

        unless bottom
          indices =
            if side
              b: 0
              e: daughter_index
            else
              b: daughter_index + 1
              e: node.childNodes.length
          @wrap_nodes(standoff, node, indices)
      else if pos.b == extent[0] and pos.e == extent[1] and
          node.getAttribute(Constants.REPLACEMENT_ATTRIBUTE)
        wrap_node = @make_wrap_node(node, standoff)
        wrap_node[Constants.PROPERTY] =
          b: pos.b
          e: pos.e
        node.parentNode.insertBefore(wrap_node, node)
        wrap_node.appendChild(node)
        return null
      else
        left_daughter_index = null
        for child_index in [0...node.childNodes.length]
          child = node.childNodes[child_index]
          child_pos = child[Constants.PROPERTY]
          if child_pos.b <= extent[0] && extent[1] <= child_pos.e # TODO error here
            return @drill_into_daughter_for(standoff, extent, child)
          if child_pos.b <= extent[0] < child_pos.e
            left_daughter_index = child_index
          else if child_pos.b < extent[1] <= child_pos.e
            return [node, left_daughter_index, child_index]
        return null # nothing fits; maybe other start node?
        # assert:
        # console.warn "Error: standoff extent #{extent[0]}-#{extent[1]} is contained in the #{node.nodeName} at #{pos.b}-#{pos.e}, but is not in any of its children."

    wrap_nodes: (standoff, node, indices) ->
      indices = { b: 0, e: node.childNodes.length } unless indices
      for child_index in [indices.b...indices.e]
        child = node.childNodes[child_index]
        child_pos = child[Constants.PROPERTY]
        if child.nodeType == child.TEXT_NODE
          wrap_node = @make_wrap_node(child, standoff)
          wrap_node[Constants.PROPERTY] =
            b: child_pos.b
            e: child_pos.e
          node.insertBefore(wrap_node, child)
          wrap_node.appendChild(child)
        else
          @wrap_nodes(standoff, child)

    make_wrap_node: (node, standoff) ->
      $node = $(node)
      wrap_node = document.createElement('span')
      @add_annotation_attribute(wrap_node, standoff[0], standoff[1])
      display =
        if node.style
          $(node).css('display')
        else
          $(node).attr('display')
      if display
        $(wrap_node).css('display', display)
      wrap_node
