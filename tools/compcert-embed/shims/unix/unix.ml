(* The part of Unix that CompCert's driver names, for backends without it
   (Melange). Nothing here touches the operating system: [isatty] is false,
   and starting a process fails with ENOSYS, which the driver already reports
   as a diagnostic. The embed API never starts a process. *)

type error = EINTR | ENOSYS

exception Unix_error of error * string * string

let error_message = function EINTR -> "Interrupted system call" | ENOSYS -> "Function not implemented"

type file_descr = int

let stdin = 0
let stdout = 1
let stderr = 2

type open_flag = O_RDONLY | O_WRONLY | O_RDWR | O_CREAT | O_TRUNC | O_APPEND
type file_perm = int
type process_status = WEXITED of int | WSIGNALED of int | WSTOPPED of int
type wait_flag = WNOHANG | WUNTRACED

let isatty (_ : file_descr) = false
let openfile (name : string) (_ : open_flag list) (_ : file_perm) : file_descr =
  raise (Unix_error (ENOSYS, "openfile", name))

let close (_ : file_descr) = ()

let create_process (prog : string) (_ : string array) (_ : file_descr) (_ : file_descr) (_ : file_descr) : int =
  raise (Unix_error (ENOSYS, "create_process", prog))

let waitpid (_ : wait_flag list) (_ : int) : int * process_status =
  raise (Unix_error (ENOSYS, "waitpid", ""))
