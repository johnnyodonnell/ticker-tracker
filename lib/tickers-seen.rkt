#lang racket

(provide get-seen-tickers
         update-seen-tickers)

(require aws/keys)
(require aws/s3)
(require json)


(let ([key-id (getenv "AWS_ACCESS_KEY_ID")]
      [secret-key (getenv "AWS_SECRET_ACCESS_KEY")]
      [session-token (getenv "AWS_SESSION_TOKEN")])
  (public-key key-id)
  (private-key secret-key)
  (when session-token
    (security-token session-token)))

(s3-region "us-west-2")

(define s3-file-path
  (path->string (build-path "tickers-005501675243" "tickers-seen.json")))

(displayln s3-file-path)

(define update-seen-tickers
  (lambda (json-map)
    (put/bytes s3-file-path (jsexpr->bytes json-map) "text/plain")))

(define get-seen-tickers
  (lambda ()
    (bytes->jsexpr (get/bytes s3-file-path))))

