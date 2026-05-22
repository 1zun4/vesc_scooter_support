(import "pkg@://vesc_packages/lib_code_server/code_server.vescpkg" 'code-server)
(read-eval-program code-server)

(defun main () {
    (start-code-server)
})

(image-save)
(main)