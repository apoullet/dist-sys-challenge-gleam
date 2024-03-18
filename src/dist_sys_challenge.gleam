import gleam/io
import gleam/erlang
import message

pub fn main() {
  let node_id = handle_init_message()
  handle_message(node_id)
}

fn handle_init_message() -> String {
  let input = case erlang.get_line("") {
    Ok(inner) -> inner
    Error(_) -> panic as "Encountered error when getting input"
  }

  let message = case message.deserialize(input) {
    Ok(inner) -> inner
    Error(_) -> panic as "Could not parse input into Message"
  }

  handle_init(message)
}

fn handle_message(node_id: String) {
  let input = case erlang.get_line("") {
    Ok(inner) -> inner
    Error(_) -> panic as "Encountered error when getting input"
  }

  let message = case message.deserialize(input) {
    Ok(inner) -> inner
    Error(_) -> panic as "Could not parse input into Message"
  }

  case message.body {
    message.Echo(_, _) -> {
      handle_echo(message, node_id)
      handle_message(node_id)
    }
    _ -> handle_message(node_id)
  }
}

fn handle_init(message: message.Message) -> String {
  case message.body {
    message.Init(msg_id, node_id, _) -> {
      let response =
        message.Message(node_id, message.src, message.InitOk(msg_id))
      io.println(message.serialize(response))
      node_id
    }
    _ -> panic as "Expected init message but got something else instead"
  }
}

fn handle_echo(message: message.Message, node_id: String) {
  case message.body {
    message.Echo(msg_id, to_echo) -> {
      let response =
        message.Message(
          node_id,
          message.src,
          message.EchoOk(msg_id, msg_id, to_echo),
        )
      io.println(message.serialize(response))
    }
    _ -> panic as "Expected echo message but got something else instead"
  }
}
