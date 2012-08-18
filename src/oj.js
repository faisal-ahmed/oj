// Generated by CoffeeScript 1.3.3
(function() {
  var ArrayP, FuncP, ObjP, oj, slice, t, unshift, _, _fn, _i, _len, _ref,
    __slice = [].slice;

  oj = module.exports;

  oj.version = '0.0.0';

  ArrayP = Array.prototype;

  FuncP = Function.prototype;

  ObjP = Object.prototype;

  slice = ArrayP.slice;

  unshift = ArrayP.unshift;

  oj._ = _ = {};

  _.isUndefined = function(obj) {
    return obj === void 0;
  };

  _.isBoolean = function(obj) {
    return obj === true || obj === false || toString.call(obj) === '[object Boolean]';
  };

  _.isNumber = function(obj) {
    return !!(obj === 0 || (obj && obj.toExponential && obj.toFixed));
  };

  _.isString = function(obj) {
    return !!(obj === '' || (obj && obj.charCodeAt && obj.substr));
  };

  _.isDate = function(obj) {
    return !!(obj && obj.getTimezoneOffset && obj.setUTCFullYear);
  };

  _.isRegExp = function(obj) {
    return toString.call(obj) === '[object RegExp]';
  };

  _.isFunction = function(obj) {
    return typeof obj === 'function';
  };

  _.isArray = Array.isArray || function(obj) {
    return toString.call(obj) === '[object Array]';
  };

  _.isElement = function(obj) {
    return !!(obj && obj.nodeType === 1);
  };

  _.has = function(obj, key) {
    return Object.prototype.hasOwnProperty.call(obj, key);
  };

  _.keys = Object.keys || function(obj) {
    var key, keys;
    if (obj !== Object(obj)) {
      throw 'Invalid object';
    }
    keys = [];
    for (key in obj) {
      if (_has(obj, key)) {
        keys[keys.length] = key;
      }
    }
    return keys;
  };

  _.values = function(obj) {
    var out;
    if (obj !== Object(obj)) {
      throw 'Invalid object';
    }
    out = [];
    _.each(obj, function(v) {
      return out.push(v);
    });
    return out;
  };

  _.flatten = function(array, shallow) {
    return _.reduce(array, (function(memo, value) {
      if (_.isArray(value)) {
        return memo.concat(shallow ? value : _.flatten(value));
      }
      memo[memo.length] = value;
      return memo;
    }), []);
  };

  _.reduce = function(obj, iterator, memo, context) {
    var ctor, initial;
    if (obj == null) {
      obj = [];
    }
    initial = arguments.length > 2;
    if (ArrayP.reduce && obj.reduce === ArrayP.reduce) {
      if (context) {
        iterator = _.bind(iterator, context);
      }
      if (initial) {
        return obj.reduce(iterator, memo);
      } else {
        return obj.reduce(iterator);
      }
    }
    _.each(obj, function(value, index, list) {
      if (!initial) {
        memo = value;
        return initial = true;
      } else {
        return memo = iterator.call(context, memo, value, index, list);
      }
    });
    if (!initial) {
      throw new TypeError('Reduce of empty array with no initial value');
    }
    memo;

    ctor = function() {};
    return _.bind = function(func, context) {
      var args, bound;
      if (func.bind === FuncP.bind && FuncP.bind) {
        return FuncP.bind.apply(func, slice.call(arguments, 1));
      }
      if (!_.isFunction(func)) {
        throw new TypeError;
      }
      args = slice.call(arguments, 2);
      return bound = function() {
        var result, self;
        if (!(this instanceof bound)) {
          return func.apply(context, args.concat(slice.call(arguments)));
        }
        ctor.prototype = func.prototype;
        self = new ctor;
        result = func.apply(self, args.concat(slice.call(arguments)));
        if (Object(result) === result) {
          return result;
        }
        return self;
      };
    };
  };

  _.isjQuery = function(obj) {
    return !!(obj && obj.jquery);
  };

  _.isBackbone = function(obj) {
    return !!(obj && obj.on && obj.trigger && !_.isOJ(obj));
  };

  _.isOJ = function(obj) {
    return !!(obj && _.isString(obj.ojtype));
  };

  _.isOJML = function(obj) {
    return !!(obj && _.isString(obj.oj));
  };

  _.isEmpty = function(obj) {
    var k;
    if (_.isArray(obj)) {
      return obj.length === 0;
    }
    for (k in obj) {
      if (_.has(obj, k)) {
        return false;
      }
    }
    return true;
  };

  _.typeOf = function(any) {
    var t;
    if (any === null) {
      return 'null';
    }
    t = typeof any;
    if (t === 'object') {
      if (_.isArray(any)) {
        t = 'array';
      } else if (_.isRegExp(any)) {
        t = 'regexp';
      } else if (_.isDate(any)) {
        t = 'date';
      } else if (_.isBackbone(any)) {
        t = 'backbone';
      } else if (_.isjQuery(any)) {
        t = 'jquery';
      } else if (_.isOJML(any)) {
        t = 'ojml';
      } else if (_.isOJ(any)) {
        t = any.ojtype;
      } else {
        t = 'object';
      }
    }
    return t;
  };

  _.isObject = function(obj) {
    return (_.typeOf(obj)) === 'object';
  };

  _.clone = function(obj) {
    if (!_.isObject(obj)) {
      return obj;
    }
    if (_.isArray(obj)) {
      return obj.slice();
    } else {
      return _.extend({}, obj);
    }
  };

  oj.create = function(name) {
    throw 'NYI';
  };

  _.breaker = {};

  _.each = function(col, iterator, context) {
    var i, k, v, _i, _len;
    if (col === null) {
      return;
    }
    if (ArrayP.forEach && col.forEach === ArrayP.forEach) {
      return col.forEach(iterator, context);
    } else if (_.isArray(col)) {
      for (i = _i = 0, _len = col.length; _i < _len; i = ++_i) {
        v = col[i];
        if (iterator.call(context, v, i, col) === _.breaker) {
          return _.breaker;
        }
      }
    } else {
      for (k in col) {
        v = col[k];
        if (_.has(col, k)) {
          if (iterator.call(context, v, k, col) === _.breaker) {
            return _.breaker;
          }
        }
      }
    }
  };

  _.map = function(obj, iterator, options) {
    var context, evaluate, iterator_, k, out, r, recurse, v;
    if (options == null) {
      options = {};
    }
    context = options.context;
    recurse = options.recurse;
    evaluate = options.evaluate;
    iterator_ = iterator;
    if (recurse) {
      (function(options) {
        return iterator_ = function(v, k, o) {
          var options_;
          options_ = _.extend(_.clone(options), {
            key: k,
            object: v
          });
          return _.map(v, iterator, options_);
        };
      })(options);
    }
    if (_.isFunction(obj)) {
      if (!evaluate) {
        return obj;
      }
      while (evaluate && _.isFunction(obj)) {
        obj = obj();
      }
    }
    out = obj;
    if (_.isArray(obj)) {
      out = [];
      if (!obj) {
        return out;
      }
      if (ArrayP.map && obj.map === ArrayP.map) {
        return obj.map(iterator_, context);
      }
      _.each(obj, (function(v, ix, list) {
        return out[out.length] = iterator_.call(context, v, ix, list);
      }));
      if (obj.length === +obj.length) {
        out.length = obj.length;
      }
    } else if (_.isObject(obj)) {
      out = {};
      if (!obj) {
        return out;
      }
      for (k in obj) {
        v = obj[k];
        if ((r = iterator_.call(context, v, k, obj)) !== void 0) {
          out[k] = r;
        }
      }
    } else {
      return iterator.call(context, obj, options.key, options.object);
    }
    return out;
  };

  _.extend = function(obj) {
    _.each(slice.call(arguments, 1), (function(source) {
      var key, value, _results;
      _results = [];
      for (key in source) {
        value = source[key];
        _results.push(obj[key] = value);
      }
      return _results;
    }));
    return obj;
  };

  _.defaults = function(obj) {
    _.each(slice.call(arguments, 1), (function(source) {
      var prop, _results;
      _results = [];
      for (prop in source) {
        if (!(obj[prop] != null)) {
          _results.push(obj[prop] = source[prop]);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }));
    return obj;
  };

  oj._result = null;

  oj.tag = function() {
    var arg, args, attributes, lastResult, len, name, ojml, r, _i, _len;
    name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (!_.isString(name)) {
      throw 'oj.tag error: argument 1 is not a string (expected tag name)';
    }
    attributes = {};
    if (args.length > 0 && _.isObject(args[0])) {
      attributes = args.shift();
    }
    ojml = [name];
    if (!_.isEmpty(attributes)) {
      ojml.push(attributes);
    }
    lastResult = oj._result;
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      arg = args[_i];
      if (_.isFunction(arg)) {
        oj._result = ojml;
        len = ojml.length;
        r = arg();
        if (len === ojml.length) {
          ojml.push(r);
        }
      } else {
        ojml.push(arg);
      }
    }
    oj._result = lastResult;
    if (oj._result) {
      oj._result.push(ojml);
    }
    return ojml;
  };

  oj.tag.elements = {
    closed: 'aa abbr acronym address applet article aside audio b bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dir div dl dt em embed fieldset figcaption figure font footer form frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins keygen kbd label legend li map mark menu meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small source span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video wbr xmp'.split(' '),
    open: 'area base br col command embed hr img input keygen link meta param source track wbr'.split(' ')
  };

  oj.tag.elements.all = (oj.tag.elements.closed.concat(oj.tag.elements.open)).sort();

  _ref = oj.tag.elements.all;
  _fn = function(t) {
    return oj[t] = function() {
      return oj.tag.apply(oj, [t].concat(__slice.call(arguments)));
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    t = _ref[_i];
    _fn(t);
  }

  oj.extend = function(context) {
    var k, o, v;
    o = {};
    for (k in oj) {
      v = oj[k];
      if (k[0] !== '_') {
        o[k] = v;
      }
    }
    delete o.extend;
    return _.extend(context, o);
  };

}).call(this);
