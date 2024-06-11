From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:02 +0100
Subject: [PATCH kmod 02/20] man: add scdoc based man pages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240611-man-v1-2-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=36523;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=lbkgwK7cJlLPMsghg4UMx8wCmvzlg+8aV2Z3P4L4tEI=;
 b=ZEsLtsqvisw1VhwPZ/hiMnwW3fn1BkgOYZPwC+mT1b9gvF1AWSIvOC21vb+n1abZSpw6x0ZDF
 w2t9qgZ18snAcTzA9LUAPF3FBwmmn4qMGElx0V2ux6Vop5UrZazJHjm
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Working with xml is quite fiddly. Swap that for scdoc, which has very
trivial markup-like syntax.

We have opted for scdoc since it's available on practically any linux
distribution. Implementation-wise it's a trivial C99 project, at 1k LoC.

If using scdoc proves to be a burden, we can trivially port these to
pandoc or similar - 90% of the content will stay the same.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
Comparing the output via the compare.sh script, we can see a few
advantages of scdoc over xsltproc:

 - uses ISO 8601 date format
 - does not choke for short opt + arg
 - does not escape every non-alphanum char so we get proper word breaks
   and nicer word wrapping

There are a couple of cons though:

 - uses leading [ for table handling, so we need to manually escape it
 - manual indentation with spaces is not allowed, escape again

Initially I was inclined to send patches in upstream scdoc to "fix"
this. Then I noticed that:
 - only a couple of instances are affected
 - both are very crowded and could use some love

I would be happy to prep something up - if anyone has concrete
suggestions, please let me know.
---
 man/depmod.8.scd      | 126 +++++++++++++++++++++++++++++
 man/depmod.d.5.scd    |  95 ++++++++++++++++++++++
 man/insmod.8.scd      |  36 +++++++++
 man/kmod.8.scd        |  48 +++++++++++
 man/lsmod.8.scd       |  30 +++++++
 man/modinfo.8.scd     |  78 ++++++++++++++++++
 man/modprobe.8.scd    | 216 ++++++++++++++++++++++++++++++++++++++++++++++++++
 man/modprobe.d.5.scd  | 168 +++++++++++++++++++++++++++++++++++++++
 man/modules.dep.5.scd |  43 ++++++++++
 man/rmmod.8.scd       |  50 ++++++++++++
 10 files changed, 890 insertions(+)

diff --git a/man/depmod.8.scd b/man/depmod.8.scd
new file mode 100644
index 0000000..0fe9128
--- /dev/null
+++ b/man/depmod.8.scd
@@ -0,0 +1,126 @@
+DEPMOD(8) "kmod" "depmod"
+
+# NAME
+
+depmod - Generate modules.dep and map files.
+
+# SYNOPSIS
+
+*depmod* [*-b* _basedir_] [*-o* _outdir_] [*-e*] [*-E* _Module.symvers_]
+\ \ \ \ \ \ \ \[*-F* _System.map_] [*-n*] [*-v*] [*-A*] [*-P* _prefix_] [*-w*] [_version_]
+
+*depmod* [*-e*] [*-E* _Module.symvers_] [*-F* _System.map_] [*-n*] [*-v*] [*-P* _prefix_]
+\ \ \ \ \ \ \ \[*-w*] [_version_] [_filename_...]
+
+# DESCRIPTION
+
+Linux kernel modules can provide services (called "symbols") for other modules
+to use (using one of the EXPORT_SYMBOL variants in the code). If a second module
+uses this symbol, that second module clearly depends on the first module. These
+dependencies can get quite complex.
+
+*depmod* creates a list of module dependencies by reading each module under
+@MODULE_DIRECTORY@/_version_ and determining what symbols it exports and what
+symbols it needs. By default, this list is written to modules.dep, and a binary
+hashed version named modules.dep.bin, in the same directory. If filenames are
+given on the command line, only those modules are examined (which is rarely
+useful unless all modules are listed). * depmod* also creates a list of symbols
+provided by modules in the file named modules.symbols and its binary hashed
+version, modules.symbols.bin. Finally, *depmod* will output a file named
+modules.devname if modules supply special device names (devname) that should be
+populated in /dev on boot (by a utility such as systemd-tmpfiles).
+
+If a _version_ is provided, then that kernel version's module directory is used
+rather than the current kernel version (as returned by *uname -r*).
+
+# OPTIONS
+
+*-a*, *--all*
+	Probe all modules. This option is enabled by default if no file names
+	are given in the command-line.
+
+*-A*, *--quick*
+	This option scans to see if any modules are newer than the
+	modules.dep file before any work is done: if not, it silently exits
+	rather than regenerating the files.
+
+*-b* _basedir_, *--basedir* _basedir_
+	If your modules are not currently in the (normal) directory
+	@MODULE_DIRECTORY@/_version_, but in a staging area, you can specify a
+	_basedir_ which is prepended to the directory name. This _basedir_ is
+	stripped from the resulting modules.dep file, so it is ready to be moved
+	into the normal location. Use this option if you are a distribution
+	vendor who needs to pre-generate the meta-data files rather than running
+	depmod again later.
+
+*-o* _outdir_, *--outdir* _outdir_
+	Set the output directory where depmod will store any generated file.
+	_ outdir_ serves as a root to that location, similar to how _basedir_ is
+	used. Also this setting takes precedence and if used together with
+	_basedir_ it will result in the input being that directory, but the output
+	being the one set by _outdir_.
+
+*-C*, *--config* _file_ _or_ _directory_
+	This option overrides the default configuration directory at
+	/etc/depmod.d/.
+
+*-e*, *--errsyms*
+	When combined with the *-F* option, this reports any symbols which a
+	module needs which are not supplied by other modules or the kernel.
+	Normally, any symbols not provided by modules are assumed to be provided
+	by the kernel (which should be true in a perfect world), but this
+	assumption can break especially when additionally updated third party
+	drivers are not correctly installed or were built incorrectly.
+
+*-E*, *--symvers*
+	When combined with the *-e* option, this reports any symbol versions
+	supplied by modules that do not match with the symbol versions provided
+	by the kernel in its Module.symvers. This option is mutually
+	incompatible with *-F*.
+
+*-F*, *--filesyms* _System.map_
+	Supplied with the System.map produced when the kernel was built, this
+	allows the *-e* option to report unresolved symbols. This option is
+	mutually incompatible with *-E*.
+
+*-h*, *--help*
+	Print the help message and exit.
+
+*-n*, *--show*, *--dry-run*
+	This sends the resulting modules.dep and the various map files to
+	standard output rather than writing them into the module directory.
+
+*-P*
+	Some architectures prefix symbols with an extraneous character. This
+	specifies a prefix character (for example '\_') to ignore.
+
+*-v*, *--verbose*
+	In verbose mode, *depmod* will print (to stdout) all the symbols each
+	module depends on and the module's file name which provides that symbol.
+
+*-V*, *--version*
+	Show version of program and exit. See below for caveats when run on
+	older kernels.
+
+*-w*
+	Warn on duplicate dependencies, aliases, symbol versions, etc.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
+Portions Copyright Jon Masters, and others.
+
+# SEE ALSO
+
+*depmod.d*(5), *modprobe*(8), *modules.dep*(5)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Robby Workman* <rworkman@slackware.com>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/depmod.d.5.scd b/man/depmod.d.5.scd
new file mode 100644
index 0000000..9c42478
--- /dev/null
+++ b/man/depmod.d.5.scd
@@ -0,0 +1,95 @@
+DEPMOD.D(5) "kmod" "depmod.d"
+
+# NAME
+
+depmod.d - Configuration directory for depmod
+
+# SYNOPSIS
+
+/lib/depmod.d/\*.conf
+
+@DISTCONFDIR@/depmod.d/\*.conf
+
+/usr/local/lib/depmod.d/\*.conf
+
+/run/depmod.d/\*.conf
+
+/etc/depmod.d/\*.conf
+
+# DESCRIPTION
+
+The order in which modules are processed by the *depmod* command can be altered
+on a global or per-module basis. This is typically useful in cases where
+built-in kernel modules are complemented by custom built versions of the same
+and the user wishes to affect the priority of processing in order to override
+the module version supplied by the kernel.
+
+The format of files under depmod.d is simple: one command per line, with blank
+lines and lines starting with '#' ignored (useful for adding comments). A '\\'
+at the end of a line causes it to continue on the next line, which makes the
+files a bit neater.
+
+# COMMANDS
+
+search _subdirectory..._
+	This allows you to specify the order in which @MODULE_DIRECTORY@ (or
+	other configured module location) subdirectories will be processed by
+	*depmod*. Directories are listed in order, with the highest priority
+	given to the first listed directory and the lowest priority given to the
+	last directory listed. The special keyword *built-in* refers to the
+	standard module directories installed by the kernel. Another special
+	keyword *external* refers to the list of external directories, defined
+	by the *external* command.
+
+	By default, depmod will give a higher priority to a directory with the
+	name *updates* using this built-in search string: "updates built-in" but
+	more complex arrangements are possible and are used in several popular
+	distributions.
+
+override _modulename_ _kernelversion_ _modulesubdirectory_
+	This command allows you to override which version of a specific module
+	will be used when more than one module sharing the same name is
+	processed by the *depmod* command. It is possible to specify one kernel
+	or all kernels using the \* wildcard. _ modulesubdirectory_ is the name
+	of the subdirectory under @MODULE_DIRECTORY@ (or other module location)
+	where the target module is installed.
+
+	For example, it is possible to override the priority of an updated test
+	module called *kmod* by specifying the following command: "override
+	kmod \* extra". This will ensure that any matching module name installed
+	under the *extra* subdirectory within @MODULE_DIRECTORY@ (or other
+	module location) will take priority over any likenamed module already
+	provided by the kernel.
+
+external _kernelversion_ _absolutemodulesdirectory..._
+	This specifies a list of directories, which will be checked according to
+	the priorities in the *search* command. The order matters also, the
+	first directory has the higher priority.
+
+	The _kernelversion_ is a POSIX regular expression or \* wildcard, like
+	in the *override*.
+
+exclude _excludedir_
+	This specifies the trailing directories that will be excluded during the
+	search for kernel modules.
+
+	The _excludedir_ is the trailing directory to exclude
+
+# COPYRIGHT
+
+This manual page Copyright 2006-2010, Jon Masters, Red Hat, Inc.
+
+# SEE ALSO
+
+*depmod*(8)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Robby Workman* <rworkman@slackware.com>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/insmod.8.scd b/man/insmod.8.scd
new file mode 100644
index 0000000..b6f8654
--- /dev/null
+++ b/man/insmod.8.scd
@@ -0,0 +1,36 @@
+INSMOD(8) "kmod" "insmod"
+
+# NAME
+
+insmod - Simple program to insert a module into the Linux Kernel
+
+# SYNOPSIS
+
+*insmod* [_filename_] [_module options_...]
+
+# DESCRIPTION
+
+*insmod* is a trivial program to insert a module into the kernel. Most users
+will want to use* modprobe*(8) instead, which is more clever and can handle
+module dependencies.
+
+Only the most general of error messages are reported: as the work of trying to
+link the module is now done inside the kernel, the *dmesg* usually gives more
+information about errors.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
+Maintained by Jon Masters and others.
+
+# SEE ALSO
+
+*modprobe*(8), *rmmod*(8), *lsmod*(8), *modinfo*(8) *depmod*(8)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/kmod.8.scd b/man/kmod.8.scd
new file mode 100644
index 0000000..d292a13
--- /dev/null
+++ b/man/kmod.8.scd
@@ -0,0 +1,48 @@
+KMOD(8) "kmod" "kmod"
+
+# NAME
+
+kmod - Program to manage Linux Kernel modules
+
+# SYNOPSIS
+
+*kmod* [*OPTIONS*...] [_COMMAND_] [*COMMAND_OPTIONS*...]
+
+# DESCRIPTION
+
+*kmod* is a multi-call binary which implements the programs used to control
+Linux Kernel modules. Most users will only run it using its other names.
+
+# OPTIONS
+
+*-V --version*
+	Show the program version and exit.
+
+*-h --help*
+	Show the help message.
+
+# COMMANDS
+
+*help*
+	Show the help message.
+
+*list*
+	List the currently loaded modules.
+
+*static-nodes*
+	Output the static device nodes information provided by the modules of
+	the currently running kernel version.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2014, Marco d'Itri. Maintained by Lucas De
+Marchi and others.
+
+# SEE ALSO
+
+*lsmod*(8), *rmmod*(8), *insmod*(8), *modinfo*(8), *modprobe*(8), *depmod*(8)
+
+# AUTHOR
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/lsmod.8.scd b/man/lsmod.8.scd
new file mode 100644
index 0000000..7195cba
--- /dev/null
+++ b/man/lsmod.8.scd
@@ -0,0 +1,30 @@
+LSMOD(8) "kmod" "lsmod"
+
+# NAME
+
+lsmod - Show the status of modules in the Linux Kernel
+
+# SYNOPSIS
+*lsmod*
+
+# DESCRIPTION
+
+*lsmod* is a trivial program which nicely formats the contents of the
+/proc/modules, showing what kernel modules are currently loaded.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
+Maintained by Jon Masters and others.
+
+# SEE ALSO
+
+*insmod*(8), *modprobe*(8), *modinfo*(8) *depmod*(8)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/modinfo.8.scd b/man/modinfo.8.scd
new file mode 100644
index 0000000..fd945ce
--- /dev/null
+++ b/man/modinfo.8.scd
@@ -0,0 +1,78 @@
+MODINFO(8) "kmod" "modinfo"
+
+# NAME
+
+modinfo - Show information about a Linux Kernel module
+
+# SYNOPSIS
+
+*modinfo* [*-0*] [*-F* _field_] [*-k* _kernel_] [modulename|filename...]
+
+*modinfo* *-V*
+
+*modinfo* *-h*
+
+# DESCRIPTION
+
+*modinfo* extracts information from the Linux Kernel modules given on the
+command line. If the module name is not a filename, then the @MODULE_DIRECTORY@/
+_version_ directory is searched, as is also done by *modprobe*(8) when loading
+kernel modules.
+
+*modinfo* by default lists each attribute of the module in form _fieldname_ :
+_value_, for easy reading. The filename is listed the same way (although it's
+not really an attribute).
+
+This version of *modinfo* can understand modules of any Linux Kernel
+architecture.
+
+# OPTIONS
+
+*-V*, *--version*
+	Print the modinfo version.
+
+*-F*, *--field*
+	Only print this field value, one per line. This is most useful for
+	scripts. Field names are case-insensitive. Common fields (which may not
+	be in every module) include author, description, license, parm, depends,
+	and alias. There are often multiple parm, alias and depends fields. The
+	special field filename lists the filename of the module.
+
+*-b* _basedir_, *--basedir* _basedir_
+	Root directory for modules, / by default.
+
+*-k* _kernel_
+	Provide information about a kernel other than the running one. This is
+	particularly useful for distributions needing to extract information
+	from a newly installed (but not yet running) set of kernel modules. For
+	example, you wish to find which firmware files are needed by various
+	modules in a new kernel for which you must make an initrd/initramfs
+	image prior to booting.
+
+*-0*, *--null*
+	Use the ASCII zero character to separate field values, instead of a new
+	line. This is useful for scripts, since a new line can theoretically
+	appear inside a field.
+
+*-a* *--author*, *-d* *--description*, *-l* *--license*, *-p* *--parameters*,
+*-n* *--filename*
+	These are shortcuts for the *--field* flag's author, description,
+	license, parm and filename arguments, to ease the transition from the
+	old modutils *modinfo*.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2003, Rusty Russell, IBM Corporation.
+Maintained by Jon Masters and others.
+
+# SEE ALSO
+
+*modprobe*(8)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
new file mode 100644
index 0000000..f678654
--- /dev/null
+++ b/man/modprobe.8.scd
@@ -0,0 +1,216 @@
+MODPROBE(8) "kmod" "modprobe"
+
+# NAME
+
+modprobe - Add and remove modules from the Linux Kernel
+
+# SYNOPSIS
+
+*modprobe* [*-v*] [*-V*] [*-C *_config-file_] [*-n*] [*-i*] [*-q*] [*-b*] [_modulename_]
+\ \ \ \ \ \ \ \ \ \[_module parameters_...]
+
+*modprobe* [-r] [*-v*] [*-n*] [*-i*] [_modulename_...]
+
+*modprobe* [-c]
+
+*modprobe* [--dump-modversions] [_filename_]
+
+# DESCRIPTION
+
+*modprobe* intelligently adds or removes a module from the Linux kernel: note
+that for convenience, there is no difference between \_ and - in module names
+(automatic underscore conversion is performed). * modprobe* looks in the module
+directory @DISTCONFDIR@/`uname -r` for all the modules and other files, except
+for the optional configuration files in the /etc/modprobe.d directory (see
+*modprobe.d*(5)). * modprobe* will also use module options specified on the
+kernel command line in the form of <module>.<option> and blacklists in the form
+of modprobe.blacklist=<module>.
+
+Note that unlike in 2.4 series Linux kernels (which are not supported by this
+tool) this version of *modprobe* does not do anything to the module itself: the
+work of resolving symbols and understanding parameters is done inside the
+kernel. So module failure is sometimes accompanied by a kernel message: see
+*dmesg*(8).
+
+*modprobe* expects an up-to-date modules.dep.bin file as generated by the
+corresponding *depmod* utility shipped along with *modprobe* (see *depmod*(8)).
+This file lists what other modules each module needs (if any), and *modprobe*
+uses this to add or remove these dependencies automatically.
+
+If any arguments are given after the _modulename_, they are passed to the kernel
+(in addition to any options listed in the configuration file).
+
+When loading modules, _modulename_ can also be a path to the module. If the path
+is relative, it must explicitly start with "./". Note that this may fail when
+using a path to a module with dependencies not matching the installed depmod
+database.
+
+# OPTIONS
+
+*-a*, *--all*
+	Insert all module names on the command line.
+
+*-b*, *--use-blacklist*
+	This option causes *modprobe* to apply the *blacklist* commands in the
+	configuration files (if any) to module names as well. It is usually used
+	by *udev*(7).
+
+*-C*, *--config*
+	This option overrides the default configuration directory
+	(/etc/modprobe.d).
+
+	This option is passed through *install* or *remove* commands to other
+	*modprobe* commands in the MODPROBE_OPTIONS environment variable.
+
+*-c*, *--showconfig*
+	Dump out the effective configuration from the config directory and exit.
+
+*--dump-modversions*
+	Print out a list of module versioning information required by a module.
+	This option is commonly used by distributions in order to package up a
+	Linux kernel module using module versioning deps.
+
+*-d*, *--dirname*
+	Root directory for modules, / by default.
+
+*--first-time*
+	Normally, *modprobe* will succeed (and do nothing) if told to insert a
+	module which is already present or to remove a module which isn't
+	present. This is ideal for simple scripts; however, more complicated
+	scripts often want to know whether *modprobe* really did something: this
+	option makes modprobe fail in the case that it actually didn't do
+	anything.
+
+*--force-vermagic*
+	Every module contains a small string containing important information,
+	such as the kernel and compiler versions. If a module fails to load and
+	the kernel complains that the "version magic" doesn't match, you can use
+	this option to remove it. Naturally, this check is there for your
+	protection, so using this option is dangerous unless you know what
+	you're doing.
+
+	This applies to any modules inserted: both the module (or alias) on the
+	command line and any modules on which it depends.
+
+*--force-modversion*
+	When modules are compiled with CONFIG_MODVERSIONS set, a section
+	detailing the versions of every interfaced used by (or supplied by) the
+	module is created. If a module fails to load and the kernel complains
+	that the module disagrees about a version of some interface, you can use
+	"--force-modversion" to remove the version information altogether.
+	Naturally, this check is there for your protection, so using this option
+	is dangerous unless you know what you're doing.
+
+	This applies any modules inserted: both the module (or alias) on the
+	command line and any modules on which it depends.
+
+*-f*, *--force*
+	Try to strip any versioning information from the module which might
+	otherwise stop it from loading: this is the same as using both
+	*--force-vermagic* and *--force-modversion*. Naturally, these checks are
+	there for your protection, so using this option is dangerous unless you
+	know what you are doing.
+
+	This applies to any modules inserted: both the module (or alias) on the
+	command line and any modules it on which it depends.
+
+*-i*, *--ignore-install*, *--ignore-remove*
+	This option causes *modprobe* to ignore *install* and *remove* commands
+	in the configuration file (if any) for the module specified on the
+	command line (any dependent modules are still subject to commands set
+	for them in the configuration file). Both *install* and *remove* commands
+	will currently be ignored when this option is used regardless of whether
+	the request was more specifically made with only one or other (and not
+	both) of *--ignore-install* or *--ignore-remove*. See *modprobe.d*(5).
+
+*-n*, *--dry-run*, *--show*
+	This option does everything but actually insert or delete the modules
+	(or run the install or remove commands). Combined with *-v*, it is
+	useful for debugging problems. For historical reasons both *--dry-run*
+	and *--show* actually mean the same thing and are interchangeable.
+
+*-q*, *--quiet*
+	With this flag, *modprobe* won't print an error message if you try to
+	remove or insert a module it can't find (and isn't an alias or
+	*install*/*remove* command). However, it will still return with a non-zero
+	exit status. The kernel uses this to opportunistically probe for modules
+	which might exist using request_module.
+
+*-R*, *--resolve-alias*
+	Print all module names matching an alias. This can be useful for
+	debugging module alias problems.
+
+*-r*, *--remove*
+	This option causes *modprobe* to remove rather than insert a module. If
+	the modules it depends on are also unused, *modprobe* will try to remove
+	them too. Unlike insertion, more than one module can be specified on the
+	command line (it does not make sense to specify module parameters when
+	removing modules).
+
+	There is usually no reason to remove modules, but some buggy modules
+	require it. Your distribution kernel may not have been built to support
+	removal of modules at all.
+
+*-w*, *--wait=*TIMEOUT_MSEC
+	This option causes *modprobe -r *to continue trying to remove a module
+	if it fails due to the module being busy, i.e. its refcount is not 0 at
+	the time the call is made. Modprobe tries to remove the module with an
+	incremental sleep time between each tentative up until the maximum wait
+	time in milliseconds passed in this option.
+
+*-S*, *--set-version*
+	Set the kernel version, rather than using *uname*(2) to decide on the
+	kernel version (which dictates where to find the modules).
+
+*--show-depends*
+	List the dependencies of a module (or alias), including the module
+	itself. This produces a (possibly empty) set of module filenames, one
+	per line, each starting with "insmod" and is typically used by
+	distributions to determine which modules to include when generating
+	initrd/initramfs images. * Install* commands which apply are shown
+	prefixed by "install". It does not run any of the install commands. Note
+	that *modinfo*(8) can be used to extract dependencies of a module from the
+	module itself, but knows nothing of aliases or install commands.
+
+*-s*, *--syslog*
+	This option causes any error messages to go through the syslog mechanism
+	(as LOG_DAEMON with level LOG_NOTICE) rather than to standard error.
+	This is also automatically enabled when stderr is unavailable.
+
+	This option is passed through *install* or *remove* commands to other
+	*modprobe* commands in the MODPROBE_OPTIONS environment variable.
+
+*-V*, *--version*
+	Show version of program and exit.
+
+*-v*, *--verbose*
+	Print messages about what the program is doing. Usually *modprobe* only
+	prints messages if something goes wrong.
+
+	This option is passed through *install* or *remove* commands to other
+	*modprobe* commands in the MODPROBE_OPTIONS environment variable.
+
+# ENVIRONMENT
+
+The MODPROBE_OPTIONS environment variable can also be used to pass arguments to
+*modprobe*.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
+Maintained by Jon Masters and others.
+
+# SEE ALSO
+
+*modprobe.d*(5), *insmod*(8), *rmmod*(8), *lsmod*(8), *modinfo*(8) *depmod*(8)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Robby Workman* <rworkman@slackware.com>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/modprobe.d.5.scd b/man/modprobe.d.5.scd
new file mode 100644
index 0000000..93b9522
--- /dev/null
+++ b/man/modprobe.d.5.scd
@@ -0,0 +1,168 @@
+MODPROBE.D(5) "kmod" "modprobe.d"
+
+# NAME
+
+modprobe.d - Configuration directory for modprobe
+
+# SYNOPSIS
+
+/lib/modprobe.d/\*.conf
+
+@DISTCONFDIR@/modprobe.d/\*.conf
+
+/usr/local/lib/modprobe.d/\*.conf
+
+/run/modprobe.d/\*.conf
+
+/etc/modprobe.d/\*.conf
+
+# DESCRIPTION
+
+Because the *modprobe* command can add or remove more than one module, due to
+modules having dependencies, we need a method of specifying what options are to
+be used with those modules. All files underneath the /etc/modprobe.d directory
+which end with the .conf extension specify those options as required. They can
+also be used to create convenient aliases: alternate names for a module, or they
+can override the normal *modprobe* behavior altogether for those with special
+requirements (such as inserting more than one module).
+
+Note that module and alias names (like other module names) can have - or \_ in
+them: both are interchangeable throughout all the module commands as underscore
+conversion happens automatically.
+
+The format of files under modprobe.d is simple: one command per line, with blank
+lines and lines starting with '#' ignored (useful for adding comments). A '\\'
+at the end of a line causes it to continue on the next line, which makes the
+file a bit neater.
+
+# COMMANDS
+
+alias _wildcard_ _modulename_
+	This allows you to give alternate names for a module. For example:
+	"alias my-mod really_long_modulename" means you can use "modprobe
+	my-mod" instead of "modprobe really_long_modulename". You can also use
+	shell-style wildcards, so "alias my-mod\* really_long_modulename" means
+	that "modprobe my-mod-something" has the same effect. You can't have
+	aliases to other aliases (that way lies madness), but aliases can have
+	options, which will be added to any other options.
+
+	Note that modules can also contain their own aliases, which you can see
+	using *modinfo*. These aliases are used as a last resort (ie. if there
+	is no real module, *install*, *remove*, or *alias* command in the
+	configuration).
+
+blacklist _modulename_
+	Modules can contain their own aliases: usually these are aliases
+	describing the devices they support, such as "pci:123...". These
+	"internal" aliases can be overridden by normal "alias" keywords, but
+	there are cases where two or more modules both support the same devices,
+	or a module invalidly claims to support a device that it does not: the
+	*blacklist* keyword indicates that all of that particular module's
+	internal aliases are to be ignored.
+
+install _modulename_ _command..._
+	This command instructs *modprobe* to run your command instead of
+	inserting the module in the kernel as normal. The command can be any
+	shell command: this allows you to do any kind of complex processing you
+	might wish. For example, if the module "fred" works better with the
+	module "barney" already installed (but it doesn't depend on it, so
+	*modprobe* won't automatically load it), you could say "install fred
+	/sbin/modprobe barney; /sbin/modprobe --ignore-install fred", which
+	would do what you wanted. Note the *--ignore-install*, which stops the
+	second *modprobe* from running the same *install* command again. See
+	also *remove* below.
+
+	The long term future of this command as a solution to the problem of
+	providing additional module dependencies is not assured and it is
+	intended to replace this command with a warning about its eventual
+	removal or deprecation at some point in a future release. Its use
+	complicates the automated determination of module dependencies by
+	distribution utilities, such as mkinitrd (because these now need to
+	somehow interpret what the *install* commands might be doing. In a
+	perfect world, modules would provide all dependency information without
+	the use of this command and work is underway to implement soft
+	dependency support within the Linux kernel.
+
+	If you use the string "$CMDLINE_OPTS" in the command, it will be
+	replaced by any options specified on the modprobe command line. This can
+	be useful because users expect "modprobe fred opt=1" to pass the "opt=1"
+	arg to the module, even if there's an install command in the
+	configuration file. So our above example becomes "install fred
+	/sbin/modprobe barney; /sbin/modprobe --ignore-install fred
+	$CMDLINE_OPTS"
+
+options _modulename_ _option..._
+	This command allows you to add options to the module _modulename_ (which
+	might be an alias) every time it is inserted into the kernel: whether
+	directly (using *modprobe* _ modulename_) or because the module being
+	inserted depends on this module.
+
+	All options are added together: they can come from an *option* for the
+	module itself, for an alias, and on the command line.
+
+remove _modulename_ _command..._
+	This is similar to the *install* command above, except it is invoked
+	when "modprobe -r" is run.
+
+softdep _modulename_ pre: _modules..._ post: _modules..._
+	The *softdep* command allows you to specify soft, or optional, module
+	dependencies. _ modulename_ can be used without these optional modules
+	installed, but usually with some features missing. For example, a driver
+	for a storage HBA might require another module be loaded in order to use
+	management features.
+
+	pre-deps and post-deps modules are lists of names and/or aliases of
+	other modules that modprobe will attempt to install (or remove) in order
+	before and after the main module given in the _modulename_ argument.
+
+	Example: Assume "softdep c pre: a b post: d e" is provided in the
+	configuration. Running "modprobe c" is now equivalent to "modprobe a b c
+	d e" without the softdep. Flags such as --use-blacklist are applied to
+	all the specified modules, while module parameters only apply to module
+	c.
+
+	Note: if there are *install* or *remove* commands with the same
+	_modulename_ argument, *softdep* takes precedence.
+
+weakdep _modulename_ _modules..._
+	The *weakdep* command allows you to specify weak module dependencies.
+	Those are similar to pre softdep, with the difference that userspace
+	doesn't attempt to load that dependency before the specified module.
+	Instead the kernel may request one or multiple of them during module
+	probe, depending on the hardware it's binding to. The purpose of weak
+	module is to allow a driver to specify that a certain dependency may be
+	needed, so it should be present in the filesystem (e.g. in initramfs)
+	when that module is probed.
+
+	Example: Assume "weakdep c a b". A program creating an initramfs knows
+	it should add a, b, and c to the filesystem since a and b may be
+	required/desired at runtime. When c is loaded and is being probed, it
+	may issue calls to request_module() causing a or b to also be loaded.
+
+# COMPATIBILITY
+
+A future version of kmod will come with a strong warning to avoid use of the
+*install* as explained above. This will happen once support for soft
+dependencies in the kernel is complete. That support will complement the
+existing softdep support within this utility by providing such dependencies
+directly within the modules.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2004, Rusty Russell, IBM Corporation.
+Maintained by Jon Masters and others.
+
+# SEE ALSO
+
+*modprobe*(8), *modules.dep*(5)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Robby Workman* <rworkman@slackware.com>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/modules.dep.5.scd b/man/modules.dep.5.scd
new file mode 100644
index 0000000..34ffb83
--- /dev/null
+++ b/man/modules.dep.5.scd
@@ -0,0 +1,43 @@
+MODULES.DEP(5) "kmod" "modules.dep"
+
+# NAME
+
+modules.dep, modules.dep.bin - Module dependency information
+
+# SYNOPSIS
+
+@MODULE_DIRECTORY@/modules.dep
+
+@MODULE_DIRECTORY@/modules.dep.bin
+
+# DESCRIPTION
+
+modules.dep.bin is a binary file generated by *depmod* listing the dependencies
+for every module in the directories under @MODULE_DIRECTORY@/_version_. It is
+used by kmod tools such as *modprobe* and libkmod.
+
+Its text counterpart is located in the same directory with the name
+modules.dep. The text version is maintained only for easy of reading by humans
+and is in no way used by any kmod tool.
+
+These files are not intended for editing or use by any additional utilities as
+their format is subject to change in the future. You should use the *modinfo*(8)
+command to obtain information about modules in a future proof and compatible
+fashion rather than touching these files.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
+Maintained by Jon Masters and others.
+
+# SEE ALSO
+
+*depmod*(8), *modprobe*(8)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer
diff --git a/man/rmmod.8.scd b/man/rmmod.8.scd
new file mode 100644
index 0000000..72947a6
--- /dev/null
+++ b/man/rmmod.8.scd
@@ -0,0 +1,50 @@
+RMMOD(8) "kmod" "rmmod"
+
+# NAME
+
+rmmod - Simple program to remove a module from the Linux Kernel
+
+# SYNOPSIS
+
+*rmmod* [*-f*] [*-s*] [*-v*] [_modulename_]
+
+# DESCRIPTION
+
+*rmmod* is a trivial program to remove a module (when module unloading support
+is provided) from the kernel. Most users will want to use *modprobe*(8) with the
+*-r* option instead since it removes unused dependent modules as well.
+
+# OPTIONS
+
+*-v*, *--verbose*
+	Print messages about what the program is doing. Usually *rmmod* prints
+	messages only if something goes wrong.
+
+*-f*, *--force*
+	This option can be extremely dangerous: it has no effect unless
+	CONFIG_MODULE_FORCE_UNLOAD was set when the kernel was compiled. With
+	this option, you can remove modules which are being used, or which are
+	not designed to be removed, or have been marked as unsafe (see *lsmod*(8)).
+
+*-s*, *--syslog*
+	Send errors to syslog instead of standard error.
+
+*-V --version*
+	Show version of program and exit.
+
+# COPYRIGHT
+
+This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
+Maintained by Jon Masters and others.
+
+# SEE ALSO
+
+*modprobe*(8), *insmod*(8), *lsmod*(8), *modinfo*(8) *depmod*(8)
+
+# AUTHORS
+
+*Jon Masters* <jcm@jonmasters.org>
+	Developer
+
+*Lucas De Marchi* <lucas.de.marchi@gmail.com>
+	Developer

-- 
2.45.0

