#lang racket

(require racket/tcp)


(define passive-regex #rx#"\\((.*),(.*),(.*),(.*),(.*),(.*)\\)")

(define (bytes->number bytes)
  (string->number (bytes->string/latin-1 bytes)))

(define send-ftp-cmd
  (lambda (cmd tcpout)
    (fprintf tcpout "~a\r\n" cmd)
    (flush-output tcpout)))

(define read-bytes-to-list
  (lambda (in)
    (let ([next-byte (read-byte in)])
      (if (eof-object? next-byte)
        '()
        (cons next-byte (read-bytes-to-list in))))))

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
      (bytes->string/utf-8 (list->bytes (read-bytes-to-list pasv-in))))))

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

      (displayln (ftp-download tcpin tcpout "nasdaqtraded.txt"))
      )))

(get-tickers)

