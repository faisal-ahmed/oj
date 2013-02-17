
# oj
# ==============================================================================
# A unified templating framework for the people. Thirsty people.


# oj function
# ------------------------------------------------------------------------------
# Convert ojml to dom
oj = module.exports = (ojml) ->
  oj.toDOM ojml

# Keep a reference to ourselves for templates to see
oj.oj = oj

# oj.begin
# ------------------------------------------------------------------------------
oj.begin = module.exports = (page) ->

  # Defer dom manipulation until the page has loaded
  _readyOrLoad ->

    # Compile only the body and below
    compiled = oj.compile body:true, (require page)

    # Setup dom
    html = compiled.html

    # Replace html
    bodyEl = document.getElementsByTagName 'body'
    if bodyEl.length == 0
      console.error 'oj: <body> was not found'
      return

    bodyEl[0].outerHTML = html

    # Setup jquery events and awaken oj objects
    compiled.js()

    # Trigger events bound through oj.ready
    oj.ready()

# Helpers
# ------------------------------------------------------------------------------
# Loading with either ready or onload (whichever exists)
# Loads immediately if it is already loaded
_readyOrLoad = (fn) ->
  # Use jquery ready if it exists
  if $?
    $(fn)
  # Otherwise fall back to onload
  else
    # Add onload if it hasn't happened yet
    if document.readyState != "complete"
      prevOnLoad = window.onload
      window.onload = ->
        prevOnLoad?()
        fn()
    # Otherwise call the function
    else
      fn()
  return

oj.error = (message) ->
  red = oj.codes?.red ? ''
  reset = oj.codes?.red ? ''
  console.error "#{red}#{message}#{reset}"
  return

# oj.ready
# -----------------------------------------------------------------------------
_readyQueue = queue:[], loaded:false
oj.ready = (fn) ->
  # Call everything if no arguments
  if _.isUndefined fn
    _readyQueue.loaded = true
    while (f = _readyQueue.queue.shift())
      f()
  # Call load if already loaded
  else if _readyQueue.loaded
    f()
  # Queue function for later
  else
    _readyQueue.queue.push fn
  return

# ## oj.id
oj.id = (len, chars) ->
  'oj' + oj.guid len, chars

# ## oj.guid
_randomInteger = (min, max) ->
  return null if min == null or max == null or min > max
  diff = max - min;
  # random int from zero to number minus one
  rnd = Math.floor Math.random() * (diff + 1)
  rnd + min

_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".split ''
oj.guid = (len = 8, chars = _chars) ->
  # Default arguments
  base = chars.length

  # Calculate how many chars can be determined by each random call
  charsPerRand = Math.floor Math.log(Math.pow(2,31)-1) / Math.log(base)
  randMin = 0
  randMax = Math.pow(base, charsPerRand)-1

  # Calculate random chars by calling random the minimum number of times
  output = ""
  for i in [0...len]
    # Generate random number
    if i % charsPerRand == 0
      rand = _randomInteger randMin, randMax
    charNext = chars[rand % base]
    output += charNext
    rand = Math.floor(rand / base)

  output

