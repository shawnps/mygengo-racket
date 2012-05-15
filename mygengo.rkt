#lang racket
(require net/url
         net/uri-codec
         web-server/stuffers/hmac-sha1
         net/base64
         openssl/sha1
         (planet dherman/json:4:0))

(struct mygengo (public-key private-key sandbox))
(define sandbox-url "http://api.sandbox.mygengo.com/v1.1/")
(define api-base-url "http://api.mygengo.com/v1.1/")
; the current seconds since UNIX epoch, to be hashed
; and sent in request as api_sig
(define current-ts
  (number->string
   (current-seconds)))

(define (hmac-sha1-hex private-key a-string)
  (bytes->hex-string
   (HMAC-SHA1
    (string->bytes/locale private-key)
    (string->bytes/locale a-string))))

; do a GET request
; example:
; (get-request "account/stats" some-user)
; "{\"opstat\":\"ok\",\"response\":{\"user_since\":1320642742,
;   \"credits_spent\":\"-1908.52\",\"currency\":\"USD\"}}"
(define (get-request method mygengo-user)
  (read-json
   (get-pure-port
    (create-url method mygengo-user)
    '("Accept:application/json"))))

(define (create-url method mygengo-user)
  (string->url
   (string-append
    (if (mygengo-sandbox mygengo-user) sandbox-url api-base-url)
    method
    "?api_key="
    (uri-encode (mygengo-public-key mygengo-user))
    "&api_sig="
    (hmac-sha1-hex (mygengo-private-key mygengo-user) current-ts)
    "&ts=" current-ts)))

(define (get-account-stats mygengo-user)
  (get-request "account/stats" mygengo-user))

(define (get-account-balance mygengo-user)
  (get-request "account/balance" mygengo-user))

(define (get-job-feedback job-id mygengo-user)
  (get-request (string-append "translate/job/" job-id "/feedback")
               mygengo-user))
