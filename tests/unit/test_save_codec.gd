# U5 BR-U5-03, 05 (SaveCodec): 왕복, 변조 거부
extends TestBase


func test_roundtrip_returns_same_data() -> void:
	var data := {"gold": 120, "items": [{"id": 1, "kind": "sword"}]}
	var back := SaveCodec.decode(SaveCodec.encode(data))
	expect(int(back["gold"]) == 120, "gold roundtrip")
	expect(back["items"][0]["kind"] == "sword", "item roundtrip")


func test_tampered_payload_rejected() -> void:
	var text := SaveCodec.encode({"gold": 120})
	var env = JSON.parse_string(text)
	env["payload"] = env["payload"].replace("120", "999")
	expect(SaveCodec.decode(JSON.stringify(env)).is_empty(), "changed payload rejected")


func test_wrong_signature_rejected() -> void:
	var env = JSON.parse_string(SaveCodec.encode({"gold": 1}))
	env["sig"] = "00"
	expect(SaveCodec.decode(JSON.stringify(env)).is_empty(), "bad signature rejected")


func test_garbage_rejected() -> void:
	expect(SaveCodec.decode("not json").is_empty(), "garbage rejected")
