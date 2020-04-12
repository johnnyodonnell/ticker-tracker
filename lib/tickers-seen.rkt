#lang racket

(provide get-seen-tickers
         update-seen-tickers)

(require aws/s3)
(require json)

(require "./aws-init.rkt")


(s3-region "us-west-2")

(define s3-file-path
  (path->string (build-path "tickers-005501675243" "tickers-seen.json")))

(define update-seen-tickers
  (lambda (json-map)
    (put/bytes s3-file-path (jsexpr->bytes json-map) "text/plain")))

(define get-seen-tickers
  (lambda ()
    (bytes->jsexpr (get/bytes s3-file-path))))

