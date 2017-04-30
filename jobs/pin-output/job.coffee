http = require 'http'

class PinOutput
  constructor: ({@connector}) ->
    throw new Error 'PinOutput requires connector' unless @connector?

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.pinname is required') unless data?.pinname?
    return callback @_userError(422, 'data.value is required') unless data?.value?

    metadata =
      code: 200
      status: http.STATUS_CODES[200]

    @connector.writePin(data.pinname, parseInt(data.value))
      
    callback null, {metadata, data}

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = PinOutput
