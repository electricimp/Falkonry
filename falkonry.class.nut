class Falkonry {
    static version = [1, 0, 0];

    static DEFAULT_TIME_IDENTIFIER = "time";

    static ERR_DEFAULT = "Request to Falkonry failed";
    static ERR_DUPLICATE_RESOURCE = "Resouce with given name already exists";
    static ERR_INVALID_INPUT = "Request missing name or invalid input";
    static ERR_NOT_FOUND = "Resouce not available";
    static ERR_DATA_FORMAT = "Error formatting data";

    _token = null;
    _url = null;
    _headers = null;
    timeIdentifier = null;

    constructor(api_token, falkonry_url = null) {
        _token = api_token;
        _url = falkonry_url ? falkonry_url : "https://service.falkonry.io";

        timeIdentifier = DEFAULT_TIME_IDENTIFIER;
        setRequestHeaders();
    }

    /////////////// Event Buffer Functions //////////////////////

    function createEventBuffer(bufferSettings, cb = null) {
        // Set defaults for timestamp related settings if none passed in
        if(!("timeIdentifier" in bufferSettings)) bufferSettings.timeIdentifier <- timeIdentifier;
        if(!("timeFormat" in bufferSettings)) bufferSettings.timeFormat <- "iso_8601";

        local req = http.post(format("%s/eventBuffer", _url), _headers, http.jsonencode(bufferSettings));
        return _sendRequest(req, cb);

        // 201 Successful request
        // 409 Event buffer with given name already exists
        // 406 Missing name or invalid input data
    }

    function getEventBuffers(cb = null) {
        local req = http.get(format("%s/eventBuffer", _url), _headers);
        return _sendRequest(req, cb);

        // 200 Successful request
    }

    function getEventBuffer(id, cb = null) {
        local req = http.get(format("%s/eventBuffer/%s", _url, id), _headers);
        return _sendRequest(req, cb);

        // 200 Successful request
        // 404 No event buffer as identified exists
    }

    function deleteEventBuffer(id, cb = null) {
        local req = http.httpdelete(format("%s/eventBuffer/%s", _url, id), _headers);
        return _sendRequest(req, cb);

        // 204 Successful request
        // 404 No such buffer available
        // 409 Event buffer is in use for some pipeline
    }

    function addDataToEventBuffer(id, data, formatTS = true, cb = null) {
        if(typeof formatTS == "function") {
            cb = formatTS;
            formatTS = true;
        }
        // format data
        local textFormattedData = _formatData(data, formatTS);
        if(textFormattedData == null) {
            if(cb) cb(ERR_DATA_FORMAT, null);
            return;
        }

        // adjust content type to text
        local headers = _headers;
        headers["Content-Type"] <- "text/plain";

        local req = http.post(format("%s/eventBuffer/%s", _url, id), headers, textFormattedData);
        return _sendRequest(req, cb);

        // 202 Successful request
        // 404 No event buffer or subscription exists
    }

    /////////////// Pipeline Functions //////////////////////////

    function getPipelines(cb = null) {
        local req = http.get(format("%s/pipeline", _url), _headers);
        return _sendRequest(req, cb);
    }

    function getPipeline(id, cb = null) {
        local req = http.get(format("%s/pipeline/%s", _url, id), _headers);
        return _sendRequest(req, cb);
    }

    function createPipeline(pipelineSettings, cb = null) {
        local req = http.post(format("%s/pipeline", _url), _headers, http.jsonencode(pipelineSettings));
        return _sendRequest(req, cb);
    }

    function deletePipeline(id, cb = null) {
        local req = http.httpdelete(format("%s/pipeline/%s", _url, id), _headers);
        return _sendRequest(req, cb);
    }

    /////////////// Helper Functions ////////////////////////////

    function setRequestHeaders(headers = {}) {
        if(!("Authorization" in headers)) headers["Authorization"] <- "Token " + _token;
        if(!("Content-Type" in headers)) headers["Content-Type"] <- "application/json";
        _headers = headers;
        return this;
    }

    // use to set locally, this will not update an exsisting eventBuffer
    function setTimeIdentifier(tsKey) {
        timeIdentifier = tsKey;
        return this;
    }

    // gets local time identifier (used to format and send data to eventBuffer)
    function getTimeIdentifier() {
        return timeIdentifier
    }

    // formats an iso_8601 timestamp
    function formatTimeStamp(ts = null) {
        local d = ts ? date(ts) : date();
        return format("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.month+1, d.day, d.hour, d.min, d.sec)
    }

    /////////////// Private Functions ///////////////////////////

    function _sendRequest(request, cb) {
        request.sendasync(function(res) {
            local err, data;

            switch(res.statuscode) {
                case 200:
                case 201:
                case 202:
                case 204:
                    // request successful don't set an error
                    break;
                case 400:
                case 406:
                    err = format("%i: %s", res.statuscode, ERR_INVALID_INPUT);
                    break;
                case 404:
                    err = format("%i: %s", res.statuscode, ERR_NOT_FOUND);
                    break;
                case 409:
                    err = format("%i: %s", res.statuscode, ERR_DUPLICATE_RESOURCE);
                    // replace error with message? - delete buffer msg is "Event buffer is in use for some pipeline"
                    break;
                case 429:
                    // back off, wait 1s then resend request
                    imp.wakeup(1, function() {
                        _sendRequest(request, cb);
                    }.bindenv(this))
                    break;
                default:
                    err = format("%i: %s", res.statuscode, ERR_DEFAULT);
            }

            try {
                // don't decode an empty string
                data = (res.body == "") ? "" : http.jsondecode(res.body);
            } catch(e) {
                if (err == null) err = e;
            }

            if (cb) {
                cb(err, data);
            } else if (err) {
                server.error(err);
            }

        }.bindenv(this))
        return this;
    }

    // formats data into jsonencoded string
    // each datapoint is separated by a new line
    // checks that data includes timestamp
    // formats timestamp if formatTS parameter is true
    function _formatData(data, formatTS = true) {
        local formattedData = "";

        if(typeof data == "array") {
            foreach(reading in data) {
                if(typeof reading != "table" || !(timeIdentifier in reading)) {
                    formattedData = null;
                    break;
                }
                if(formatTS) {
                    reading[timeIdentifier] <- formatTimeStamp(reading[timeIdentifier]);
                }
                formattedData += ( http.jsonencode(reading) + "\n" );
            }
        } else if (typeof data == "table" && (timeIdentifier in reading)) {
            if(formatTS) {
                reading[timeIdentifier] <- formatTimeStamp(reading[timeIdentifier]);
            }
            formattedData = http.jsonencode(data);
        } else {
            formattedData = null;
        }
        return formattedData;
    }
}
