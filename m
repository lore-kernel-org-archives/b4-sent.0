From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:20 +0100
Subject: [PATCH kmod 20/20] man: list options one per line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-20-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=12342;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=iEsXEhrs2v3OLHp+4HwYCKBxvEq3t2+J74GNP/VdBA8=;
 b=S1l4ZzvEyIWtIEtrL5t2w1pOpH60IaWEuAw5qBjXZu3GOdqkrIu34p+LuS0T9zytbEse6la49
 KHkBX0+xd+aCbnODi5aDpXS+/uNTnSR3YDev3xEg1v0zeq8IWUA8iDk
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Somewhat inspired by my selfish use of VIM as man pager. Namely, when
there are multiple options on the same line, only the first one gets
properly rendered.

A good bonus point is that very long instances, like modinfo's legacy
"--author, --description ..." look a bit neater now.

With this is also more consistently handle short/long options which take
an argument.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/depmod.8.scd   | 37 +++++++++++++++++++++++++------------
 man/kmod.8.scd     |  6 ++++--
 man/modinfo.8.scd  | 17 ++++++++++++-----
 man/modprobe.8.scd | 50 ++++++++++++++++++++++++++++++++++----------------
 man/rmmod.8.scd    | 12 ++++++++----
 5 files changed, 83 insertions(+), 39 deletions(-)

diff --git a/man/depmod.8.scd b/man/depmod.8.scd
index 0252a72..8c87a64 100644
--- a/man/depmod.8.scd
+++ b/man/depmod.8.scd
@@ -35,16 +35,19 @@ rather than the current kernel version (as returned by *uname -r*).
 
 # OPTIONS
 
-*-a*, *--all*
+*-a*
+*--all*
 	Probe all modules. This option is enabled by default if no file names
 	are given in the command-line.
 
-*-A*, *--quick*
+*-A*
+*--quick*
 	This option scans to see if any modules are newer than the
 	*modules.dep* file before any work is done: if not, it silently exits
 	rather than regenerating the files.
 
-*-b* _basedir_, *--basedir* _basedir_
+*-b* _basedir_
+*--basedir* _basedir_
 	If your modules are not currently in the (normal) directory
 	@MODULE_DIRECTORY@/_version_, but in a staging area, you can specify a
 	_basedir_ which is prepended to the directory name. This _basedir_ is
@@ -53,18 +56,21 @@ rather than the current kernel version (as returned by *uname -r*).
 	distribution vendor who needs to pre-generate the meta-data files rather
 	than running *depmod* again later.
 
-*-o* _outdir_, *--outdir* _outdir_
+*-o* _outdir_
+*--outdir* _outdir_
 	Set the output directory where *depmod* will store any generated file.
 	_outdir_ serves as a root to that location, similar to how _basedir_ is
 	used. Also this setting takes precedence and if used together with
 	_basedir_ it will result in the input being that directory, but the output
 	being the one set by _outdir_.
 
-*-C*, *--config* _file_ _or_ _directory_
+*-C*  _file_ _or_ _directory_
+*--config* _file_ _or_ _directory_
 	This option overrides the default configuration files. See
 	*depmod.d*(5).
 
-*-e*, *--errsyms*
+*-e*
+*--errsyms*
 	When combined with the *-F* option, this reports any symbols which a
 	module needs which are not supplied by other modules or the kernel.
 	Normally, any symbols not provided by modules are assumed to be provided
@@ -72,21 +78,26 @@ rather than the current kernel version (as returned by *uname -r*).
 	assumption can break especially when additionally updated third party
 	drivers are not correctly installed or were built incorrectly.
 
-*-E*, *--symvers* _Module.symvers_
+*-E* _Module.symvers_
+*--symvers* _Module.symvers_
 	When combined with the *-e* option, this reports any symbol versions
 	supplied by modules that do not match with the symbol versions provided
 	by the kernel in its _Module.symvers_. This option is mutually
 	incompatible with *-F*.
 
-*-F*, *--filesyms* _System.map_
+*-F* _System.map_
+*--filesyms* _System.map_
 	Supplied with the _System.map_ produced when the kernel was built, this
 	allows the *-e* option to report unresolved symbols. This option is
 	mutually incompatible with *-E*.
 
-*-h*, *--help*
+*-h*
+*--help*
 	Print the help message and exit.
 
-*-n*, *--show*, *--dry-run*
+*-n*
+*--show*
+*--dry-run*
 	This sends the resulting *modules.dep* and the various map files to
 	standard output rather than writing them into the module directory.
 
