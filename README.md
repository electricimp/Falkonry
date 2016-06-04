#Falkonry

##TODO

- write documentation

```squirrel
API_TOKEN <- "<YOUR_API_TOKEN_HERE>";
falkonry <- Falkonry(API_TOKEN);

falkonry.createEventBuffer({"sourceId": "2377736938a609ee"}, function(err, res) {
    server.error(err)
    log(res)
})

falkonry.getEventBuffers(function(err, res) {
    server.error(err)
    log(res)
})

falkonry.getEventBuffer("f5gde055yfo54m", function(err, res) {
    server.error(err)
    log(res)
})

reading <- { "temp" : 24.7,
             "humid" : 32.5,
             "timeStamp" : time() };

falkonry.addDataToEventBuffer("f5gde055yfo54m", reading, function(err, res) {
    server.error(err)
    log(res)
})

falkonry.deleteEventBuffer("g9kk3tkp8cx1lg", function(err, res) {
    server.error(err)
    log(res)
})


falkonry.getPipelines(function(err, res) {
    server.error(err)
    log(res)
})

falkonry.getPipeline("9k5brfd1ilkg6n", function(err, res) {
    server.error(err)
    log(res)
})

falkonry.deletePipeline("9k5brfd1ilkg6n", function(err, res) {
    server.error(err)
    log(res)
})

table - must have these keys
pipelineSettings <-   { "name": "APITestPipeline", //unique string
                        "input": "57398u1gijgckj", //buffer id
                        "thingIdentifier" : "Env_Tail_1", //(automatically set to "thing" if singleThingId) must have this...
                        "singleThingID": "TQCt8aA7HkOl", //...or this
                        "inputList": [{ "name": "temp", should match slot name from buffer data table
                                        "valueType": { "type": "Numeric" },
                                        "eventType": { "type": "Samples" }
                                     },
                                     { "name": "humid", //should match slot name from buffer data table
                                        "valueType": { "type": "Numeric" },
                                        "eventType": { "type": "Samples" }
                                     }],
                        "assessmentList": [{ "name": "health",
                                            "inputList": [ "temp",
                                                            "humid" ]
                                         }],
                        "interval": { "duration": "PT1S" } //must have duration or field key
                      };
falkonry.createPipeline(pipelineSettings, function(err, res) {
    server.error(err)
    log(res)
})
```