#lang racket

(provide get-tickers)

(require racket/tcp)
(require csv-reading)

(require "./ticker.rkt")


(define convert-to-exchange
  (lambda (sym)
    (case sym
      [("N") 'nyse]
      [("Q") 'nasdaq]
      [else 'other])))

(define make-list-iterator
  (lambda (lst)
    (lambda ([num-of-forward-iterations 0])
      (let loop ([i 0])
        (let ([popped-value (car lst)])
          (set! lst (cdr lst))
          (if (= i num-of-forward-iterations)
            popped-value
            (loop (+ i 1))))))))

(define convert-csv-line-to-ticker
  (lambda (csv-line)
    (let ([iterator (make-list-iterator csv-line)])
      (ticker (string->symbol (iterator 1))
              (iterator)
              (convert-to-exchange (iterator))))))

(define passive-regex #rx#"\\((.*),(.*),(.*),(.*),(.*),(.*)\\)")

(define ticker-csv-reader-maker
  (make-csv-reader-maker
    '((separator-chars #\|))))

(define (bytes->number bytes)
  (string->number (bytes->string/latin-1 bytes)))

(define send-ftp-cmd
  (lambda (cmd tcpout)
    (fprintf tcpout "~a\r\n" cmd)
    (flush-output tcpout)))

(define create-passive-connection
  (lambda (tcpin tcpout)
    (send-ftp-cmd "PASV" tcpout)
    (let* ([response (read-bytes-line tcpin 'any)]
           [connection-info (regexp-match passive-regex response)])
      (displayln response)
      (tcp-connect
        (format "~a.~a.~a.~a"
                (list-ref connection-info 1)
                (list-ref connection-info 2)
                (list-ref connection-info 3)
                (list-ref connection-info 4))
        (+ (* 256 (bytes->number (list-ref connection-info 5)))
           (bytes->number (list-ref connection-info 6)))))))

(define ftp-download
  (lambda (tcpin tcpout filename)
    (let-values ([(pasv-in pasv-out) (create-passive-connection tcpin tcpout)])
      (send-ftp-cmd "TYPE I" tcpout)
      (displayln (read-bytes-line tcpin 'any))
      (tcp-abandon-port pasv-out)
      (send-ftp-cmd (format "RETR ~a" filename) tcpout)
      (displayln (read-bytes-line tcpin 'any))
      pasv-in)))

(define get-tickers
  (lambda ()
    (let-values ([(tcpin tcpout) (tcp-connect "ftp.nasdaqtrader.com" 21)])
      (displayln (read-bytes-line tcpin 'any))
      (send-ftp-cmd "USER anonymous" tcpout)
      (displayln (read-bytes-line tcpin 'any))
      (send-ftp-cmd "PASS anonymous" tcpout)
      (displayln (read-bytes-line tcpin 'any))
      (send-ftp-cmd "CWD SymbolDirectory" tcpout)
      (displayln (read-bytes-line tcpin 'any))

      (filter
        (lambda (ticker)
          (or (eq? (ticker-exchange ticker) 'nasdaq)
              (eq? (ticker-exchange ticker) 'nyse)))
        (csv-map
          convert-csv-line-to-ticker
          (ticker-csv-reader-maker
            (ftp-download tcpin tcpout "nasdaqtraded.txt")))))))

