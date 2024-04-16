# Gleam OpenTelemetry Proof-of-Concept Application

This PoC provides Erlang FFI for
[opentelemetry-erlang](https://github.com/open-telemetry/opentelemetry-erlang)
for a `wisp` backend and some JS FFI for OpenTelemetry as well for its `lustre`
frontend.

After following the setup below, you should be able to browse to
[http://localhost:5173](http://localhost:5173) in order to click a button -
which will result in an HTTP GET that returns 500. Browsing to Jaeger at
[http://localhost:16686](http://localhost:16686), you should be able see nested
spans from frontend to backend.

## Known Quirks

You will see this error starting up the backend:
```
OTLP exporter failed to initialize with exception error:{badmatch,
                                                         {error,
                                                          inets_not_started}}
```

`glotel/tracing.init()` takes care of this by forcing OTP applications to re-load and re-start in the right order.

## Running Jaeger to Collect / View Metrics for Testing

```shell
docker run --rm --name jaeger \
  -e COLLECTOR_ZIPKIN_HOST_PORT=:9411 \
  -e COLLECTOR_OTLP_HTTP_CORS_ALLOWED_HEADERS="*" \
  -e COLLECTOR_OTLP_HTTP_CORS_ALLOWED_ORIGINS="http://localhost:5173" \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 14250:14250 \
  -p 14268:14268 \
  -p 14269:14269 \
  -p 9411:9411 \
  jaegertracing/all-in-one:1.56
```

## Running the Backend

```shell
cd backend
export OTEL_SERVICE_NAME="gleam_otel_poc_backend"
gleam run
```

## Running the Frontend

```shell
cd frontend
npm i
export VITE_OTEL_SERVICE_NAME="gleam_otel_poc_frontend"
npm run dev
```