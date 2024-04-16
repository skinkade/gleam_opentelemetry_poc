import gleam/dict.{type Dict}
import gleam/erlang/atom.{type Atom}
import gleam/http.{method_to_string}
import wisp.{type Request, type Response}
import gleam/int

type ApplicationStartResult

@external(erlang, "glotel_ffi", "ensure_otel_started")
fn ensure_otel_started() -> ApplicationStartResult

pub type Tracer

pub fn init() -> Nil {
  ensure_otel_started()
  Nil
}

@external(erlang, "glotel_ffi", "get_tracer")
fn do_get_tracer() -> Tracer

pub type Span

@external(erlang, "otel_tracer", "start_span")
fn do_start_span(
  tracer: Tracer,
  name: String,
  attributes: Dict(Atom, Dict(String, String)),
) -> Span

fn start_span(tracer: Tracer, name: String, attributes: List(#(String, String))) {
  do_start_span(
    tracer,
    name,
    dict.new()
      |> dict.insert(
        atom.create_from_string("attributes"),
        dict.from_list(attributes),
      ),
  )
}

@external(erlang, "otel_span", "end_span")
fn do_end_span(span: Span) -> Nil

type OtelCtx

@external(erlang, "otel_ctx", "get_current")
fn current_otel_ctx() -> OtelCtx

@external(erlang, "otel_tracer", "set_current_span")
fn set_current_span(ctx: OtelCtx, span: Span) -> OtelCtx

type CtxToken

@external(erlang, "otel_ctx", "attach")
fn attach(ctx: OtelCtx) -> CtxToken

@external(erlang, "otel_ctx", "detach")
fn detach(token: CtxToken) -> Nil

pub fn with_span(
  name: String,
  attributes: List(#(String, String)),
  callback: fn() -> a,
) -> a {
  let ctx = current_otel_ctx()
  let tracer = do_get_tracer()
  let span = start_span(tracer, name, attributes)
  let ctx2 = set_current_span(ctx, span)
  let token = attach(ctx2)

  let result = callback()

  do_end_span(span)
  detach(token)

  result
}

@external(erlang, "glotel_ffi", "set_span_error")
pub fn set_span_error() -> Nil

@external(erlang, "glotel_ffi", "set_span_error_message")
pub fn set_span_error_message(message: String) -> Nil

@external(erlang, "glotel_ffi", "set_span_attribute")
pub fn set_span_attribute(key: String, value: String) -> Nil

@external(erlang, "otel_propagator_text_map", "extract")
fn extract(values: List(#(String, String))) -> Nil

pub fn wisp_middleware(request: Request, handler: fn() -> Response) -> Response {
  let method = method_to_string(request.method)
  let path = request.path

  extract(request.headers)

  use <- with_span(method <> " " <> path, [
    #("http.method", method),
    #("http.route", path),
  ])

  let response = handler()

  set_span_attribute("http.status_code", int.to_string(response.status))

  case response.status >= 500 {
    True -> set_span_error()
    _ -> Nil
  }

  response
}
