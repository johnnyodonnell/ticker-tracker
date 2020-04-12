#lang racket

(require aws/keys)


(displayln "Setting AWS credentials...")

(let ([key-id (getenv "AWS_ACCESS_KEY_ID")]
      [secret-key (getenv "AWS_SECRET_ACCESS_KEY")]
      [session-token (getenv "AWS_SESSION_TOKEN")])
  (public-key key-id)
  (private-key secret-key)
  (when session-token
    (security-token session-token)))

