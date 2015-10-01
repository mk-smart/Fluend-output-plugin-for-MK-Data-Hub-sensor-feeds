# Fluend output plugin for MK Data Hub sensor feeds
This is a simple [Fluentd](http://www.fluentd.org/) output plugin for fluentd that can send data (time/value) to a sensor stream in the MK Data Hub.
The plugin requires the ID of the feed and of the stream to post to, the API key to use and the data attribute to use for as the value to record. (see example below).

## Installation 
Copy the [mkdh.rb](mkdh.rb) file in the plugin directory of Fluentd and restart Fluentd

## Example
This example configuration sends the size and the code of requests from the logs of an apache server to two different streams of the same sensor feed on the MK Data Hub.

```xml
<source>
  type tail
  format apache
  path /var/log/apache2/access.log
  tag local.apache.access
</source>

<match local.apache.access>
  type copy
  <store>
    type mkdhs
    feedid 6xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx8
    streamid 0
    dhkey 9xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx3
    valueattr size
  </store>
  <store>
    type mkdhs
    feedid 6xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx8
    streamid 1
    dhkey 9xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx3
    valueattr code
  </store>
</match>
```
