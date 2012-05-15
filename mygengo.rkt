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
; '#hasheq((response . #hasheq((user_since . 1320642742)
;  (credits_spent . "-1908.52") (currency . "USD"))) (opstat . "ok"))
(define (get-request method mygengo-user [optional-params ""])
  (read-json
   (get-pure-port
    (create-url method
                mygengo-user
                optional-params)
    '("Accept:application/json"))))

(define (create-url method mygengo-user [optional-params ""])
  (string->url
   (string-append
    (if (mygengo-sandbox mygengo-user) sandbox-url api-base-url)
    method
    "?api_key="
    (uri-encode (mygengo-public-key mygengo-user))
    "&api_sig="
    (hmac-sha1-hex (mygengo-private-key mygengo-user) current-ts)
    "&ts=" current-ts
    optional-params)))

(define (get-account-stats mygengo-user)
  (get-request "account/stats" mygengo-user))

(define (get-account-balance mygengo-user)
  (get-request "account/balance" mygengo-user))

(define (get-job-preview job-id mygengo-user)
  (get-request (string-append "translate/job/"
                              (number->string job-id)
                              "/preview")
               mygengo-user))

(define (get-job-revision job-id rev-id mygengo-user)
  (get-request (string-append "translate/job/"
                              (number->string job-id)
                              "/revision/"
                              (number->string rev-id))
               mygengo-user))

(define (get-job-feedback job-id mygengo-user)
  (get-request (string-append "translate/job/"
                              (number->string job-id)
                              "/feedback")
               mygengo-user))

(define (get-job-comments job-id mygengo-user)
  (get-request (string-append "translate/job/"
                              (number->string job-id)
                              "/comments")
               mygengo-user))

(define (get-job job-id mygengo-user [pre-mt 0])
  (get-request (string-append "translate/job/"
                              (number->string job-id))
               mygengo-user
               (if (and pre-mt (= pre-mt 1)) "&pre_mt=1" "")))

(define (get-job-group group-id mygengo-user)
  (get-request (string-append "translate/jobs/group/"
                              (number->string group-id))
               mygengo-user ""))
