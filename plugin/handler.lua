-- Kong Log Google Plugin
local basic_serializer = require "kong.plugins.log-serializers.basic"
local BatchQueue = require "kong.tools.batch_queue"
local cjson = require "cjson"
local url = require "socket.url"
local http = require "resty.http"


local cjson_encode = cjson.encode
local ngx_encode_base64 = ngx.encode_base64
local table_concat = table.concat
local fmt = string.format

local HttpLogHandler2 = {}

HttpLogHandler2.PRIORITY = 12
HttpLogHandler2.VERSION = "2.0.0"

local queues = {} -- one queue per unique plugin config

local parsed_urls_cache = {}



-- Parse host url.
-- @param `url` host url
-- @return `parsed_url` a table with host details:
-- scheme, host, port, path, query, userinfo
local function parse_url(host_url)
    local parsed_url = parsed_urls_cache[host_url]

    if parsed_url then
        return parsed_url
    end

    parsed_url = url.parse(host_url)
    if not parsed_url.port then
        if parsed_url.scheme == "http" then
            parsed_url.port = 80
        elseif parsed_url.scheme == "https" then
            parsed_url.port = 443
        end
    end
    if not parsed_url.path then
        parsed_url.path = "/"
    end

    parsed_urls_cache[host_url] = parsed_url

    return parsed_url
end

-- Sends the provided payload (a string) to the configured plugin host
-- @return true if everything was sent correctly, falsy if error
-- @return error message if there was an error
local function send_payload(self, conf, payload, ua, ip, getpath)
    local method = "POST"
    local timeout = 60000
    local keepalive = 60000
    local content_type = "application/x-www-form-urlencoded"

    local ok, err
    local parsed_url = parse_url(conf.http_endpoint)
    local host = parsed_url.host
    local port = tonumber(parsed_url.port)

    local httpc = http.new()
    httpc:set_timeout(timeout)
    ok, err = httpc:connect(host, port)
    if not ok then
        return nil, "failed to connect to " .. host .. ":" .. tostring(port) .. ": " .. err
    end

    if parsed_url.scheme == "https" then
        local _, err = httpc:ssl_handshake(true, host, false)
        if err then
            return nil, "failed to do SSL handshake with " .. host .. ":" .. tostring(port) .. ": " .. err
        end
    end
    local bodyis = "v=1&t=pageview&tid="..conf.tid .. "&cid=" .. conf.cid .. "&dp=/" .. getpath .. "&ua=" .. ua .. "&uip=" .. ip
    local res, err =
        httpc:request(
        {
            method = "POST",
            path = "/collect",
            body = bodyis,
            --    conf.tid .. "&cid=" .. conf.cid .. "&dp=" .. getpath .. "&ua=" .. ua .. "&uip=" .. ip,
            --   body = "v=1&t=pageview&tid="..conf.tid.."&cid="..conf.cid.."&dp="..kong.request.get_path().."&ua="..kong.request.get_header("Host").."&uip="..kong.client.get_ip(),
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
        }
    )
    if not res then
        return nil, "failed request to " .. host .. ":" .. tostring(port) .. ": " .. err
    end
    kong.log.debug("request to google: " .. bodyis .. res:read_body())
    -- always read response body, even if we discard it without using it on success
    local response_body = res:read_body()
    local success = res.status < 400
    local err_msg

    if not success then
        err_msg =
            "request to " ..
            host ..
                ":" ..
                    tostring(port) .. " returned status code " .. tostring(res.status) .. " and body " .. response_body
    end

    ok, err = httpc:set_keepalive(keepalive)
    if not ok then
        -- the batch might already be processed at this point, so not being able to set the keepalive
        -- will not return false (the batch might not need to be reprocessed)
        kong.log.err("failed keepalive for ", host, ":", tostring(port), ": ", err)
    end

    return success, err_msg
end

local function json_array_concat(entries)
    return "[" .. table_concat(entries, ",") .. "]"
end

local function get_queue_id(conf)
    conf.http_endpoint = "https://www.google-analytics.com/collect"
    conf.method = "POST"
    conf.content_type = "application/x-www-form-urlencoded"
    conf.timeout = 10000
    conf.keepalive = 60000
    conf.retry_count = 2
    conf.queue_size = 1
    conf.flush_timeout = 10
    return fmt(
        "%s:%s",
        conf.cid,
        conf.tid


    )
end

-- #### ACCESS PHASE
-- #### ACCESS PHASE
-- #### ACCESS PHASE
-- #### ACCESS PHASE
function HttpLogHandler2:access(conf)
    

end

-- #### LOG PHASE
-- #### LOG PHASE
-- #### LOG PHASE
-- #### LOG PHASE
function HttpLogHandler2:log(conf)
    local entry = cjson_encode(basic_serializer.serialize(ngx))
    local ua = kong.request.get_header("User-Agent")
    local ip = kong.client.get_ip()
    local getpath = kong.request.get_path()
    local queue_id = get_queue_id(conf)
    local q = queues[queue_id]
    if not q then
        -- batch_max_size <==> conf.queue_size
        local batch_max_size = conf.queue_size or 1
        local process = function(entries)
            local payload = batch_max_size == 1 and entries[1] or json_array_concat(entries)
            return send_payload(self, conf, payload, ua, ip, getpath)
        end

        local opts = {
            retry_count = conf.retry_count,
            flush_timeout = conf.flush_timeout,
            batch_max_size = batch_max_size,
            process_delay = 0
        }

        local err
        q, err = BatchQueue.new(process, opts)
        if not q then
            kong.log.err("could not create queue: ", err)
            return
        end
        queues[queue_id] = q
    end

    q:add(entry)
end

return HttpLogHandler2
