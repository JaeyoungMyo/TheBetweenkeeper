# 저장 코덱 (U5 BR-U5-03, 04, 05): JSON 본문 + HMAC-SHA256 서명 봉투. 암호화는 파일 쓰기 쪽 (SaveService) 에서 한다
class_name SaveCodec
extends RefCounted

## 개인용 수준의 키 (V-4 A). 빌드 시 교체 대상
const KEY := "아공간관리인-save-key-v1"


static func _mac(payload: String) -> String:
	var c := Crypto.new()
	var mac := c.hmac_digest(HashingContext.HASH_SHA256, KEY.to_utf8_buffer(), payload.to_utf8_buffer())
	return mac.hex_encode()


## 데이터 → 봉투 문자열 {"payload": 본문 JSON 문자열, "sig": 서명}
static func encode(data: Dictionary) -> String:
	var payload := JSON.stringify(data)
	return JSON.stringify({"payload": payload, "sig": _mac(payload)})


## 봉투 → 데이터. 서명이 틀리거나 형식이 깨졌으면 빈 딕셔너리 (거부)
static func decode(text: String) -> Dictionary:
	var env = JSON.parse_string(text)
	if not (env is Dictionary) or not env.has("payload") or not env.has("sig"):
		return {}
	var payload: String = env["payload"]
	if _mac(payload) != env["sig"]:
		return {}
	var data = JSON.parse_string(payload)
	return data if data is Dictionary else {}
