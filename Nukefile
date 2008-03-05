
;; source files
(set @m_files     (filelist -"^objc/.*\.m$"))
(set @nu_files 	  (filelist -"^nu/.*\.nu$"))

;; framework description
(set @framework "NuTcl")
(set @framework_identifier "nu.programming.tcl")
(set @framework_creator_code "????")

;; libraries
(ifDarwin
         (then
              (set @ldflags "-framework Foundation -framework Nu -ltcl -ledit"))
         (else
              (set @includes "-I /usr/include/tcl8.4") ;; set this as needed
              (set @ldflags "-L /usr/lib/tcl8.4 -ltcl8.4 -lreadline -lNu -lNuFound")))

(compilation-tasks)
(framework-tasks)

(task "clobber" => "clean" is
      (SH "rm -rf #{@framework_dir}"))

(task "default" => "framework")

(task "doc" is (SH "nudoc"))

(task "install" => "framework" is
      (SH "sudo rm -rf /Library/Frameworks/#{@framework}.framework")
      (SH "ditto #{@framework}.framework /Library/Frameworks/#{@framework}.framework"))

(task "test" => "framework" is
      (SH "nutest test/test_*.nu"))

