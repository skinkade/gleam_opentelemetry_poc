import wisp
import glotel/tracing

fn allow_all_cors(handler: fn() -> wisp.Response) -> wisp.Response {
  handler()
  |> wisp.set_header("Access-Control-Allow-Origin", "*")
  |> wisp.set_header("Access-Control-Allow-Headers", "*")
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  use <- allow_all_cors()
  use <- tracing.wisp_middleware(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}
