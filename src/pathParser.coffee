# Interpret the path because it can be a regular
# path, or a path pattern using a special path grammar.

module.exports =
  # Test to see if path name contains a segment that starts with an underscore.
  # Such a path is private to the current session and should not be stored
  # in persistent storage or synced with other clients.
  isPrivate: (name) -> /(?:^_)|(?:\._)/.test name

  regExp: (pattern) -> if pattern instanceof RegExp then pattern else
    new RegExp '^' + pattern.replace(/[.*]/g, (match, index) ->
      # Escape periods
      return if match is '.' then '\\.'
      # An asterisk matches any single path segment in the middle
      # and any path or paths at the end
      else if pattern.length - index is 1 then '(.+)' else '([^.]+)'
    ) + '$'

  fastLookup: (path, obj) ->
    for prop in path.split '.'
      return unless obj = obj[prop]
    return obj

  # Split the path at the first ocurrance of a wildcard
  split: (path) -> path.split /\.?[*(]/

  expand: (path) ->
    # Remove whitespace and line break characters
    path = path.replace /[\s\n]/g, ''
    # Return right away if path doesn't contain any groups
    return [path]  unless ~path.indexOf('(')

    # Break up path groups into a list of equivalent paths that contain
    # only names and *
    stack = {paths: paths = [''], out: out = []}
    while path
      unless match = /^([^,()]*)([,()])(.*)/.exec path
        return (val + path for val in out)
      pre = match[1]
      token = match[2]
      path = match[3]

      if pre
        paths = (val + pre for val in paths)
        unless token is '('
          out = if lastClosed then paths else out.concat paths

      lastClosed = false
      if token is ','
        stack.out = stack.out.concat paths
        {paths} = stack
      else if token is '('
        stack = {parent: stack, paths, out: out = []}
      else if token is ')'
        lastClosed = true
        paths = out = stack.out.concat paths
        stack = stack.parent

    return out
