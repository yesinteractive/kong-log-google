# Kong Plugin Log to Google Analytics

This Kong Plugin will log Kong activity to Google Analytics. Built off the Open Source Kong HTTP Logging plugin.

## Installation

### Manual

To manually install plugin, create directory called `/usr/local/share/lua/5.1/kong/plugins/log-google` on Kong node and copy contents of `/plugins` directory there.

Restart Kong and you're ready to go.

### luarocks

Verify Git is installed on your Kong Node then install via luarocks:

<pre>
$ apk add --no-cache git
$ luarocks install kong-log-google
</pre>


## Configuration

You can add the plugin on a service by executing the following request against the Kong admin API:

<pre>
$ curl -X POST http://kong:8001/services/SERVICE_NAME_OR_ID/plugins \
    --data "name=log-google" \
    --data "config.cid=555" \
    --data "config.tid=trackerid"
</pre>


| Parameter     | Default     | Description  |  Required  |
| ------------- |-------------|------------- |-------------| 
| cid   | 555 |  This is a unique user ID you can set for Google analytics | yes
| tid      | UA-someid      |   Your unique tracking ID, typically beings with UA-.... | yes

