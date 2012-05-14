#lang racket
(require net/url
         net/uri-codec
         web-server/stuffers/hmac-sha1
         net/base64
         openssl/sha1)

(define sandbox-url "http://api.sandbox.mygengo.com/v1.1/")
(struct mygengo (public-key private-key sandbox))
(define current-ts
  (substring
   (number->string
    (/ (current-inexact-milliseconds) 1000))
   0 10))

(define (params-to-api-sig private-key params)
  (bytes->hex-string
   (HMAC-SHA1
    (string->bytes/locale private-key)
    (string->bytes/locale params))))

; do a GET request
; example:
; (get-request sandbox-url "account/stats" someuser)
; "{\"opstat\":\"ok\",\"response\":{\"user_since\":1320642742,
;   \"credits_spent\":\"-1908.52\",\"currency\":\"USD\"}}"
(define (get-request base-url method mygengo-user)
  (read-line
   (get-pure-port
    (string->url (string-append base-url
                                method
                                "?api_key="
                                (uri-encode
                                 (mygengo-public-key mygengo-user))
                                "&api_sig="
                                (params-to-api-sig
                                 (mygengo-private-key mygengo-user)
                                 current-ts)
                                "&ts=" current-ts))
    '("Accept:application/json"))))
