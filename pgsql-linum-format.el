;;; pgsql-linum-format.el --- Dimitri Fontaine
;;
;; Copyright (C) 2011 Dimitri Fontaine
;;
;; Author: Dimitri Fontaine <dim@tapoueh.org>
;; URL: http://tapoueh.org/
;; Version: 0.2
;; Created: 2011-01-21
;; Keywords: PostgreSQL PLpgSQL linum
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/
;;
;; This file is NOT part of GNU Emacs.
;;
;; Implement a linum-mode hook to display PostgreSQL functions line numbers
;;
(require 'linum)

(defun dim:pgsql-current-func ()
  "return first line number of current function, if any"
  (save-excursion
    (let* ((start (point))
	   (prev-create-function
	    (re-search-backward "create.*function" nil t))
	   (open-as-$$
	    (when prev-create-function
	      ;; limit the search to next semi-colon
	      (let ((next-semi-col (re-search-forward ";" nil t)))
		(goto-char prev-create-function)
		(re-search-forward "AS[^$]*\\$\\([^$\n]*\\)\\$" next-semi-col t))))
	   ($$-name
	    (when open-as-$$ (match-string-no-properties 1)))
	   ($$-line-num
	    (when open-as-$$ (line-number-at-pos)))
	   (begin-line-num
	    (when open-as-$$
	      (unless (looking-at "\n") (forward-char))
	      (if (string-match "begin" (current-word))
		  (1- (line-number-at-pos))
		(line-number-at-pos))))
	   (close-as-$$
	    (when open-as-$$
	      (re-search-forward (format "\\$%s\\$" $$-name) nil t)
	      (beginning-of-line)
	      (point)))
	   (reading-function
	    (when (and open-as-$$ close-as-$$)
	      (and (or (>= start open-as-$$)
		       (and (not (eq $$-line-num begin-line-num))
			    (= (line-number-at-pos start) $$-line-num)))
		   (< start close-as-$$)))))

      (if reading-function begin-line-num nil))))

(defun dim:pgsql-linum-format (line)
  "Return the current line number linum output"
  (if (not (equal major-mode 'sql-mode))
      (format "%S" line)
    (save-excursion
      ;; (goto-line line)
      (goto-char (point-min)) (forward-line (1- line))
      (let ((current-func-start (dim:pgsql-current-func)))
	(if current-func-start
	    (format "%3d %5d" (- line current-func-start) line)
	  (format "%9d" line))))))

(setq linum-format 'dim:pgsql-linum-format)

(provide 'pgsql-linum-format)
