#lang racket
(require net/url
         net/uri-codec
         web-server/stuffers/hmac-sha1
         net/base64
         openssl/sha1
         (planet dherman/json:4:0)
         racket/draw)

(provide mygengo get-account-stats get-account-balance get-job-preview 
         get-job-revision get-job-revisions get-job-feedback post-job-comment 
         get-job-comments delete-job get-job revise-job approve-job
         reject-job post-job get-jobs-by-group-id get-jobs get-jobs-by-job-ids 
         post-jobs get-language-pairs get-languages jobs-quote)

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

(define (get-api-sig-and-ts mygengo-user)
  (define hex-digest
    (hmac-sha1-hex (mygengo-private-key mygengo-user) current-ts))
  (list (cons 'api_sig hex-digest)
        (cons 'ts current-ts)))

(define (create-url method mygengo-user auth-required [optional-params null])
  (define api-sig
    (if auth-required
        (first (get-api-sig-and-ts mygengo-user)) null))
  (define timestamp
    (if auth-required
        (last (get-api-sig-and-ts mygengo-user)) null))
  (define api-key
    `(api_key . ,(mygengo-public-key mygengo-user)))
  (define param-list
    (if auth-required
        (append optional-params (list api-key api-sig timestamp))
        (append optional-params (list api-key))))
  (string->url
   (string-append
    (if (mygengo-sandbox mygengo-user) sandbox-url api-base-url)
    method "?"
    (alist->form-urlencoded param-list))))

(define (get-request method mygengo-user auth-required optional-params)
  (read-json
   (get-pure-port
    (create-url method
                mygengo-user
                auth-required
                optional-params)
    '("Accept:application/json"))))

(define (post/put-request post-or-put-pure-port method data mygengo-user [optional-params null])
  (define base-url (if (mygengo-sandbox mygengo-user) sandbox-url api-base-url))
  (define api-sig-and-ts (get-api-sig-and-ts mygengo-user))
  (define api-sig (first api-sig-and-ts))
  (define ts (last api-sig-and-ts))
  (define param-list
    (list api-sig
          ts
          `(api_key . ,(mygengo-public-key mygengo-user))
          `(data . ,data)))
  (read-json
   (post-or-put-pure-port
    (string->url (string-append base-url method))
    (string->bytes/locale
     (alist->form-urlencoded
      param-list))
    '("Accept:application/json"
      "Content-Type:application/x-www-form-urlencoded"))))

(define (delete-request method mygengo-user)
  (read-json
   (delete-pure-port
    (create-url method
                mygengo-user
                #t)
    '("Accept:application/json"))))

(define (get-request-auth-required method mygengo-user [optional-params null])
  (get-request method mygengo-user #t optional-params))

(define (get-request-no-auth method mygengo-user [optional-params null])
  (get-request method mygengo-user #f optional-params))

(define (get-request-jpeg method mygengo-user)
  (make-object bitmap%
    (get-pure-port
     (create-url method mygengo-user #t null))))

(define (post-request method data mygengo-user [optional-params null])
  (post/put-request post-pure-port method data mygengo-user optional-params))

(define (put-request method data mygengo-user [optional-params null])
  (post/put-request put-pure-port method data mygengo-user optional-params))

(define set-hash-data
  (lambda (a-hash param-symbol param)
    (if (not (null? param))
        (hash-set! a-hash param-symbol param)
        null)
    a-hash))

; http://mygengo.com/api/developer-docs/methods/account-stats-get/
(define (get-account-stats mygengo-user)
  (get-request-auth-required "account/stats" mygengo-user))

; http://mygengo.com/api/developer-docs/methods/account-balance-get/
(define (get-account-balance mygengo-user)
  (get-request-auth-required "account/balance" mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-preview-get/
(define (get-job-preview job-id mygengo-user)
  (get-request-jpeg
   (format "translate/job/~s/preview" job-id)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/
;        translate-job-id-revision-rev-id-get/
(define (get-job-revision job-id rev-id mygengo-user)
  (get-request-auth-required
   (format "translate/job/~s/revision/~s" job-id rev-id)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-revisions-get/
(define (get-job-revisions job-id mygengo-user)
  (get-request-auth-required
   (format "translate/job/~s/revisions" job-id)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-feedback-get/
(define (get-job-feedback job-id mygengo-user)
  (get-request-auth-required
   (format "translate/job/~s/feedback" job-id)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-comment-post/
(define (post-job-comment job-id comment mygengo-user)
  (define data-hash (make-hash))
  (hash-set! data-hash 'body comment)
  (post-request
   (format "translate/job/~s/comment" job-id)
   (jsexpr->json data-hash)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-comment-post/
(define (get-job-comments job-id mygengo-user)
  (get-request-auth-required
   (format "translate/job/~s/comments" job-id)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-delete/
(define (delete-job job-id mygengo-user)
  (delete-request
   (format "translate/job/~s" job-id)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-get/
(define (get-job job-id mygengo-user [pre-mt #f])
  (define optional-params
    (if pre-mt (list '(pre_mt . "1")) null))
  (get-request-auth-required
   (format "translate/job/~s" job-id)
   mygengo-user
   optional-params))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-put/
(define (revise-job job-id comment mygengo-user)
  (define data-hash (make-hash))
  (hash-set! data-hash 'action "revise")
  (hash-set! data-hash 'comment comment)
  (put-request
   (format "translate/job/~s" job-id)
   (jsexpr->json data-hash)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-put/
(define (approve-job job-id mygengo-user [rating null]
                     [for-translator null] [for-mygengo null]
                     [public 0])
  (define data-hash (make-hash))
  (hash-set! data-hash 'action "approve")
  (set-hash-data data-hash 'rating rating)
  (set-hash-data data-hash 'for_translator for-translator)
  (set-hash-data data-hash 'for_mygengo for-mygengo)
  (set-hash-data data-hash 'public public)
  (put-request
   (format "translate/job/~s" job-id)
   (jsexpr->json data-hash)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-id-put/
(define (reject-job job-id mygengo-user reason
                    comment captcha
                    [follow-up null])
  (define data-hash (make-hash))
  (hash-set! data-hash 'action "reject")
  (hash-set! data-hash 'reason reason)
  (hash-set! data-hash 'comment comment)
  (hash-set! data-hash 'captcha captcha)
  (set-hash-data data-hash 'follow_up follow-up)
  (put-request
   (format "translate/job/~s" job-id)
   (jsexpr->json data-hash)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-job-post/
; Define the job in a separate json file following the specification under
; "Job Payload - For submissions" here:
; http://mygengo.com/api/developer-docs/payloads/
; See single_job_example.json as well.
(define (post-job job-json mygengo-user)
  (define data (read-json (open-input-file job-json)))
  (post-request
   "translate/job"
   (jsexpr->json data)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-jobs-group-get/
(define (get-jobs-by-group-id group-id mygengo-user)
  (get-request-auth-required
   (format "translate/jobs/group/~s" group-id)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-jobs-get/
(define (get-jobs mygengo-user [status null]
                  [timestamp-after null] [count null])
  (define timestamp-after-string
    (if (not (null? timestamp-after)) (number->string timestamp-after) null))
  (define count-string
    (if (not (null? count)) (number->string count) null))
  (define optional-params
    (filter (lambda (x) (not (null? (cdr x))))
            (list
             `(status . ,status)
             `(timestamp_after . ,timestamp-after-string)
             `(count . ,count-string))))
  (get-request-auth-required
   "translate/jobs"
   mygengo-user
   optional-params))

; http://mygengo.com/api/developer-docs/methods/translate-jobs-ids-get/
(define (get-jobs-by-job-ids list-of-job-ids mygengo-user)
  (get-request-auth-required
   (format "translate/jobs/~a"
           (string-join (map number->string list-of-job-ids) ","))
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-jobs-post/
(define (post-jobs jobs-json mygengo-user)
  (define data (read-json (open-input-file jobs-json)))
  (post-request
   "translate/jobs"
   (jsexpr->json data)
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/
;        translate-service-language-pairs-get/
(define (get-language-pairs mygengo-user [lc-src null])
  (define optional-params
    (if (not (null? lc-src)) (list (cons 'lc_src lc-src)) null))
  (get-request-no-auth
   "translate/service/language_pairs"
   mygengo-user
   optional-params))

; http://mygengo.com/api/developer-docs/methods/translate-service-languages-get/
(define (get-languages mygengo-user)
  (get-request-no-auth
   "translate/service/languages"
   mygengo-user))

; http://mygengo.com/api/developer-docs/methods/translate-service-quote-post/
(define (jobs-quote jobs-json mygengo-user)
  (define data (read-json (open-input-file jobs-json)))
  (post-request
   "translate/service/quote"
   (jsexpr->json data)
   mygengo-user))