@@ -94,11 +105,13 @@ rather than the current kernel version (as returned by *uname -r*).
 	Some architectures prefix symbols with an extraneous character. This
 	specifies a prefix character (for example '\_') to ignore.
 
-*-v*, *--verbose*
+*-v*
+*--verbose*
 	In verbose mode, *depmod* will print (to stdout) all the symbols each
 	module depends on and the module's file name which provides that symbol.
 
-*-V*, *--version*
+*-V*
+*--version*
 	Show version of program and exit. See below for caveats when run on
 	older kernels.
 
diff --git a/man/kmod.8.scd b/man/kmod.8.scd
index 6bd9432..ff80c2f 100644
--- a/man/kmod.8.scd
+++ b/man/kmod.8.scd
@@ -15,10 +15,12 @@ Linux Kernel modules. Most users will only run it using its other names.
 
 # OPTIONS
 
-*-V*, *--version*
+*-V*
+*--version*
 	Show the program version and exit.
 
-*-h*, *--help*
+*-h*
+*--help*
 	Show the help message.
 
 # COMMANDS
diff --git a/man/modinfo.8.scd b/man/modinfo.8.scd
index d088c7e..038234d 100644
--- a/man/modinfo.8.scd
+++ b/man/modinfo.8.scd
@@ -28,17 +28,20 @@ architecture.
 
 # OPTIONS
 
-*-V*, *--version*
+*-V*
+*--version*
 	Print the *modinfo* version.
 
-*-F* _field_, *--field* _field_
+*-F* _field_
+*--field* _field_
 	Only print this _field_ value, one per line. This is most useful for
 	scripts. Field names are case-insensitive. Common fields (which may not
 	be in every module) include author, description, license, parm, depends,
 	and alias. There are often multiple parm, alias and depends fields. The
 	special _field_ filename lists the filename of the module.
 
-*-b* _basedir_, *--basedir* _basedir_
+*-b* _basedir_
+*--basedir* _basedir_
 	Root directory for modules, / by default.
 
 *-k* _kernel_
@@ -49,12 +52,16 @@ architecture.
 	modules in a new kernel for which you must make an initrd/initramfs
 	image prior to booting.
 
-*-0*, *--null*
+*-0*
+*--null*
 	Use the ASCII zero character to separate _field_ values, instead of a new
 	line. This is useful for scripts, since a new line can theoretically
 	appear inside a _field_.
 
-*-a* *--author*, *-d* *--description*, *-l* *--license*, *-p* *--parameters*,
+*-a* *--author*
+*-d* *--description*
+*-l* *--license*
+*-p* *--parameters*
 *-n* *--filename*
 	These are shortcuts for the *--field* flag's author, description,
 	license, parm and filename arguments, to ease the transition from the
diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index 657d172..a06cf31 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -46,22 +46,26 @@ database.
 
 # OPTIONS
 
-*-a*, *--all*
+*-a*
+*--all*
 	Insert all module names on the command line.
 
-*-b*, *--use-blacklist*
+*-b*
+*--use-blacklist*
 	This option causes *modprobe* to apply the *blacklist* commands in the
 	configuration files (if any) to module names as well. It is usually used
 	by *udev*(7).
 
-*-C* _directory_, *--config* _directory_
+*-C* _directory_
+*--config* _directory_
 	This option overrides the default configuration directory. See
 	*modprobe.d*(5).
 
 	This option is passed through *install* or *remove* commands to other
 	*modprobe* commands in the MODPROBE_OPTIONS environment variable.
 
-*-c*, *--showconfig*
+*-c*
+*--showconfig*
 	Dump out the effective configuration from the config directory and exit.
 
 *--dump-modversions*
@@ -69,7 +73,8 @@ database.
 	This option is commonly used by distributions in order to package up a
 	Linux kernel module using module versioning deps.
 
-*-d*, *--dirname*
+*-d*
+*--dirname*
 	Root directory for modules, / by default.
 
 *--first-time*
@@ -103,7 +108,8 @@ database.
 	This applies to any modules inserted: both the module (or alias) on the
 	command line and any modules on which it depends.
 
-*-f*, *--force*
+*-f*
+*--force*
 	Try to strip any versioning information from the module which might
 	otherwise stop it from loading: this is the same as using both
 	*--force-vermagic* and *--force-modversion*. Naturally, these checks are
@@ -113,7 +119,9 @@ database.
 	This applies to any modules inserted: both the module (or alias) on the
 	command line and any modules on which it depends.
 
