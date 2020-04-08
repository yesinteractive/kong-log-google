# my_plugin_template

To manually install plugin, create directory and install in /usr/local/share/lua/5.1/kong/plugins directory on Kong node

If running in docker, the update_docker.sh script is useful for quickly copying over files to Kong containter to test.

Here are a couple of the key command if you choose to run manually

`# docker cp plugin/. $container:/usr/local/share/lua/5.1/kong/plugins/<plugin name>`

`# docker exec -it --user root <container id> /bin/sh`

`# KONG_PLUGINS=bundled,<plugin name> kong reload`
