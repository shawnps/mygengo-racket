#lang racket
(require net/url
         net/uri-codec
         web-server/stuffers/hmac-sha1
         net/base64
         openssl/sha1
         (planet dherman/json:4:0)
         racket/draw)

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
  (define api-sig (car api-sig-and-ts))
  (define ts (car (cdr api-sig-and-ts)))
  (read-json
   (post-or-put-pure-port
    (string->url (string-append base-url method))
    (string->bytes/locale
     (alist->form-urlencoded (list
                              api-sig
                              (cons 'api_key (mygengo-public-key mygengo-user))
                              (cons 'data data)
                              ts)))
    '("Accept:application/json"
      "Content-Type:application/x-www-form-urlencoded"))))

(define (get-request-auth-required method mygengo-user [optional-params ""])
  (get-request method mygengo-user #t optional-params))

(define (get-request-no-auth method mygengo-user [optional-params ""])
  (get-request method mygengo-user #f optional-params))

(define (get-request-jpeg method mygengo-user)
  (make-object bitmap%
    (get-pure-port
     (create-url method mygengo-user #t empty))))

(define (post-request method data mygengo-user [optional-params null])
  (post/put-request post-pure-port method data mygengo-user optional-params))

(define (put-request method data mygengo-user [optional-params null])
  (post/put-request put-pure-port method data mygengo-user optional-params))

(define (delete-request method mygengo-user)
  (read-json
   (delete-pure-port
    (create-url method
                mygengo-user
                #t)
    '("Accept:application/json"))))

(define (get-api-sig-and-ts mygengo-user)
  (define hex-digest
    (hmac-sha1-hex (mygengo-private-key mygengo-user) current-ts))
  (list (cons 'api_sig hex-digest)
        (cons 'ts current-ts)))

(define (create-url method mygengo-user auth-required [optional-params empty])
  (define api-sig
    (if auth-required
        (car (get-api-sig-and-ts mygengo-user)) empty))
  (define timestamp
    (if auth-required
        (car (cdr (get-api-sig-and-ts mygengo-user))) empty))
  (string->url
   (string-append
    (if (mygengo-sandbox mygengo-user) sandbox-url api-base-url)
    method "?"
    (alist->form-urlencoded
     (filter (lambda (x) (pair? x))
             (list (cons 'api_key (mygengo-public-key mygengo-user))
                   api-sig timestamp
                   optional-params))))))

(define set-put-data
  (lambda (a-hash param-symbol param) 
    (if (not (null? param)) 
        (hash-set! a-hash param-symbol param)
        null)
    a-hash))

(define (get-account-stats mygengo-user)
  (get-request-auth-required "account/stats" mygengo-user))

(define (get-account-balance mygengo-user)
  (get-request-auth-required "account/balance" mygengo-user))

(define (get-job-preview job-id mygengo-user)
  (get-request-jpeg
   (format "translate/job/~s/preview" job-id)
   mygengo-user))

(define (get-job-revision job-id rev-id mygengo-user)
  (get-request-auth-required
   (format "translate/job/~s/revision/~s" job-id rev-id)
   mygengo-user))

(define (get-job-feedback job-id mygengo-user)
  (get-request-auth-required
   (format "translate/job/~s/feedback" job-id)
   mygengo-user))

(define (get-job-comments job-id mygengo-user)
  (get-request-auth-required
   (format "translate/job/~s/comments" job-id)
   mygengo-user))

(define (get-job job-id mygengo-user [pre-mt #f])
  (define optional-params
    (if pre-mt (cons 'pre_mt "1") empty))
  (get-request-auth-required
   (format "translate/job/~s" job-id)
   mygengo-user
   optional-params))

(define (get-job-group group-id mygengo-user)
  (get-request-auth-required
   (format "translate/jobs/group/~s" group-id)
   mygengo-user))

(define (get-jobs list-of-job-ids mygengo-user)
  (get-request-auth-required
   (format "translate/jobs/~a"
           (string-join (map number->string list-of-job-ids) ","))
   mygengo-user))

(define (get-language-pairs mygengo-user [lc-src empty])
  (define optional-params
    (if (not (empty? lc-src)) (cons 'lc_src lc-src) empty))
  (get-request-no-auth
   "translate/service/language_pairs"
   mygengo-user
   optional-params))

(define (get-languages mygengo-user)
  (get-request-no-auth
   "translate/service/languages"
   mygengo-user))

(define (post-job-comment job-id comment mygengo-user)
  (define data-hash (make-hash))
  (hash-set! data-hash 'body comment)
  (post-request
   (format "translate/job/~s/comment" job-id)
   (jsexpr->json data-hash)
   mygengo-user))

(define (delete-job job-id mygengo-user)
  (delete-request
   (format "translate/job/~s" job-id)
   mygengo-user))

(define (revise-job job-id comment mygengo-user)
  (define data-hash (make-hash))
  (hash-set! data-hash 'action "revise")
  (hash-set! data-hash 'comment comment)
  (put-request
   (format "translate/job/~s" job-id)
   (jsexpr->json data-hash)
   mygengo-user))

(define (approve-job job-id mygengo-user [rating null]
                     [for-translator null] [for-mygengo null] 
                     [public 0])
  (define data-hash (make-hash))
  (hash-set! data-hash 'action "approve")
  (set-put-data data-hash 'rating rating)
  (set-put-data data-hash 'for_translator for-translator)
  (set-put-data data-hash 'for_mygengo for-mygengo)
  (set-put-data data-hash 'public public)
  (put-request 
   (format "translate/job/~s" job-id)
   (jsexpr->json data-hash)
   mygengo-user))

(define (reject-job job-id mygengo-user reason
                    comment captcha
                    [follow-up "requeue"])
  (define data-hash (make-hash))
  (hash-set! data-hash 'reason reason)
  (hash-set! data-hash 'comment comment)
  (hash-set! data-hash 'captcha captcha)
  (set-put-data data-hash 'follow-up follow-up)
  (put-request
   (format "translate/job/~s" job-id)
   (jsexpr->json data-hash)
   mygengo-user))