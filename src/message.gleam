import gleam/dynamic
import gleam/json
import gleam/list
import gleam/result

pub type Message {
  Message(src: String, dest: String, body: MessageBody)
}

pub type MessageBody {
  TagContainer(tag: String)
  Init(msg_id: Int, node_id: String, node_ids: List(String))
  InitOk(in_reply_to: Int)
  Echo(msg_id: Int, to_echo: String)
  EchoOk(msg_id: Int, in_reply_to: Int, to_echo: String)
}

pub fn serialize(message: Message) -> String {
  let body_json = case message.body {
    InitOk(in_reply_to) -> serialize_init_ok(in_reply_to)
    EchoOk(msg_id, in_reply_to, to_echo) ->
      serialize_echo_ok(msg_id, in_reply_to, to_echo)
    _ -> panic as "Received unexpected message type"
  }

  json.object([
    #("src", json.string(message.src)),
    #("dest", json.string(message.dest)),
    #("body", body_json),
  ])
  |> json.to_string
}

fn serialize_init_ok(in_reply_to: Int) -> json.Json {
  json.object([
    #("type", json.string("init_ok")),
    #("in_reply_to", json.int(in_reply_to)),
  ])
}

fn serialize_echo_ok(
  msg_id: Int,
  in_reply_to: Int,
  to_echo: String,
) -> json.Json {
  json.object([
    #("type", json.string("echo_ok")),
    #("msg_id", json.int(msg_id)),
    #("in_reply_to", json.int(in_reply_to)),
    #("echo", json.string(to_echo)),
  ])
}

pub fn deserialize(message_str: String) -> Result(Message, json.DecodeError) {
  json.decode(
    message_str,
    dynamic.decode3(
      Message,
      dynamic.field("src", of: dynamic.string),
      dynamic.field("dest", of: dynamic.string),
      dynamic.field("body", of: parse_message_body),
    ),
  )
}

fn parse_message_body(
  message_body_dyn: dynamic.Dynamic,
) -> Result(MessageBody, List(dynamic.DecodeError)) {
  let maybe_tag_container =
    message_body_dyn
    |> dynamic.decode1(TagContainer, dynamic.field("type", of: dynamic.string))

  let tag = case maybe_tag_container {
    Ok(value) ->
      case value {
        TagContainer(tag) -> tag
        _ ->
          panic as "Expected TagContainer but got something different instead"
      }
    Error(errors) -> {
      let message = unwrap_decode_errors(errors, expected: "TagContainer")
      panic as message
    }
  }

  case tag {
    "init" -> parse_init_body(message_body_dyn)
    "init_ok" -> parse_init_ok_body(message_body_dyn)
    "echo" -> parse_echo_body(message_body_dyn)
    "echo_ok" -> parse_echo_ok_body(message_body_dyn)
    _ -> Error([dynamic.DecodeError("known message type", tag, [""])])
  }
}

fn parse_init_body(
  body_dyn: dynamic.Dynamic,
) -> Result(MessageBody, List(dynamic.DecodeError)) {
  body_dyn
  |> dynamic.decode3(
    Init,
    dynamic.field("msg_id", of: dynamic.int),
    dynamic.field("node_id", of: dynamic.string),
    dynamic.field("node_ids", of: dynamic.list(of: dynamic.string)),
  )
}

fn parse_init_ok_body(
  body_dyn: dynamic.Dynamic,
) -> Result(MessageBody, List(dynamic.DecodeError)) {
  body_dyn
  |> dynamic.decode1(InitOk, dynamic.field("in_reply_to", of: dynamic.int))
}

fn parse_echo_body(
  body_dyn: dynamic.Dynamic,
) -> Result(MessageBody, List(dynamic.DecodeError)) {
  body_dyn
  |> dynamic.decode2(
    Echo,
    dynamic.field("msg_id", of: dynamic.int),
    dynamic.field("echo", of: dynamic.string),
  )
}

fn parse_echo_ok_body(
  body_dyn: dynamic.Dynamic,
) -> Result(MessageBody, List(dynamic.DecodeError)) {
  body_dyn
  |> dynamic.decode3(
    EchoOk,
    dynamic.field("msg_id", of: dynamic.int),
    dynamic.field("in_reply_to", of: dynamic.int),
    dynamic.field("echo", of: dynamic.string),
  )
}

fn unwrap_decode_errors(
  errors: List(dynamic.DecodeError),
  expected expected: String,
) -> String {
  let inner =
    errors
    |> list.first
    |> result.unwrap(dynamic.DecodeError(expected, "unknown", [""]))

  "Expected " <> inner.expected <> " but got " <> inner.found
}
