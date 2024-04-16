import gleam/dynamic
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre_http.{type HttpError}

@external(javascript, "app_ffi.js", "setup")
fn tracing_setup() -> Nil

pub fn main() {
  tracing_setup()
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

pub type Model {
  Static
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Static, effect.none())
}

pub type Cat {
  Cat(id: String, tags: List(String))
}

pub opaque type Msg {
  UserActionTriggered
  GotCat(Result(Cat, HttpError))
}

fn update(_: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserActionTriggered -> #(Static, user_action())
    GotCat(_) -> #(Static, effect.none())
  }
}

fn user_action() -> Effect(Msg) {
  let url = "http://localhost:8000/test"
  let decoder =
    dynamic.decode2(
      Cat,
      dynamic.field("_id", dynamic.string),
      dynamic.field("tags", dynamic.list(dynamic.string)),
    )
  lustre_http.get(url, lustre_http.expect_json(decoder, GotCat))
}

pub fn view(_model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "w-full h-[32rem] mb-4 p-4 flex flex-col items-center border",
      ),
    ],
    [
      html.button(
        [
          attribute.class("border rounded p-2 m-4 active:bg-blue-600"),
          event.on_click(UserActionTriggered),
        ],
        [element.text("Click")],
      ),
    ],
  )
}
