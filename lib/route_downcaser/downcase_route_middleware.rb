module RouteDowncaser

  class DowncaseRouteMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      old_env = {
        'REQUEST_URI' => env['REQUEST_URI'],
        'PATH_INFO' => env['PATH_INFO']
      }

      # Don't touch anything, if uri/path is part of exclude_patterns
      if exclude_patterns_match?(env['REQUEST_URI']) or exclude_patterns_match?(env['PATH_INFO'])
        return @app.call(env)
      end

      # Downcase request_uri and/or path_info if applicable
      if !env['REQUEST_URI'].nil? || !env['REQUEST_URI'].empty?
        env['REQUEST_URI'] = downcased_uri(env['REQUEST_URI'])
      end

      if !env['PATH_INFO'].nil? || !env['PATH_INFO'].empty?
        env['PATH_INFO'] = downcased_uri(env['PATH_INFO'])
      end

      # If redirect configured, then return redirect request,
      # if either request_uri or path_info has changed
      if RouteDowncaser.redirect && env['REQUEST_METHOD'] == "GET"
        if (!env["REQUEST_URI"].nil? || !env["REQUEST_URI"].empty?) and old_env["REQUEST_URI"] != env["REQUEST_URI"]
          return redirect_header(env["REQUEST_URI"])
        end

        if (!env["PATH_INFO"].nil? || !env["PATH_INFO"].empty?) and old_env["PATH_INFO"] != env["PATH_INFO"]
          return redirect_header(env["PATH_INFO"])
        end
      end

      # Default just move to next chain in Rack callstack
      # calling with downcased uri if needed
      @app.call(env)
    end

    private

    def exclude_patterns_match?(uri)
      uri.match(Regexp.union(RouteDowncaser.exclude_patterns)) if uri and RouteDowncaser.exclude_patterns
    end

    def downcased_uri(uri)
      if has_querystring?(uri)
        "#{path(uri).mb_chars.downcase}?#{querystring(uri)}"
      else
        path(uri).mb_chars.downcase
      end
    end

    def path(uri)
      uri_items(uri).first
    end

    def querystring(uri)
      uri_items(uri).last
    end

    def has_querystring?(uri)
      uri_items(uri).length > 1
    end

    def uri_items(uri)
      uri.split('?')
    end

    def redirect_header(uri)
      [301, {'Location' => uri, 'Content-Type' => 'text/html'}, []]
    end
  end

end
