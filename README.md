A myGengo API client library in Racket.

To use:

First, create a mygengo object with your public key, private key, and boolean for whether you want to use the sandbox (#t is use sandbox)

```Racket
(define shawn
  (mygengo "public key"
           "private key"
           #t))
```

Then you can call the various functions using that object:

```Racket
> (get-account-stats shawn)
'#hasheq((response . #hasheq((user_since . 1320642742) (credits_spent . "-1907.67") (currency . "USD"))) (opstat . "ok"))

> (get-account-balance shawn)
'#hasheq((response . #hasheq((credits . "1907.67") (currency . #\nul))) (opstat . "ok"))

> (get-job-preview 59072 shawn)
; This returns a bitmap object, so if you're using DrRacket, you should see the image preview in the Interactions console.

; (get-job-revision <job-id> <revision-id> <mygengo-user>
> (get-job-revision 59072 445059 shawn)
'#hasheq((response . #hasheq((revision . #hasheq((ctime . 1337322828) (body_tgt . #\nul))))) (opstat . "ok"))

> (get-job-revisions 59072 shawn)
'#hasheq((response
          .
          #hasheq((job_id . "59072")
                  (revisions . (#hasheq((ctime . 1337041968) (rev_id . "438101")) #hasheq((ctime . 1337322828) (rev_id . "445059"))))))
         (opstat . "ok"))

> (get-job-feedback 59072 shawn)
'#hasheq((response . #hasheq((feedback . #hasheq((rating . "3.0") (for_translator . "hi"))))) (opstat . "ok"))

> (post-job-comment 205483 "test comment" shawn)
'#hasheq((response . #hasheq()) (opstat . "ok"))

> (get-job-comments 205483 shawn)
'#hasheq((response . #hasheq((thread . (#hasheq((author . "customer") (body . "test comment") (ctime . 1337740214)))))) (opstat . "ok"))

> (delete-job 205483 shawn)
'#hasheq((response . #hasheq()) (opstat . "ok"))

> (get-job 205485 shawn)
'#hasheq((response
          .
          #hasheq((job
                   .
                   #hasheq((eta . 25128)
                           (status . "pending")
                           (lc_src . "en")
                           (job_id . "205485")
                           (slug . "0")
                           (body_src . "second thing that i want translated")
                           (lc_tgt . "ja")
                           (unit_count . "6")
                           (tier . "standard")
                           (credits . "0.30")
                           (currency . "USD")
                           (ctime . 1337489757)
                           (auto_approve . "0")))))
         (opstat . "ok"))

> (revise-job 205485 "please revise this" shawn)
'#hasheq((response . #hasheq()) (opstat . "ok"))

> (approve-job 205484 shawn)
'#hasheq((response . #hasheq()) (opstat . "ok"))

> (reject-job 205925 shawn "quality" "this wasn't good enough quality for me" "GKDQ")
'#hasheq((response . #hasheq()) (opstat . "ok"))

> (post-job "/Users/shawn/mygengo-racket/single_job_example.json" shawn)
'#hasheq((response
          .
          #hasheq((job
                   .
                   #hasheq((eta . 25164)
                           (status . "available")
                           (lc_src . "en")
                           (body_src . "stuff that i want translated")
                           (lc_tgt . "ja")
                           (tier . "standard")
                           (job_id . "205926")
                           (slug . "0")
                           (unit_count . "5")
                           (credits . "0.25")
                           (currency . "USD")
                           (ctime . 1337741439)
                           (auto_approve . "0")
                           (body_tgt . "(Our machine translator is exhausted and taking a break. Please check back in a bit.)")
                           (mt . 1)))))
         (opstat . "ok"))

> (get-jobs-by-group-id 16367 shawn)
'#hasheq((response . #hasheq((jobs . (#hasheq((job_id . "205944")) #hasheq((job_id . "205945")))) (ctime . 1337749756))) (opstat . "ok"))

> (get-jobs shawn)
'#hasheq((response . (#hasheq((ctime . 1337749756) (job_id . "205944")) #hasheq((ctime . 1337749756) (job_id . "205945")))) (opstat . "ok"))

; only get jobs that have status "available", after epoch timestamp 1337750605, and return the 2 jobs submitted after the since the timestamp.
> (get-jobs shawn "available" 1337750605 2)
'#hasheq((response . (#hasheq((ctime . 1337749756) (job_id . "205944")) #hasheq((ctime . 1337749756) (job_id . "205945")))) (opstat . "ok"))

> (get-jobs-by-job-ids '(205944 205945) shawn)
'#hasheq((response
          .
          #hasheq((jobs
                   .
                   (#hasheq((eta . 25128)
                            (status . "available")
                            (lc_src . "en")
                            (job_id . "205944")
                            (body_src . "some stuff that i want translated")
                            (lc_tgt . "ja")
                            (unit_count . "6")
                            (tier . "standard")
                            (credits . "0.30")
                            (currency . "USD")
                            (ctime . 1337749756)
                            (auto_approve . "0"))
                    #hasheq((eta . 25128)
                            (status . "available")
                            (lc_src . "en")
                            (job_id . "205945")
                            (body_src . "more stuff that i want translated")
                            (lc_tgt . "ja")
                            (unit_count . "6")
                            (tier . "standard")
                            (credits . "0.30")
                            (currency . "USD")
                            (ctime . 1337749756)
                            (auto_approve . "0"))))))
         (opstat . "ok"))

> (post-jobs "/Users/shawn/mygengo-racket/many_jobs_example.json" shawn)
'#hasheq((response
          .
          #hasheq((jobs
                   .
                   (#hasheq((job_one
                             .
                             #hasheq((eta . 25128)
                                     (status . "available")
                                     (lc_src . "en")
                                     (body_src . "some stuff that i want translated")
                                     (lc_tgt . "ja")
                                     (tier . "standard")
                                     (job_id . "205944")
                                     (slug . "0")
                                     (unit_count . "6")
                                     (credits . "0.30")
                                     (currency . "USD")
                                     (ctime . 1337749756)
                                     (auto_approve . "0")
                                     (body_tgt . "(Our machine translator is exhausted and taking a break. Please check back in a bit.)")
                                     (mt . 1))))
                    #hasheq((job_two
                             .
                             #hasheq((eta . 25128)
                                     (status . "available")
                                     (lc_src . "en")
                                     (body_src . "more stuff that i want translated")
                                     (lc_tgt . "ja")
                                     (tier . "standard")
                                     (job_id . "205945")
                                     (slug . "0")
                                     (unit_count . "6")
                                     (credits . "0.30")
                                     (currency . "USD")
                                     (ctime . 1337749756)
                                     (auto_approve . "0")
                                     (body_tgt . "(Our machine translator is exhausted and taking a break. Please check back in a bit.)")
                                     (mt . 1))))))
                  (group_id . 16367)))
         (opstat . "ok"))

> (get-language-pairs shawn)
; returns a big hash full of language pairs that you can translate from (lc_src) to (lc_tgt).

> (get-language-pairs shawn "ja")
'#hasheq((response
          .
          (#hasheq((lc_src . "ja") (lc_tgt . "en") (tier . "standard") (unit_price . "0.0300") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "en") (tier . "pro") (unit_price . "0.0600") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "en") (tier . "ultra") (unit_price . "0.0900") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "es") (tier . "standard") (unit_price . "0.0300") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "es") (tier . "pro") (unit_price . "0.0600") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "es") (tier . "ultra") (unit_price . "0.0900") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "id") (tier . "standard") (unit_price . "0.0300") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "id") (tier . "pro") (unit_price . "0.0600") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "id") (tier . "ultra") (unit_price . "0.0900") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "ko") (tier . "standard") (unit_price . "0.0300") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "ko") (tier . "pro") (unit_price . "0.0600") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "ko") (tier . "ultra") (unit_price . "0.0900") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "zh") (tier . "standard") (unit_price . "0.0300") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "zh") (tier . "pro") (unit_price . "0.0600") (currency . "USD"))
           #hasheq((lc_src . "ja") (lc_tgt . "zh") (tier . "ultra") (unit_price . "0.0900") (currency . "USD"))))
         (opstat . "ok"))

> (get-languages shawn)
'#hasheq((response
          .
          (#hasheq((language . "Arabic") (localized_name . "العربية") (lc . "ar") (unit_type . "character"))
           #hasheq((language . "Indonesian") (localized_name . "Bahasa Indonesia") (lc . "id") (unit_type . "word"))
           #hasheq((language . "Dutch") (localized_name . "Nederlands") (lc . "nl") (unit_type . "word"))
           #hasheq((language . "French (Canada)") (localized_name . "Français (Canada)") (lc . "fr-ca") (unit_type . "word"))
           #hasheq((language . "Polish") (localized_name . "Polski") (lc . "pl") (unit_type . "character"))
           #hasheq((language . "Chinese (Traditional)") (localized_name . "中文 (台湾)") (lc . "zh-tw") (unit_type . "character"))
           #hasheq((language . "Swedish") (localized_name . "Svenska") (lc . "sv") (unit_type . "word"))
           #hasheq((language . "Korean") (localized_name . "한국어") (lc . "ko") (unit_type . "character"))
           #hasheq((language . "Spanish (Latin America)") (localized_name . "Español (América Latina)") (lc . "es-la") (unit_type . "word"))
           #hasheq((language . "Portuguese (Europe)") (localized_name . "Português Europeu") (lc . "pt") (unit_type . "word"))
           #hasheq((language . "English") (localized_name . "English") (lc . "en") (unit_type . "word"))
           #hasheq((language . "Japanese") (localized_name . "日本語") (lc . "ja") (unit_type . "character"))
           #hasheq((language . "Spanish (Spain)") (localized_name . "Español") (lc . "es") (unit_type . "word"))
           #hasheq((language . "Chinese (Simplified)") (localized_name . "中文 (简体)") (lc . "zh") (unit_type . "character"))
           #hasheq((language . "German") (localized_name . "Deutsch") (lc . "de") (unit_type . "word"))
           #hasheq((language . "French") (localized_name . "Français") (lc . "fr") (unit_type . "word"))
           #hasheq((language . "Russian") (localized_name . "русский язык") (lc . "ru") (unit_type . "word"))
           #hasheq((language . "Italian") (localized_name . "Italiano") (lc . "it") (unit_type . "word"))
           #hasheq((language . "Portuguese (Brazil)") (localized_name . "Português Brasileiro") (lc . "pt-br") (unit_type . "word"))))
         (opstat . "ok"))

; json to submit must have jobs key even if it only a single job
> (jobs-quote "/Users/shawn/mygengo-racket/many_jobs_for_quote_example.json" shawn)
'#hasheq((response . #hasheq((jobs . #hasheq((job_one . #hasheq((eta . 25128) (unit_count . 6) (credits . 0.3) (currency . "USD"))))))) (opstat . "ok"))
```