-*-i*, *--ignore-install*, *--ignore-remove*
+*-i*
+*--ignore-install*
+*--ignore-remove*
 	This option causes *modprobe* to ignore *install* and *remove* commands
 	in the configuration file (if any) for the module specified on the
 	command line (any dependent modules are still subject to commands set
@@ -122,24 +130,29 @@ database.
 	the request was more specifically made with only one or other (and not
 	both) of *--ignore-install* or *--ignore-remove*. See *modprobe.d*(5).
 
-*-n*, *--dry-run*, *--show*
+*-n*
+*--dry-run*
+*--show*
 	This option does everything but actually insert or delete the modules
 	(or run the install or remove commands). Combined with *-v*, it is
 	useful for debugging problems. For historical reasons both *--dry-run*
 	and *--show* actually mean the same thing and are interchangeable.
 
-*-q*, *--quiet*
+*-q*
+*--quiet*
 	With this flag, *modprobe* won't print an error message if you try to
 	remove or insert a module it can't find (and isn't an alias or
 	*install*/*remove* command). However, it will still return with a non-zero
 	exit status. The kernel uses this to opportunistically probe for modules
 	which might exist using request_module.
 
-*-R*, *--resolve-alias*
+*-R*
+*--resolve-alias*
 	Print all module names matching an alias. This can be useful for
 	debugging module alias problems.
 
-*-r*, *--remove*
+***-r*
+*--remove*
 	This option causes *modprobe* to remove rather than insert a module. If
 	the modules it depends on are also unused, *modprobe* will try to remove
 	them too. Unlike insertion, more than one module can be specified on the
@@ -150,14 +163,16 @@ database.
 	require it. Your distribution kernel may not have been built to support
 	removal of modules at all.
 
-*-w* _TIMEOUT_MSEC_, *--wait* _TIMEOUT_MSEC_
+*-w* _TIMEOUT_MSEC_
+*--wait* _TIMEOUT_MSEC_
 	This option causes *modprobe -r *to continue trying to remove a module
 	if it fails due to the module being busy, i.e. its refcount is not 0 at
 	the time the call is made. Modprobe tries to remove the module with an
 	incremental sleep time between each tentative up until the maximum wait
 	time in milliseconds passed in this option.
 
-*-S* _version_, *--set-version* _version_
+*-S* _version_
+*--set-version* _version_
 	Set the kernel version, rather than using *uname*(2) to decide on the
 	kernel version (which dictates where to find the modules).
 
@@ -171,7 +186,8 @@ database.
 	that *modinfo*(8) can be used to extract dependencies of a module from the
 	module itself, but knows nothing of aliases or install commands.
 
-*-s*, *--syslog*
+*-s*
+*--syslog*
 	This option causes any error messages to go through the syslog mechanism
 	(as LOG_DAEMON with level LOG_NOTICE) rather than to standard error.
 	This is also automatically enabled when stderr is unavailable.
@@ -179,10 +195,12 @@ database.
 	This option is passed through *install* or *remove* commands to other
 	*modprobe* commands in the MODPROBE_OPTIONS environment variable.
 
-*-V*, *--version*
+*-V*
+*--version*
 	Show version of program and exit.
 
-*-v*, *--verbose*
+*-v*
+*--verbose*
 	Print messages about what the program is doing. Usually *modprobe* only
 	prints messages if something goes wrong.
 
diff --git a/man/rmmod.8.scd b/man/rmmod.8.scd
index c4dcc3e..1baed99 100644
--- a/man/rmmod.8.scd
+++ b/man/rmmod.8.scd
@@ -16,20 +16,24 @@ is provided) from the kernel. Most users will want to use *modprobe*(8) with the
 
 # OPTIONS
 
-*-v*, *--verbose*
+*-v*
+*--verbose*
 	Print messages about what the program is doing. Usually *rmmod* prints
 	messages only if something goes wrong.
 
-*-f*, *--force*
+*-f*
+*--force*
 	This option can be extremely dangerous: it has no effect unless
 	CONFIG_MODULE_FORCE_UNLOAD was set when the kernel was compiled. With
 	this option, you can remove modules which are being used, or which are
 	not designed to be removed, or have been marked as unsafe (see *lsmod*(8)).
 
-*-s*, *--syslog*
+*-s*
+*--syslog*
 	Send errors to syslog instead of standard error.
 
-*-V*, *--version*
+*-V*
+*--version*
 	Show version of program and exit.
 
 # COPYRIGHT

-- 
2.45.0