# Register require.extension for .oj files in node
if require.extensions

  coffee = require 'coffee-script'
  fs = require new String('fs') # Hack to avoid pulling fs to client

  stripBOM = (c) -> if c.charCodeAt(0) == 0xFEFF then (c.slice 1) else c

  isCS = (code) -> -1 != code.search /(^\s*#|\n\s*#|-\>)/
  isJS = (code) -> -1 != code.search /var|function|((^|\n)\s*\/\/)/

  require.extensions['.oj'] = (module, filepath) ->
    # Compile as coffee-script or javascript
    code = stripBOM fs.readFileSync filepath, 'utf8'

    # Transform into coffee script if necessary
    try
      code = coffee.compile code, bare: true

    catch eCoffee

      eCoffee.message = "#{oj.codes?.red}coffee-script error in #{filepath}: #{eCoffee.message}#{oj.codes?.reset}"
      # Report it as a coffee-script error if we are pretty
      # sure it is
      if (isCS code) or not (isJS code)
        throw eCoffee

    # Compile javascript
    try
      code = "(function(){with(require('oj')){#{code}}}).call(this);"
      module._compile code, filepath

    catch eJS

      eJS.message = "#{oj.codes?.red}javascript error in #{filepath}: #{eJS.message}#{oj.codes?.reset}"
      throw eJS

root = @

oj.version = '0.0.7'

oj.isClient = true

# Export for NodeJS if necessary
if typeof module != 'undefined'
  exports = module.exports = oj
else
  root['oj'] = oj

# Utility: Helpers
# ------------------------------------------------------------------------------

ArrayP = Array.prototype
FuncP = Function.prototype
ObjP = Object.prototype

slice = ArrayP.slice
unshift = ArrayP.unshift

# Methods from [underscore.js](http://underscorejs.org/), because some methods just need to exist.
oj.__ = _ = {}
_.isUndefined = (obj) -> obj == undefined
_.isBoolean = (obj) -> obj == true or obj == false or toString.call(obj) == '[object Boolean]'
_.isNumber = (obj) -> !!(obj == 0 or (obj and obj.toExponential and obj.toFixed))
_.isString = (obj) -> !!(obj == '' or (obj and obj.charCodeAt and obj.substr))
_.isDate = (obj) -> !!(obj and obj.getTimezoneOffset and obj.setUTCFullYear)
_.isRegExp = (obj) -> toString.call(obj) == '[object RegExp]'
_.isFunction = (obj) -> typeof obj == 'function'
_.isArray = Array.isArray or (obj) -> toString.call(obj) == '[object Array]'
_.isElement = (obj) -> !!(obj and obj.nodeType == 1)
_.isCapitalLetter = (c) -> !!(c.match /[A-Z]/)
_.identity = (v) -> v
_.property = (obj, options = {}) ->
  # _.defaults options, configurable: false
  Object.defineProperty obj, options
_.has = (obj, key) -> Object.prototype.hasOwnProperty.call(obj, key)
_.keys = Object.keys || (obj) ->
  throw 'Invalid object' if obj != Object(obj)
  keys = [];
  for key of obj
    if _has obj, key
      keys[keys.length] = key;
  keys
_.values = (obj) ->
  throw 'Invalid object' if obj != Object(obj)
  out = []
  _.each obj, (v) -> out.push v
  out

_.flatten = (array, shallow) ->
  _.reduce array, ((memo, value) ->
    if _.isArray value
      return memo.concat(if shallow then value else _.flatten(value))
    memo[memo.length] = value
    memo
  ), []

_.reduce = (obj = [], iterator, memo, context) ->
  initial = arguments.length > 2
  if ArrayP.reduce and obj.reduce == ArrayP.reduce
    if context
      iterator = _.bind iterator, context
    return if initial then obj.reduce iterator, memo else obj.reduce iterator

  _.each obj, (value, index, list) ->
    if (!initial)
      memo = value
      initial = true
    else
      memo = iterator.call context, memo, value, index, list

  if !initial
    throw new TypeError 'Reduce of empty array with no initial value'
  memo

  ctor = ->
  _.bind = (func, context) ->
    if func.bind == FuncP.bind and FuncP.bind
      return FuncP.bind.apply func, slice.call(arguments, 1)
    throw new TypeError unless _.isFunction(func)
    args = slice.call arguments, 2
    return bound = ->
      unless this instanceof bound
        return func.apply context, args.concat(slice.call arguments)
      ctor.prototype = func.prototype
      self = new ctor
      result = func.apply self, args.concat(slice.call(arguments))
      if Object(result) == result
        return result
      self


_.sortedIndex = (array, obj, iterator = _.identity) ->
  low = 0
  high = array.length;
  while low < high
    mid = (low + high) >> 1;
    if iterator(array[mid]) < iterator(obj) then low = mid + 1 else high = mid;
  low

_.indexOf = (array, item, isSorted) ->
  return -1 unless array?
  if isSorted
    i = _.sortedIndex array, item
    return if array[i] == item then i else -1
  if (ArrayP.indexOf && array.indexOf == ArrayP.indexOf)
    return array.indexOf item
  for v, i in array
    if v == item
      return i
  -1

# _.create
# ------------------------------------------------------------------------------
# Abstract Object.create for older browsers
#
# Define this once to improve performance in older browsers
F = ->
_.create =
  # Check for existing native / shimmed Object.create
  if typeof Object.create == "function"
    # found native/shim, so use it
    Object.create

  # Based on Crockford shim
  else
    (o) ->
      # set the prototype of the function
      # so we will get `o` as the prototype
      # of the new object instance
      F.prototype = o

      # create a new object that inherits from
      # the `o` parameter
      child = new F()

      # clean up just in case o is really large
      F.prototype = null

      # send it back
      child

_.getPrototypeOf =
  if typeof Object.getPrototypeOf == "function"
    Object.getPrototypeOf
  else
    (o) -> o.proto || o.constructor.prototype

# Utility: Type Detection
# -----------------------

# _.isjQuery
_.isjQuery = (obj) -> !!(obj and obj.jquery)

# _.isBackbone
_.isBackbone = (obj) -> !!(obj and obj.on and obj.trigger and not _.isOJ obj)

# oj.isOJ
# Determine if obj is an OJ instance
oj.isOJ = (obj) -> !!(obj?.isOJ)

# Determine if object or array is empty
_.isEmpty = (obj) ->
  return obj.length == 0 if _.isArray obj
  for k of obj
    if _.has obj, k
      return false
  true

# typeOf: Mimic behavior of built-in typeof operator and integrate jQuery, Backbone, and OJ types
oj.typeOf = (any) ->

  return 'null' if any == null
  t = typeof any
  if t == 'object'
    if _.isArray any           then t = 'array'
    else if _.isRegExp any     then t = 'regexp'
    else if _.isDate any       then t = 'date'
    else if _.isBackbone any   then t = 'backbone'
    else if _.isjQuery any     then t = 'jquery'
    else if oj.isOJ any         then t = any.type
    else                       t = 'object'
  t

# Determine if obj is a vanilla object
_.isObject = (obj) -> (oj.typeOf obj) == 'object'

_.clone = (obj) ->
  # TODO: support cloning OJ instances
  # TODO: support options, deep: true
  return obj unless _.isObject obj
  if _.isArray obj then obj.slice() else _.extend {}, obj

oj.enum = (name, args) ->
  throw 'NYI'

# Utility: Iteration
# ------------------------------------------------------------------------

# _each(collection, iterator, context)
#
#     Iterate over collection or function. If a function
#     is encountered it is evaluated before iteration
#
#     collection    Array or Object to iterate over
#     iterator      Function to call on each step
#     context       (Optional) Object to pass as 'this' to iteration method

_.breaker = {}
_.each = (col, iterator, context) ->

  return if col == null
  if ArrayP.forEach and col.forEach == ArrayP.forEach
    col.forEach iterator, context
  else if _.isArray col
    for v, i in col
      if iterator.call(context, v, i, col) == _.breaker
        return _.breaker
  else
    for k, v of col
      if _.has col, k
        if iterator.call(context, v, k, col) == _.breaker
          return _.breaker

# _.map(collection, iterator, options = {})
#
#     Map over object or array If a function
#     is encountered it is evaluated before iteration
#
#     collection    Array or Object to iterate over
#     iterator      Function to call on each step
#     options
#       context       (Optional) Object to pass as 'this' to iteration method
#       context       (Optional) Boolean indicating  to pass as 'this' to iteration method

_.map = (obj, iterator, options = {}) ->

  context = options.context
  recurse = options.recurse
  evaluate = options.evaluate

  # Recurse if necessary
  iterator_ = iterator
  if recurse
    do (options) ->
      iterator_ = (v,k,o) ->
        options_ = _.extend (_.clone options), (key: k, object: v)
        _.map v, iterator, options_

  # Evaluate functions if necessary
  if _.isFunction obj

    # Functions pass through if evaluate isn't set
    return obj unless evaluate

    while evaluate and _.isFunction obj
      obj = obj()

  out = obj

  # Array case
  if _.isArray obj
    out = []
    return out unless obj
    return (obj.map iterator_, context) if ArrayP.map and obj.map == ArrayP.map
    _.each(obj, ((v, ix, list) ->
      out[out.length] = iterator_.call context, v, ix, list
    ))

    if obj.length == +obj.length
      out.length = obj.length

  # Object case
  else if _.isObject obj
    out = {}
    return out unless obj
    for k,v of obj
      # Returning undefined will omit the thing
      if (r = iterator_.call(context, v, k, obj)) != undefined
        out[k] = r
  # Basis of recursive case
  else
    return iterator.call context, obj, options.key, options.object,
  out

# _.extend
_.extend = (obj) ->
  _.each(slice.call(arguments, 1), ((source) ->
    for key, value of source
      obj[key] = value
  ))
  obj

# _.defaults
_.defaults = (obj) ->
  _.each(slice.call(arguments, 1), ((source) ->
    for prop of source
      if not obj[prop]?
        obj[prop] = source[prop]
  ))
  obj

_.uniqueSort = (array, isSorted = false) ->
  if not isSorted
    array.sort()
  out = []
  for item,ix in array
    if ix > 0 and array[ix-1] == array[ix]
      continue
    out.push item
  out

_.uniqueSortedUnion = (array, array2) ->
  _.uniqueSort (array.concat array2)

# oj.addMethod
# ------------------------------------------------------------------------------
oj.addMethods = (obj, mapNameToMethod) ->
  for methodName, method of mapNameToMethod
    oj.addMethod obj, methodName, method
  return

# oj.addMethod
# ------------------------------------------------------------------------------
oj.addMethod = (obj, methodName, method) ->
  throw 'oj.addMethod: string expected for second argument' unless _.isString methodName
  throw 'oj.addMethod: function expected for thrid argument' unless _.isFunction method
  Object.defineProperty obj, methodName,
    value: method
    enumerable: false
    writable: false
    configurable: true
  return

# oj.removeMethod
# ------------------------------------------------------------------------------
oj.removeMethod = (obj, methodName) ->
  throw 'oj.removeMethod: string expected for second argument' unless _.isString methodName
  delete obj[methodName]
  return

# oj.addProperties
# ------------------------------------------------------------------------------
oj.addProperties = (obj, mapNameToInfo) ->

  for propName, propInfo of mapNameToInfo
    # Prop value may be specified by an object with a get/set or by value
    # Examples:
    #   age: 7    # defaults to {writable:true, enumerable:true}
    #   age: {value:7, writable:false, enumerable:false}
    #   age: {get:(-> 7), enumerable:false}

    # Wrap the value if propInfo is not already a property definition
    if not propInfo?.get? and not propInfo?.value?
      propInfo = value: propInfo

    oj.addProperty obj, propName, propInfo

  return

# oj.addProperty
# ------------------------------------------------------------------------------
oj.addProperty = (obj, propName, propInfo) ->
  throw 'oj.addProperty: string expected for second argument' unless _.isString propName
  throw 'oj.addProperty: object expected for third argument' unless (_.isObject propInfo)
  throw 'oj.addProperty: get or value key expected in third argument' unless (propInfo.get? or propInfo.value?)

  _.defaults propInfo,
    enumerable: true
    configurable: true

  # Remove property if it already exists
  if obj[propName]?
    oj.removeProperty obj, propName

  # Add the property
  Object.defineProperty obj, propName, propInfo
  return

# oj.removeProperty
# ------------------------------------------------------------------------------

oj.removeProperty = (obj, propName) ->
  throw 'oj.addProperty: string expected for second argument' unless _.isString propName
  delete obj[propName]

# oj.isProperty
# ------------------------------------------------------------------------------
# Determine if the specified key is was defined by addProperty

oj.isProperty = (obj, propName) ->
  throw 'oj.isProperty: string expected for second argument' unless _.isString propName

  Object.getOwnPropertyDescriptor(obj, propName).get?

# oj.copyProperty
# ------------------------------------------------------------------------------
# Determine copy source.propName to dest.propName

oj.copyProperty = (dest, source, propName) ->
  info = Object.getOwnPropertyDescriptor source, propName
  Object.defineProperty dest, propName, info

# _.arguments
# ------------------------------------------------------------------------------
# Abstraction to wrap global arguments stack. This makes me sad but it is necessary for div -> syntax

# Stack of results
_.argumentsStack = []
# Result is top of the stack
oj.addProperty _, 'arguments', get: -> if _.argumentsStack.length then _.argumentsStack[_.argumentsStack.length-1] else null

# Push scope onto arguments
_.argumentsPush = (args = []) ->
  _.argumentsStack.push args
  return

# Pop scope from arguments
_.argumentsPop = ->
  if _.argumentsStack.length
    return _.argumentsStack.pop()
  null

# Append argument
_.argumentsAppend = (arg) ->
  if _.arguments
    _.arguments.push arg
  return

# oj.tag (name, attributes, content, content, ...)
# ------------------------------------------------------------------------------
#     name          String of the tag to serialize
#     attributes    (Optional) Object defining attributes of tag being serialized
#                   Keys have smart mappings:
#                       'c'  will map to 'class'
#                       'fontSize' will map to 'font-size'
#                       'borderRadius' will map to 'moz-border-radius', etc.


oj.tag = (name, args...) ->
  throw 'oj.tag error: argument 1 is not a string (expected tag name)' unless _.isString name

  # Build ojml starting with tag
  ojml = [name]

  # Get attributes from args by unioning all objects
  attributes = {}
  for arg in args
    # TODO: evaluate argument if necessary
    if _.isObject arg
      _.extend attributes, arg

  # Help the attributes out as they have shitting
  attributes = _tagAttributes name, attributes

  # Add attributes to ojml if they exist
  ojml.push attributes unless _.isEmpty attributes

  # Push arguments to build up children tags
  _.argumentsPush ojml

  # Loop over attributes
  for arg in args
    if _.isObject arg
      continue
    else if _.isFunction arg

      len = _.arguments.length

      # Call the argument it will auto append to _.arguments which is ojml
      r = arg()

      # Use return value if _.arguments weren't changed
      if len == _.arguments.length and r?
        _.argumentsAppend r

    else
      _.argumentsAppend arg

  # Pop to restore previous context
  _.argumentsPop()

  # Append the final result to your parent's arguments
  # if there exists an argument to append to
  _.argumentsAppend ojml

  ojml

oj.tag.elements =
  closed: 'a abbr acronym address applet article aside audio b bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dir div dl dt em embed fieldset figcaption figure font footer form frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins keygen kbd label legend li map mark menu meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small source span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video wbr xmp'.split ' '
  open: 'area base br col command css embed hr img input keygen link meta param source track wbr'.split ' '

oj.tag.elements.all = (oj.tag.elements.closed.concat oj.tag.elements.open).sort()

oj.tag.isClosed = (tag) ->
  (_.indexOf oj.tag.elements.open, tag, true) == -1

# Create tag methods
for t in oj.tag.elements.all
  do (t) ->
    oj[t] = -> oj.tag t, arguments...

# Customize a few tags

_defaultClear = (dest, d, e) ->
  _.defaults dest, d
  for k of e
    dest[k] = null
  dest

_tagAttributes = (name, attributes) ->
  attr = _.clone attributes
  switch name
    when 'link' then _defaultClear attr, {rel:'stylesheet', type:'text/css', href: attr.url or attr.src}, {url:0, src:0}
    when 'script' then _defaultClear attr, {type:'text/javascript', src: attr.url}, url:0
    when 'a' then _defaultClear attr, {href:attr.url}, url:0
  attr

# oj.styles = ()

# oj.extend (context)
# ------------------------------------------------------------------------------
#     Extend oj methods into a context. Common contexts are `global` `window`
#     and `this` (used in coffee script). Helper methods are not extended (oj._)
#
#     context          Object to extend oj methods and objects into

oj.extend = (context) ->
  o = {}
  for k,v of oj
    if k[0] != '_'
      o[k] = v
  delete o.extend
  _.extend context, o

# oj.compile
# ------------------------------------------------------------------------------
# Compile ojml into meaningful parts
# options
#     html:true           Compile to html
#     js:true             Compile to js
#     dom:true            Compile to dom
#     css:true            Compile to css
#     debug:true          Keep all source including comments
#     ignore:{html:1}     Map of tags to ignore while compiling
#     body:true           Shortcut to ignore all top level tags except body

oj.compile = (options, ojml) ->

  # Options is optional
  if not ojml?
    ojml = options
    options = {}

  options = _.defaults {}, options,
    html: false
    js: false
    dom: false
    css: false
    debug: false
    body: false
    ignore: {}

  options.html = if options.html then [] else null    # html accumulator
  options.dom = if options.dom then [] else null      # dom accumulator
  options.js = []                                     # code accumulator
  options.css = if options.css then {} else null      # css accumulator
  options.indent = ''                                 # indent counter
  options.types = []                                  # remember what types were used
  options.tags = {}                                   # remember what tags were used

  if options.body
    options.ignore = html:1,doctype:1,head:1,link:1,script:1,comment:1

  _compileAny ojml, options


  # Calculate css
  if options.css
    options.css = _cssFromObject options.css, options.debug

  # Join HTML only if the options ask for it
  html = options.html?.join ''

  out = html:html, types:options.types, dom:options.dom, css:options.css, tags:options.tags, js:->
    # Call defered javascript
    for fn in options.js
      fn()
    # Call awaken for all objects
    for t in options.types
      t.awaken()
    undefined

  out

_styleKeyFromFancy = (key) ->
  out = ""
  # Loop over characters in key looking for camal case
  for c in key
    if _.isCapitalLetter c
      out += "-#{c.toLowerCase()}"
    else
      out += c
  out

# _styleFromObject: Convert object to string form
# -----------------------------------------------------------------------------
#
#     inline:false      inline:true                inline:false,indent:true
#     color:red;        color:red;font-size:10px   \tcolor:red;
#     font-size:10px;                              \tfont-size:10px;
#

_styleFromObject = (obj, options = {}) ->
  _.defaults options,
    inline: true
    indent: false
  # Trailing semi should only exist on when we aren't indenting
  options.semi = !options.inline
  out = ""
  keys = _.keys(obj).sort()
  indent = if options.indent then '\t' else ''
  newline = if options.inline then '' else '\n'
  for kFancy,ix in keys
    # Add semi if it is not inline or it is not the last key
    semi = if options.semi or ix != keys.length-1 then ";" else ''
    k = _styleKeyFromFancy kFancy
    out += "#{indent}#{k}:#{obj[kFancy]}#{semi}#{newline}"
  out

# _attributesFromObject: Convert object to attribute string
# -----------------------------------------------------------------------------
# This object has nothing special. No renamed keys, no jquery events. It is
# precicely what must be serialized with no adjustment.
_attributesFromObject = (obj) ->
  # Pass through non objects
  return obj if not _.isObject obj

  out = ''
  # Serialize attributes in order for consistent output
  space = ''
  for k in _.keys(obj).sort()
    # Ignore null
    if (v = obj[k])?
      out += "#{space}#{k}=\"#{v}\""
    space = ' '
  out

# _cssFromObject:
# -----------------------------------------------------------------------------
# Convert css selectors and rules to a string
#
#     debug:true               debug:false
#     .cls {                   .cls{color: red}
#         color: red;
#     }

_cssFromObject = (cssMap, isDebug = false) ->
  newline = if isDebug then '\n' else ''
  space = if isDebug then ' ' else ''
  inline = !isDebug
  indent = isDebug
  css = ''
  for selector, styles of cssMap
    rules = _styleFromObject styles, inline:inline, indent:indent
    css += "#{selector}#{space}{#{newline}#{rules}}"
  css

# Recursive helper for compiling that wraps indention
_compileDeeper = (method, ojml, options) ->
  i = options.indent
  options.indent += '\t'
  method ojml, options
  options.indent = i

# Compile ojml or any type
pass = ->
_compileAny = (ojml, options) ->

  switch oj.typeOf ojml

    when 'array'
      _compileTag ojml, options

    when 'jquery'
      options.html?.push ojml[0].outerHTML

    when 'string'
      options.html?.push ojml

    when 'boolean', 'number'
      options.html?.push "#{ojml}"

    when 'function'
      _compileAny ojml(), options

    # Do nothing for 'null', 'undefined', 'object'
    when 'null' then break
    when 'undefined' then break
    when 'object' then break

    else
      # OJ type
      if oj.isOJ ojml
        _compileOJInstance ojml

  return

# Supported events from jquery
events = bind:1, on:1, off:1, live:1, blur:1, change:1, click:1, dblclick:1, focus:1, focusin:1, focusout:1, hover:1, keydown:1, keypress:1, keyup:1, mousedown:1, mouseenter:1, mousemove:1, mouseout:1, mouseup:1, ready:1, resize:1, scroll:1, select:1

# Compile ojml as oj object
_compileOJInstance = (ojml, options) ->
  console.log "complingOJInstance: ", ojml
  if options.html
    options.html.push ojml.toHTML options
  if options.dom
    options.dom.push ojml.toDOM options
  return

# Compile ojml as element
_compileElement = (ojml, options) ->
  console.log "complingElement: ", ojml
  if options.html
    options.html.push ojml.outerHTML;
  if options.dom
    options.dom.push ojml
  return

# Compile ojml tag (an array)
_compileTag = (ojml, options) ->

  # Get tag
  tag = ojml[0]

  # TODO: accept ojml with oj.Type instead of string for first element
  throw new Error('oj.compile: tag is missing in array') unless _.isString(tag) and tag.length > 0

  # Create oj object if tag is capitalized
  if _.isCapitalLetter tag[0]
    return _compileDeeper _compileAny, (new oj[tag] ojml.slice(1)), options

  # Record tag
  options.tags[tag] = true

  # Get attributes (optional)
  attributes = null
  if _.isObject ojml[1]
    attributes = ojml[1]

  children = if attributes then ojml.slice 2 else ojml.slice 1

  # Compile to css if requested
  if tag == 'css'
    if options.css
      # Extend options.css with rules
      for selector,styles of attributes
        options.css[selector] ?= styles
        _.extend options.css[selector], styles

  # Compile to html if requested
  else if not options.ignore[tag]

    # Alias c to class
    _attributeCMeansClass attributes

    # style takes objects
    _attributeStyleAllowsObject attributes

    # class takes arrays
    _attributeClassAllowsArrays attributes

    # filter out jquery events from attributes
    _attributesAllowEventBinding attributes, options

    # TODO: Consider jsoning anything that isn't a string
    # any keys that aren't strings are jsoned
    # _attributesJSONAllKeys attributes

    # Convert attributes to a string
    if options.html
      attr = _attributesFromObject attributes
      if attr?
        options.html.push "<#{tag} #{attr}>"
      else
        options.html.push "<#{tag}>"

    if options.dom and document?
      # Create element and set attributes
      el = document.createElement tag
      for attrName,attrValue of attributes
        el.setAttribute attrName, attrValue

      # Add self to parent
      options.dom.appendChild el

      # Push ourselves on the dom stack
      options.dom = el

  # Compile your children if necessary
  for child in children
    # Skip intention if there is only one child
    if options.debug && children.length > 1
      options.html?.push "\n\t#{options.indent}"
    _compileDeeper _compileAny, child, options

  # Skip intention if there is only one child
  if options.debug && children.length > 1
    options.html?.push "\n#{options.indent}"

  # End html tag if you have children or your tag closes
  if not options.ignore[tag]
    # Close tag if html
    if options.html and (children.length > 0 or oj.tag.isClosed(tag))
      options.html?.push "</#{tag}>"
    # Pop ourselves if dom
    if options.dom
      options.dom = options.dom.parentNode

  return

# Allow attributes to take style as an object
_attributeStyleAllowsObject = (attr) ->
  if _.isObject attr?.style
    attr.style = _styleFromObject attr.style, inline:true
  return

# Allow attributes to alias c to class
_attributeCMeansClass = (attr) ->
  if attr?.c?
    attr.class = attr.c
    delete attr.c
  return

# Allow attributes to take class as an array of strings
_attributeClassAllowsArrays = (attr) ->
  if _.isArray attr?.class
    attr.class = attr.join ' '
  return

# Allow attributes to overload jquery event bindings
# Filter those bindings out in the final result
_attributesAllowEventBinding = (attr, options) ->
  if attr
    # Filter out attributes that are events
    for k,v of attr
      do(k,v) ->
        # If this attribute (k) is an event
        if events[k]?
          # Ensure there is an attribute id
          attr.id ?= oj.id()
          # Bind event if jquery exists
          if $?
            # Event binding is a queued structure of js calls
            options.js?.push ->
              $el = $('#' + attr.id)
              if _.isArray v
                $el[k].apply @, v
              else
                $el[k](v)
              return
          else if oj.isClient
            console.error "oj: jquery is missing when binding a '#{k}' event"

          # Null out the event
          attr[k] = null

# oj.toDOM
# ------------------------------------------------------------------------------
# Make oj directly in the DOM

oj.toDOM = (options, ojml) ->
  # Options is optional
  if not _.isObject options
    ojml = options
    options = {}

  # Create dom not html
  _.extend options,
    dom: true
    js: true
    html: false
    css: false

  result = oj.compile options, ojml

  # Bind js if it exists
  result.js?()

  result.dom

# oj.toHTML
# ------------------------------------------------------------------------------
# Make oj directly to HTML. It will ignore all event bindings

oj.toHTML = (options, ojml) ->
  # Options is optional
  if not _.isObject options
    ojml = options
    options = {}

  # Create html only
  _.extend options,
    dom: false
    js: false
    html: true
    css: false

  (oj.compile options, ojml).html

# oj.toCSS
# ------------------------------------------------------------------------------
# Make oj directly to css. It will ignore all event bindings and html

oj.toCSS = (options, ojml) ->
  # Options is optional
  if not _.isObject options
    ojml = options
    options = {}

  # Create html only
  _.extend options,
    dom: false
    js: false
    html: false
    css: true

  (oj.compile options, ojml).css

# _.inherit
# ------------------------------------------------------------------------------
# Based on, but sadly, incompatable with coffeescript inheritance
_.inherit = (child, parent) ->

  # Copy class properties and methods
  for key of parent
    oj.copyProperty child, parent, key

  ctor = ->
  ctor:: = parent::
  child:: = new ctor()

  # Provide easy access for super methods
  # Example: @super.methodName(arguments...)
  child::super = parent::

  return

# oj.type
# ------------------------------------------------------------------------------

oj.type = (name, args = {}) ->

  throw 'oj.type: string expected for first argument' unless _.isString name
  throw 'oj.type: object expected for second argument' unless _.isObject args

  args.methods ?= {}
  args.properties ?= {}
  args.constructor ?= ->

  Out = new Function("""return function #{name}(){
    var _this = this;
    if ( !(this instanceof #{name}) )
      _this = new #{name};

    #{name}.prototype.constructor.apply(_this, arguments);

    return _this;
  }
  """
  )();

  # Alias 'extends' to 'inherits' for javascript folks
  args.extends ?= args.inherits

  # Inherit if necessary
  if args.extends?
    _.inherit Out, args.extends

  # Add the constructor and wrap it to automatically call super.constructor
  oj.addMethod Out::, 'constructor', ->

    # Call your super's constructor
    if args.extends?
      (args.extends)::constructor.apply @, arguments

    # Then call your own constructor
    try
      args.constructor.apply @, arguments
    catch e
      console.error "#{name}.constructor failed with: ", e
      throw e
    return @

  # Mark new type and its instances with a non-enumerable _type and _oj properties
  typeProps =
    type: {value:name, writable:false, enumerable:false}
    isOJ: {value:true, writable:false, enumerable:false}
  oj.addProperties Out, typeProps
  oj.addProperties Out::, typeProps

  # Add properties helper to instance and type
  propKeys = (_.keys args.properties).sort()
  if Out::properties?
    propKeys = _.uniqueSortedUnion Out::properties, propKeys
  properties = value:propKeys, writable:false, enumerable:false
  oj.addProperty Out, 'properties', properties
  oj.addProperty Out::, 'properties', properties

  # Add methods helper to instance and type
  methodKeys = (_.keys args.methods).sort()
  if Out::methods?
    methodKeys = _.uniqueSortedUnion Out::methods, methodKeys
  methods = value:methodKeys, writable:false, enumerable:false
  oj.addProperty Out, 'methods', methods
  oj.addProperty Out::, 'methods', methods

  # Add methods to the type
  _.extend args.methods,

    # set: Set all properties on the object at once
    set: (k,v) ->
      obj = k
      if not _.isObject k
        obj = {}
        obj[k] = v;
      for key,value of obj
        @[key] = value
      return

    # toJSON: Use properties to generate json
    toJSON: ->
      json = {}
      for prop in @properties
        json[prop] = @[prop]
      json

  # Add methods
  oj.addMethods Out::, args.methods

  # Add the properties
  oj.addProperties Out::, args.properties

  Out

# oj.view
# ------------------------------------------------------------------------------

oj.view = (name, args) ->
  throw 'oj.view: string expected for first argument' unless _.isString name
  throw 'oj.view: object expected for second argument' unless _.isObject args
  args.extends ?= oj.View
  oj.type name, args

# optionsUnion:
# Take arguments and tranform them into options and args.
# options is a union of all items in `arguments` that are objects
# args is a concat of all arguments that aren't objects in the same order
_.optionsUnion = (argList) ->
  obj = {}
  list = []
  for v in argList
    if _.isObject v
      obj = _.extend obj, v
    else
      list.push v
  options: obj, args: list

# oj.View
# ------------------------------------------------------------------------------
# Properties
#   $el           Reference el
#   attributes    Initialize from element, $(selector), or ojml

# Methods
#   css

oj.View = oj.type 'View',

  # Views are special objects map properties together. This is a union of arguments
  # With the remaining arguments becoming a list

  ###
    CheckBox is constructed
      => Its properties are set (and this makes the el)
      => value is storied in the dom element

      When it is pushed into the dom
        => Its dom.outerHTML is called?

      Later when you manipulate it on the client
      makeOrGet awakens it in place in the dom

  ###
  constructor: ->
    # Simplify arguments to a single object of properties and a single list of arguments
    {options, args} = _.optionsUnion arguments

    # Generate id if missing
    options.id ?= oj.id()
    @_id = options.id

    # Views act like tag methods and support the div -> syntax.
    # Append this to parent
    _.argumentsAppend @

    @set options
    return

  properties:
    el:
      # Getting an element is the key to OJ. It takes a few steps:
      get: ->
        # Step one: use the cached version if possible
        return @_el if _.isElement @_el

        # Step two: search for the element in the dom
        # This will "awaken" this object to allow live editing
        if document?
          @_el = document.getElementsById @_id
          return @_el if _.isElement @_el

        # Step three: create it ourselves
        ojml = @make()
        results = oj.compile(dom:true, ojml)
        results.js()
        results.dom

    $el:
      get: -> $(@el)

    # Read only generated oj-guid
    id: get: -> @_id

    attributes:
      get: -> @$el.attributes()
      set: -> @$el.attributes arguments...

    hidden:
      get: -> $el.css('display') == 'none'
      set: (v) -> if v then $el.hide() else $el.show()

  methods:
    # make: Return ojml that creates initial dom state
    # Override this to create your own structure
    make: ->
      ojml = oj.div c:"oj.#{oj.typeOf @}", id:oj.id()
      oj.toDOM ojml

    # Find sub elements via jquery selector
    $: -> @$el.find arguments...

    toHTML: (options) -> @el.outerHTML + (if options.debug then '\n' else '')

    toDOM: -> @el

    toString: -> @toHTML()

    # Detach element from dom
    detach: -> throw 'detach nyi'
      # The implementation is to set el manipulate it, and remember how to set it back

    # Attach element to dom where it use to be
    attach: -> throw 'attach nyi'
      # The implementation is to unset el from detach

# oj.CheckBox
# ------------------------------------------------------------------------------
# CheckBox control

oj.CheckBox = oj.type 'CheckBox'
  extends: oj.View
  # constructor: ->
  #   @set arguments...

  properties:

    value:
      get: -> @_value
      set: (v) -> @_value = v; return

    disabled:
      get: -> @el.disabled
      set: (v) -> @el.disabled = v; return

  methods:
    make: (props) ->
      oj.input id: oj.id(), c:@type, type:'checkbox'

    toString: ->
      @super.toString.apply @,arguments

# oj.List
# ------------------------------------------------------------------------------
# List control

# oj.List = oj.type 'List',
#   constructor: ->

#   methods:

# oj.Link
# ------------------------------------------------------------------------------
# oj.Link = class Link extends Control




