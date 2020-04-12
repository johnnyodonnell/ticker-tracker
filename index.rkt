#lang racket

(provide handler)

(require date)

(require "./lib/get-tickers.rkt")
(require "./lib/tickers-seen.rkt")
(require "./lib/send-notification.rkt")
(require "./lib/ticker.rkt")


(define handler
  (lambda (event context)
    (let ([tickers-seen (get-seen-tickers)]
          [utc-timestamp (current-date-string-iso-8601 #t)])
      (for-each
        (lambda (ticker)
          (if (hash-has-key? tickers-seen (ticker-symbol ticker))
            (set!
              tickers-seen
              (hash-set
                tickers-seen
                (ticker-symbol ticker)
                (hash-set
                  (hash-ref tickers-seen (ticker-symbol ticker))
                  'time-last-accessed
                  utc-timestamp)))
            (begin
              (displayln
                (format "Found new ticker: ~a" (ticker-symbol ticker)))
              (notify-new-ticker ticker)
              (set!
                tickers-seen
                (hash-set
                  tickers-seen
                  (ticker-symbol ticker)
                  (hasheq 'date-created utc-timestamp))))))
        (get-tickers))
      (update-seen-tickers tickers-seen))))

