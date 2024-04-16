-module(glotel_ffi).

-export([get_tracer/0, ensure_otel_started/0, get_otel_exporter/0, set_span_error/0,
         set_span_error_message/1, set_span_attribute/2]).

get_tracer() ->
    opentelemetry:get_application_tracer(
        application:get_application()).

% Hack to get things (re)0loaded in the right order
ensure_otel_started() ->
    application:stop(opentelemetry),
    application:unload(opentelemetry),
    application:stop(opentelemetry_exporter),
    application:unload(opentelemetry_exporter),
    application:ensure_started(inets),
    application:load(opentelemetry_exporter),
    application:start(opentelemetry_exporter, permanent),
    application:load(opentelemetry),
    application:start(opentelemetry).

get_otel_exporter() ->
    application:get_key(opentelemetry_exporter).

set_span_error() ->
    otel_span:set_status(
        otel_tracer:current_span_ctx(), error).

set_span_error_message(Message) ->
    otel_span:set_status(
        otel_tracer:current_span_ctx(), error, Message).

set_span_attribute(Key, Value) ->
    otel_span:set_attribute(
        otel_tracer:current_span_ctx(), Key, Value).
