import gleeunit
import gleeunit/should
import message

pub fn main() {
  gleeunit.main()
}

pub fn init_message_deserialization_test() {
  let message_str =
    "{\"src\":\"c1\",\"dest\":\"n3\",\"body\":{\"type\":\"init\",\"msg_id\":1,\"node_id\":\"n3\",\"node_ids\":[\"n1\",\"n2\",\"n3\"]}}"
  let expected =
    message.Message("c1", "n3", message.Init(1, "n3", ["n1", "n2", "n3"]))

  message.deserialize(message_str)
  |> should.be_ok()
  |> should.equal(expected)
}

pub fn init_ok_message_deserialization_test() {
  let message_str =
    "{\"src\":\"c1\",\"dest\":\"n3\",\"body\":{\"type\":\"init_ok\",\"in_reply_to\":1}}"
  let expected = message.Message("c1", "n3", message.InitOk(1))

  message.deserialize(message_str)
  |> should.be_ok()
  |> should.equal(expected)
}

pub fn init_ok_message_serialization_test() {
  let message = message.Message("c1", "n3", message.InitOk(1))
  let expected =
    "{\"src\":\"c1\",\"dest\":\"n3\",\"body\":{\"type\":\"init_ok\",\"in_reply_to\":1}}"

  message.serialize(message)
  |> should.equal(expected)
}

pub fn echo_message_deserialization_test() {
  let message_str =
    "{\"src\":\"c1\",\"dest\":\"n3\",\"body\":{\"type\":\"echo\",\"msg_id\":1,\"echo\":\"Please echo 98\"}}"
  let expected = message.Message("c1", "n3", message.Echo(1, "Please echo 98"))

  message.deserialize(message_str)
  |> should.be_ok()
  |> should.equal(expected)
}

pub fn echo_ok_message_deserialization_test() {
  let message_str =
    "{\"src\":\"c1\",\"dest\":\"n3\",\"body\":{\"type\":\"echo_ok\",\"msg_id\":1,\"in_reply_to\":1,\"echo\":\"Please echo 98\"}}"
  let expected =
    message.Message("c1", "n3", message.EchoOk(1, 1, "Please echo 98"))

  message.deserialize(message_str)
  |> should.be_ok()
  |> should.equal(expected)
}

pub fn echo_ok_message_serialization_test() {
  let message =
    message.Message("c1", "n3", message.EchoOk(1, 1, "Please echo 98"))
  let expected =
    "{\"src\":\"c1\",\"dest\":\"n3\",\"body\":{\"type\":\"echo_ok\",\"msg_id\":1,\"in_reply_to\":1,\"echo\":\"Please echo 98\"}}"

  message.serialize(message)
  |> should.equal(expected)
}
