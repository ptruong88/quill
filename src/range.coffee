#= underscore
#= require rangy/rangy-core

class TandemPosition
  constructor: (@node, @offset) ->
    while @node.childNodes.length > 0
      @node = @node.firstChild
      while @offset > @node.length
        @offset -= @node.length
        @node = @node.nextSibling
    @node = @node.parentNode


class TandemRange
  @getCurrent: (iframe) ->
    rangySelection = rangy.getIframeSelection(iframe)
    if !rangySelection.isBackwards()
      start = new TandemPosition(rangySelection.anchorNode, rangySelection.anchorOffset)
      end = new TandemPosition(rangySelection.focusNode, rangySelection.focusOffset)
    else
      start = new TandemPosition(rangySelection.focusNode, rangySelection.focusOffset)
      end = new TandemPosition(rangySelection.anchorNode, rangySelection.anchorOffset)
    return new TandemRange(iframe, start, end)

  # constructor: (@iframe, Number startIndex, Number endIndex) ->
  # constructor: (@iframe, Object start, Object end) ->
  constructor: (@iframe, @start, @end) ->
    # TODO initialize with index
    #if _.isNumber(@end)

    @iframeDoc = @iframe.contentWindow.document

  groupNodesByLine: ->
    range = rangy.createRangyRange(@iframe)
    range.setStart(@start.node.firstChild, @start.offset)
    range.setEnd(@end.node.firstChild, @end.offset)
    textNodes = _.map(range.getNodes([3]), (node) -> return node.parentNode)
    currentAncestor = 0
    arr = _.reduce(textNodes, (memo, node) ->
      ancestor = node.parentNode
      while ancestor.className != "line"
        ancestor = ancestor.parentNode
      if currentAncestor == ancestor
        memo[memo.length - 1].push(node)
      else
        memo.push([node])
        currentAncestor = ancestor
      return memo
    , [])
    return arr

  split: (position, before = true) ->
    newNode = @iframeDoc.createElement(position.node.tagName)
    beforeText = position.node.textContent.substring(0, position.offset)
    afterText = position.node.textContent.substring(position.offset)
    return if beforeText == '' || afterText == ''
    if before
      newNode.textContent = beforeText
      position.node.textContent = afterText
      position.node.parentNode.insertBefore(newNode, position.node)
    else
      position.node.textContent = beforeText
      newNode.textContent = afterText
      position.node.parentNode.insertBefore(newNode, position.node.nextSibling)

  splitBefore: ->
    this.split(@start, true)
    @end.offset -= @start.offset if @end.node == @start.node
    @start.offset -= @start.offset

  splitAfter: ->
    this.split(@end, false)

  splitEnds: ->
    this.splitBefore()
    this.splitAfter()


window.Tandem ||= {}
window.Tandem.Range = TandemRange
