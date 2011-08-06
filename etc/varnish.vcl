# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 
backend default {
    .host = "10.0.0.1";
    .port = "80";
}

backend bbbike64 {
    #.host = "bbbike64";
    .host = "10.0.0.4";
    .port = "80";

    .first_byte_timeout = 600s;
    .connect_timeout = 600s;
    .between_bytes_timeout = 600s;
}

backend bbbike {
    .host = "bbbike";
    .port = "80";
}


backend eserte {
    .host = "eserte";
    .port = "80";
    .first_byte_timeout = 300s;
    .connect_timeout = 300s;
    .between_bytes_timeout = 300s;
}

sub vcl_recv {
    if (req.http.host ~ "^(www\.|dev\.|download\.|)bbbike\.org$") {
        set req.backend = bbbike64;
    } else if (req.http.host ~ "^eserte\.bbbike\.org$" || req.http.host ~ "^.*bbbike\.de$" ) {
        set req.backend = eserte;
    } else {
        set req.backend = bbbike;
    }

    if (req.http.x-forwarded-for) {
       set req.http.X-Forwarded-For =
           req.http.X-Forwarded-For ", " client.ip;
    } else {
       set req.http.X-Forwarded-For = client.ip;
    }

    # do not cache OSM files
    if (req.http.host ~ "^(download)\.bbbike\.org$") {
         return (pipe);
    }

    # development machine of S.R.T
    if (req.http.host ~ "^eserte\.bbbike\.org$") {
	return (pass);
    }

    # force caching of images and CSS/JS files
    if (req.url ~ "^/html|^/images|^/feed/|^/osp/|^/cgi/[ac-z]|.*\.html$|.*/$") {
       unset req.http.cookie;
       unset req.http.Accept-Encoding;
       unset req.http.User-Agent;
       unset req.http.referer;
    }

    # override page reload requests from impatient users
    if (  req.http.Cache-Control ~ "no-cache" 
       || req.http.Cache-Control ~ "private"
       || req.http.Cache-Control ~ "max-age=0") {

      set req.http.Cache-Control = "max-age=240";
      #unset req.http.Expires;
    }

    # pipeline post requests trac #4124 
    if (req.request == "POST") {
	return (pass);
    }

    # test & development
    if (req.http.host ~ "^(dev|devel)\.bbbike\.org$") {
	return (pass);
    }
    return (lookup);
}

sub vcl_hash {
    # cache requests with cookies in mind
    set req.hash += req.http.cookie;
}

sub vcl_fetch {
    #return (pass);

    #if (req.url ~ "^/html|^/images|^/feed/|.*\.html$|.*/$") {
    #   unset beresp.http.cookie;
    #}

    if (!beresp.cacheable) {
         return (pass);
    }

    return (deliver);

    #unset beresp.http.set-cookie;
    #if (beresp.http.Set-Cookie) {
    #    return (pass);
    #}
    #return (deliver);
}

sub vcl_pipe {
    /* Force the connection to be closed afterwards so subsequent reqs don't use pipe */
    set bereq.http.connection = "close";
}

# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
# 
# sub vcl_recv {
#     if (req.http.x-forwarded-for) {
# 	set req.http.X-Forwarded-For =
# 	    req.http.X-Forwarded-For ", " client.ip;
#     } else {
# 	set req.http.X-Forwarded-For = client.ip;
#     }
#     if (req.request != "GET" &&
#       req.request != "HEAD" &&
#       req.request != "PUT" &&
#       req.request != "POST" &&
#       req.request != "TRACE" &&
#       req.request != "OPTIONS" &&
#       req.request != "DELETE") {
#         /* Non-RFC2616 or CONNECT which is weird. */
#         return (pipe);
#     }
#     if (req.request != "GET" && req.request != "HEAD") {
#         /* We only deal with GET and HEAD by default */
#         return (pass);
#     }
#     if (req.http.Authorization || req.http.Cookie) {
#         /* Not cacheable by default */
#         return (pass);
#     }
#     return (lookup);
# }
# 
# sub vcl_pipe {
#     # Note that only the first request to the backend will have
#     # X-Forwarded-For set.  If you use X-Forwarded-For and want to
#     # have it set for all requests, make sure to have:
#     # set req.http.connection = "close";
#     # here.  It is not set by default as it might break some broken web
#     # applications, like IIS with NTLM authentication.
#     return (pipe);
# }
# 
# sub vcl_pass {
#     return (pass);
# }
# 
# sub vcl_hash {
#     set req.hash += req.url;
#     if (req.http.host) {
#         set req.hash += req.http.host;
#     } else {
#         set req.hash += server.ip;
#     }
#     return (hash);
# }
# 
# sub vcl_hit {
#     if (!obj.cacheable) {
#         return (pass);
#     }
#     return (deliver);
# }
# 
# sub vcl_miss {
#     return (fetch);
# }
# 
# sub vcl_fetch {
#     if (!beresp.cacheable) {
#         return (pass);
#     }
#     if (beresp.http.Set-Cookie) {
#         return (pass);
#     }
#     return (deliver);
# }
# 
# sub vcl_deliver {
#     return (deliver);
# }
# 
# sub vcl_error {
#     set obj.http.Content-Type = "text/html; charset=utf-8";
#     synthetic {"
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
# <html>
#   <head>
#     <title>"} obj.status " " obj.response {"</title>
#   </head>
#   <body>
#     <h1>Error "} obj.status " " obj.response {"</h1>
#     <p>"} obj.response {"</p>
#     <h3>Guru Meditation:</h3>
#     <p>XID: "} req.xid {"</p>
#     <hr>
#     <p>Varnish cache server</p>
#   </body>
# </html>
# "};
#     return (deliver);
# }
