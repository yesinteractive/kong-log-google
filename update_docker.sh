read -p "Enter container ID or name: "  container
read -p "Enter working subdirectory /usr/local/share/lua/5.1/kong/plugins/"  dir


docker exec -it --user root $container mkdir /usr/local/share/lua/5.1/kong/plugins/$dir
echo "directory created or verified"
docker cp plugin/. $container:/usr/local/share/lua/5.1/kong/plugins/$dir
echo "contents copied to /usr/local/share/lua/5.1/kong/plugins/$dir"
docker exec -ti $container /bin/sh -c "KONG_PLUGINS='bundled,$dir' kong reload"
echo "Kong restarted"
