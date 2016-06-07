# Falkonry

The [Falkonry](http://falkonry.com/start) service is used to transform signal data into real-time assessments of condition.  This library integrates with the Falkonry Condition Prediction API. To use this library you will need to sign up for a [Falkonry account](https://service.falkonry.io/).

**To add this library to your project, add** `#require "falkonry.class.nut:1.0.0"` **to the top of your agent code.**

## Class Usage

### Optional Callback Parameter

All Event Buffer and Pipeline methods make asynchonous requests to Falkonry and take an optional callback parameter.  The callback takes two required parameters: *error* and *response*.  If an error is not encountered the *error* parameter will be null. If the request is successful the *response* parameter will contain a table with the response body.

###Constructor: Falconry(*apiToken[, baseURL]*)

The constructor takes one required parameter: an API token used to authenticate all requests made to Falkonry, and one optional parameter: the base URL to use for each request.  If no URL is passed in "https://service.falkonry.io" will be used as the default.  To generate an API Token sign in to [Falkonry Service UI](https://service.falkonry.io), then click the *ADD TOKEN* button found under the Account -> Integration tab.

```squirrel
API_TOKEN <- "<YOUR_API_TOKEN_HERE>";
falkonry <- Falkonry(API_TOKEN);
```

## Class Methods

### createEventBuffer(*[bufferSettings, callback]*)

The *createEventBuffer()* method takes one required parameter: a settings table, and one optional parameter: a callback function. See the table below for event buffer settings details.  A successful response will contain a table with all the settings for the Event Buffer just created.

####Event Buffer Settings
| Key | Default | Required | Description |
| ----- | ---------- | ------------ | --------------- |
| name | N/A | Yes | An identifying name for the event buffer. It must be unique for the account and may be changed later. |
| timeIdentifier | Falkonry.timeIdentifier | Yes | The label in the input data table which represents timestamps for each event.  Note: This value should **always** be set using the *setTimeIdentifier()* method before creating an event buffer. |
| timeFormat | "iso_8601" | Yes | The format of the timestamps for each event in the input data |
| sourceId | N/A | No | An identifier used in an external system to identify this event buffer |

For more information on what settings to pass into *createEventBuffer()* see [Falconry API docs](http://help.falkonry.com/en/latest/connector/api/buffer/create.html).

```squirrel
agentID <- split(http.agenturl(), "/").pop();
eventBufferID <- null;

falkonry.setTimeIdentifier("ts");
falkonry.createEventBuffer({"name": agentID}, function(err, res) {
    if (err) server.error(err);
    if ("id" in res) eventBufferID = res.id;
    server.log(http.jsonencode(res));
})
```

### getEventBuffers(*[callback]*)

The *getEventBuffers()* method requests a list of event buffers from Falkonry, and takes one optional parameter: a callback function.

```squirrel
falkonry.getEventBuffers(function(err, res) {
    if (err) server.error(err);
    server.log(http.jsonencode(res));
})
```

### getEventBuffer(*eventBufferId[, callback]*)

The *getEventBuffer()* method requests the details of a specific event buffer. It takes one required parameter: the id of the event buffer, and one optional parameter: a callback function.

```squirrel
falkonry.getEventBuffer(eventBufferID, function(err, res) {
    if (err) server.error(err);
    server.log(http.jsonencode(res));
})
```

### deleteEventBuffer(*eventBufferId[, callback]*)

The *deleteEventBuffer()* method deletes a specific event buffer.  It takes one required parameter: the id of the event buffer, and one optional parameter: a callback function.

```squirrel
falkonry.deleteEventBuffer(eventBufferID, function(err, res) {
    if (err) server.error(err);
})
```

### addDataToEventBuffer(*eventBufferId, data,[, callback, formatTS]*)

The *addDataToEventBuffer()* method uploads data to the specified event buffer.  It takes two required parameters: the id of the event buffer and the data to be sent, and two optional parameters: a callback function and a boolean formatTS.  The data passed in can be either a table with a single reading, including a timeStamp with the slot name matching the *timeIdentifier*, or an array of readings.  By default the *formatTS* boolean is set to `true`, which will reformat a timestamp set using Electric Imp's *time()* method into an ISO8601 time format before being sent.

**Please note:** Falkonry only supports text formats for this endpoint, so the *Content-Type* header for this request will always be set to "text/plain", and all data is formatted into text before it is sent.

```squirrel
reading <- { "temp" : 24.7,
             "humid" : 32.5,
             "timeStamp" : time() };

falkonry.addDataToEventBuffer(eventBufferID, reading, function(err, res) {
    if (err) server.error(err);
})
```

### createPipeline(*pipelineSettings[, callback]*)

The *createPipeline()* method takes one required parameter: a settings table, and one optional parameter: a callback funciton.  No default settings are assigned. See the table below for pipeline setting details.  A successful response will contain a table with all the settings for the pipeline just created.

####Pipeline Settings
| Key  | Required | Description |
| ------ | ------------ | --------------- |
| name | Yes | An identifying name for the pipeline. It must be unique for the account and may be changed later. |
| input | Yes | The identifier of the event buffer used to supply inflow to this pipeline  |
| thingIdentifier | Either a *thingIdentifier* or a *singleThingID* must set | The slot in the input data table which identifies each individual unit or thing in the pipeline.  Automatically set to "thing" if singleThingID is passed in. |
| singleThingID | Either a *thingIdentifier* or a *singleThingID* must set | The identifier of the individual unit or thing in the pipeline |
| inputList | Yes | The list of signals referenced in the pipeline this list must match the uploaded data.  See example below for how to format the inputList. |
| assessmentList | Yes | The list of list of assessments desired from the pipeline. See example below for how to format the inputList. |
| interval | Yes | The minimum frequency at which assessment results are desired for the pipeline |
| sourceId | No | An identifier used in an external system to identify this pipleline |

For more information on what settings to pass into *createPipeline()* see [Falconry API docs](http://help.falkonry.com/en/latest/connector/api/pipeline/create.html).

```squirrel
agentID <- split(http.agenturl(), "/").pop();
pipelineID <- null;

pipelineSettings <-   { "name": "APITestPipeline",
                        "input": eventBufferID,
                        "thingIdentifier" : "thing",
                        "singleThingID": agentID,
                        "inputList": [{ "name": "temp", // must match a key from buffer event data table
                                        "valueType": { "type": "Numeric" }, // data format ("Numeric" for numbers, "Categorical" for strings or text)
                                        "eventType": { "type": "Samples" } // if data set is a sample or complete collection of data ("Samples" of sample of data, "Occurrences" for complete set of data)
                                     },
                                     { "name": "humid", // must match a key from buffer event data table
                                        "valueType": { "type": "Numeric" }, // data format ("Numeric" for numbers, "Categorical" for strings or text)
                                        "eventType": { "type": "Samples" } // if data set is a sample or complete collection of data ("Samples" of sample of data, "Occurrences" for complete set of data)
                                     }],
                        "assessmentList": [
                                            { "name": "health", // name of an assessment, cannot be changed once a revision is created
                                              "inputList": [ "temp" ] // the list of input signals that are used by Falkonry service to produce the assessment
                                            }
                                         ],
                        "interval": { "duration": "PT1S" } // The ISO 8601 formatted interval here specifies that an assessment is desired every second
                      };

falkonry.createPipeline(pipelineSettings, function(err, res) {
    if (err) server.error(err);
    if ("id" in res) pipelineID = res.id;
    server.log(http.jsonencode(res));
})
```

### getPipelines(*[callback]*)

The *getPipelines()* method requests a list of pipelines from Falkonry, and takes one optional parameter: a callback function.

```squirrel
falkonry.getPipelines(function(err, res) {
    if (err) server.error(err);
    server.log(http.jsonencode(res));
})
```

### getPipeline(*pipelineId[, callback]*)

The *getPipeline()* method requests the details of a specific pipeline. It takes one required parameter: the id of the pipeline, and one optional parameter: a callback function.

```squirrel
falkonry.getPipeline(pipelineID, function(err, res) {
    if (err) server.error(err);
    server.log(http.jsonencode(res));
})
```

### deletePipeline(*pipelineId[, callback]*)

The *deletePipeline()* method deletes a specific pipeline.  It takes one required parameter: the id of the pipeline, and one optional parameter: a callback function.

```squirrel
falkonry.deletePipeline(pipelineID, function(err, res) {
    if (err) server.error(err);
})
```

### setRequestHeaders(*[headers]*)

The *setRequestHeaders()* method takes one optional parameter: a table of headers.  If no table is passed default headers will be set: *Authorization* containing the API token and *Content-Type* set to "application/json".  The Falkonry constructor sets default headers.

```squirrel
headers <- {"Content-Type" : "text/plain"};
falkonry.setRequestHeaders(headers);
```

### setTimeIdentifier(*timeIdentifier*)

The *setTimeIdentifier()* method takes one required parameter: a string.  This is a locally stored string containing the label in the input data table which represents timestamps for each event, and is used to format event data being sent to Falkonry. If this method is not called the default string "timeStamp" will be used.  Note: this method will not update the *timeIdentifier* in an event buffer that has already been created.

```squirrel
falkonry.setTimeIdentifier("ts");
```

### getTimeIdentifier()

The *getTimeIdentifier()* method returns the locally stored string containing the label in the input data table which represents timestamps for each event.

```squirrel
server.log(getTimeIdentifier());
```

### formatTimeStamp(*[epochTimeStamp]*)

The *formatTimeStamp()* method takes one optional parameter: an epoch time stamp, and returns an ISO8601 formatted timestamp.  If no time stamp is passed in an ISO8601 formatted timestamp for the current time will be returned.

```squirrel
local ts = time();
local formattedTS = falkonry.formatTimeStamp(ts);
server.log(formattedTS);
```

## License
The Falkonry library is licensed under the [MIT License](./LICENSE).