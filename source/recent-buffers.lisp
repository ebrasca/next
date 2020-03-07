;;; recent-buffers.lisp --- Manage list of recent buffers.

(in-package :next)
(annot:enable-annot-syntax)

@export
(defmethod buffer-match-predicate ((buffer buffer))
  (lambda (other-buffer)
    (when other-buffer
      (and (string= (url buffer) (url other-buffer))
           (string= (title buffer) (title other-buffer))))))

(defun recent-buffer-completion-filter ()
  (let ((buffers (ring:recent-list (recent-buffers *browser*))))
    (lambda (input)
      (fuzzy-match input buffers))))

(define-command reopen-buffer ()
  "Reopen queried deleted buffer(s)."
  (with-result (buffers (read-from-minibuffer
                         (make-minibuffer
                          :input-prompt "Reopen buffer(s)"
                          :multi-selection-p t
                          :completion-function (recent-buffer-completion-filter))))
    (dolist (buffer buffers)
      (ring:delete-match (recent-buffers *browser*) (buffer-match-predicate buffer))
      (reload-current-buffer (ipc-buffer-make *browser* :dead-buffer buffer))
      (when (and (eq buffer (first buffers))
                 (focus-on-reopened-buffer-p *browser*))
        (set-current-buffer buffer)))))

(define-command reopen-last-buffer ()
  "Open a new buffer with the URL of the most recently deleted buffer."
  (if (plusp (ring:item-count (recent-buffers *browser*)))
      (let ((buffer (ipc-buffer-make *browser*
                     :dead-buffer (ring:pop-most-recent (recent-buffers *browser*)))))
        (reload-current-buffer buffer)
        (when (focus-on-reopened-buffer-p *browser*)
          (set-current-buffer buffer)))
      (echo "There are no recently-deleted buffers.")))
