#lang racket

(provide (struct-out ticker))


(struct ticker (symbol description exchange))

