#lang racket

(provide notify-new-ticker)

(require aws/sns)
(require aws/util)

(require "./aws-init.rkt")
(require "./ticker.rkt")


(sns-endpoint (endpoint "sns.us-west-2.amazonaws.com" #t))

(sns-region "us-west-2")

(define topic-arn "arn:aws:sns:us-west-2:005501675243:new-ticker-found")

(define notify-new-ticker
  (lambda (ticker)
    (publish
      topic-arn
      (format
        "A new ticker ~a was found on the ~a exchange. Ticker description: ~a"
        (ticker-symbol ticker)
        (ticker-exchange ticker)
        (ticker-description ticker)))))

