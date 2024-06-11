From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:05 +0100
Subject: [PATCH kmod 05/20] man: add some extra bold/italic annotations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240611-man-v1-5-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=8611;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=4+XNcKsNSqVWUEv7Fxf4RGoF3gHdf6x19eyWUX/0mdA=;
 b=iudBmav1qM9IGW0qGALL8FfbsD8t0dDMMTNVo+KrbCobv2pIfes/Do0rCLQobMAg8+MG5mNIE
 oUHDLAO3D0sC70F93rMLjG5/z2BWqpamHGtTN3K+4WeQorUzVgkiR84
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/depmod.8.scd      | 18 +++++++++---------
 man/kmod.8.scd        |  2 +-
 man/modinfo.8.scd     |  8 ++++----
 man/modprobe.8.scd    | 12 ++++++------
 man/modules.dep.5.scd | 11 ++++++-----
 man/rmmod.8.scd       |  2 +-
 6 files changed, 27 insertions(+), 26 deletions(-)

diff --git a/man/depmod.8.scd b/man/depmod.8.scd
index 0fe9128..8cb6449 100644
--- a/man/depmod.8.scd
+++ b/man/depmod.8.scd
@@ -21,7 +21,7 @@ dependencies can get quite complex.
 
 *depmod* creates a list of module dependencies by reading each module under
 @MODULE_DIRECTORY@/_version_ and determining what symbols it exports and what
-symbols it needs. By default, this list is written to modules.dep, and a binary
+symbols it needs. By default, this list is written to *modules.dep*, and a binary
 hashed version named modules.dep.bin, in the same directory. If filenames are
 given on the command line, only those modules are examined (which is rarely
 useful unless all modules are listed). * depmod* also creates a list of symbols
@@ -41,17 +41,17 @@ rather than the current kernel version (as returned by *uname -r*).
 
 *-A*, *--quick*
 	This option scans to see if any modules are newer than the
-	modules.dep file before any work is done: if not, it silently exits
+	*modules.dep* file before any work is done: if not, it silently exits
 	rather than regenerating the files.
 
 *-b* _basedir_, *--basedir* _basedir_
 	If your modules are not currently in the (normal) directory
 	@MODULE_DIRECTORY@/_version_, but in a staging area, you can specify a
 	_basedir_ which is prepended to the directory name. This _basedir_ is
-	stripped from the resulting modules.dep file, so it is ready to be moved
-	into the normal location. Use this option if you are a distribution
-	vendor who needs to pre-generate the meta-data files rather than running
-	depmod again later.
+	stripped from the resulting *modules.dep* file, so it is ready to be
+	moved into the normal location. Use this option if you are a
+	distribution vendor who needs to pre-generate the meta-data files rather
+	than running *depmod* again later.
 
 *-o* _outdir_, *--outdir* _outdir_
 	Set the output directory where depmod will store any generated file.
@@ -75,11 +75,11 @@ rather than the current kernel version (as returned by *uname -r*).
 *-E*, *--symvers*
 	When combined with the *-e* option, this reports any symbol versions
 	supplied by modules that do not match with the symbol versions provided
-	by the kernel in its Module.symvers. This option is mutually
+	by the kernel in its _Module.symvers_. This option is mutually
 	incompatible with *-F*.
 
 *-F*, *--filesyms* _System.map_
-	Supplied with the System.map produced when the kernel was built, this
+	Supplied with the _System.map_ produced when the kernel was built, this
 	allows the *-e* option to report unresolved symbols. This option is
 	mutually incompatible with *-E*.
 
@@ -87,7 +87,7 @@ rather than the current kernel version (as returned by *uname -r*).
 	Print the help message and exit.
 
 *-n*, *--show*, *--dry-run*
-	This sends the resulting modules.dep and the various map files to
+	This sends the resulting *modules.dep* and the various map files to
 	standard output rather than writing them into the module directory.
 
 *-P*
diff --git a/man/kmod.8.scd b/man/kmod.8.scd
index d292a13..7bef863 100644
--- a/man/kmod.8.scd
+++ b/man/kmod.8.scd
@@ -6,7 +6,7 @@ kmod - Program to manage Linux Kernel modules
 
 # SYNOPSIS
 
-*kmod* [*OPTIONS*...] [_COMMAND_] [*COMMAND_OPTIONS*...]
+*kmod* [*OPTIONS...*] [_COMMAND_] [*COMMAND_OPTIONS...*]
 
 # DESCRIPTION
 
diff --git a/man/modinfo.8.scd b/man/modinfo.8.scd
index fd945ce..75267bc 100644
--- a/man/modinfo.8.scd
+++ b/man/modinfo.8.scd
@@ -29,14 +29,14 @@ architecture.
 # OPTIONS
 
 *-V*, *--version*
-	Print the modinfo version.
+	Print the *modinfo* version.
 
 *-F*, *--field*
 	Only print this field value, one per line. This is most useful for
 	scripts. Field names are case-insensitive. Common fields (which may not
 	be in every module) include author, description, license, parm, depends,
 	and alias. There are often multiple parm, alias and depends fields. The
-	special field filename lists the filename of the module.
+	special _field_ filename lists the filename of the module.
 
 *-b* _basedir_, *--basedir* _basedir_
 	Root directory for modules, / by default.
@@ -50,9 +50,9 @@ architecture.
 	image prior to booting.
 
 *-0*, *--null*
-	Use the ASCII zero character to separate field values, instead of a new
+	Use the ASCII zero character to separate _field_ values, instead of a new
 	line. This is useful for scripts, since a new line can theoretically
-	appear inside a field.
+	appear inside a _field_.
 
 *-a* *--author*, *-d* *--description*, *-l* *--license*, *-p* *--parameters*,
 *-n* *--filename*
diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index f678654..653fbd9 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -9,11 +9,11 @@ modprobe - Add and remove modules from the Linux Kernel
 *modprobe* [*-v*] [*-V*] [*-C *_config-file_] [*-n*] [*-i*] [*-q*] [*-b*] [_modulename_]
 \ \ \ \ \ \ \ \ \ \[_module parameters_...]
 
-*modprobe* [-r] [*-v*] [*-n*] [*-i*] [_modulename_...]
+*modprobe* [*-r*] [*-v*] [*-n*] [*-i*] [_modulename_...]
 
-*modprobe* [-c]
+*modprobe* [*-c*]
 
-*modprobe* [--dump-modversions] [_filename_]
+*modprobe* [*--dump-modversions*] [_filename_]
 
 # DESCRIPTION
 
@@ -42,7 +42,7 @@ If any arguments are given after the _modulename_, they are passed to the kernel
 
 When loading modules, _modulename_ can also be a path to the module. If the path
 is relative, it must explicitly start with "./". Note that this may fail when
-using a path to a module with dependencies not matching the installed depmod
+using a path to a module with dependencies not matching the installed *depmod*
 database.
 
 # OPTIONS
@@ -78,7 +78,7 @@ database.
 	module which is already present or to remove a module which isn't
 	present. This is ideal for simple scripts; however, more complicated
 	scripts often want to know whether *modprobe* really did something: this
-	option makes modprobe fail in the case that it actually didn't do
+	option makes *modprobe* fail in the case that it actually didn't do
 	anything.
 
 *--force-vermagic*
@@ -97,7 +97,7 @@ database.
 	detailing the versions of every interfaced used by (or supplied by) the
 	module is created. If a module fails to load and the kernel complains
 	that the module disagrees about a version of some interface, you can use
-	"--force-modversion" to remove the version information altogether.
+	*--force-modversion* to remove the version information altogether.
 	Naturally, this check is there for your protection, so using this option
 	is dangerous unless you know what you're doing.
 
diff --git a/man/modules.dep.5.scd b/man/modules.dep.5.scd
index 34ffb83..c4e7653 100644
--- a/man/modules.dep.5.scd
+++ b/man/modules.dep.5.scd
@@ -12,13 +12,14 @@ modules.dep, modules.dep.bin - Module dependency information
 
 # DESCRIPTION
 
-modules.dep.bin is a binary file generated by *depmod* listing the dependencies
-for every module in the directories under @MODULE_DIRECTORY@/_version_. It is
-used by kmod tools such as *modprobe* and libkmod.
+*modules.dep.bin* is a binary file generated by *depmod* listing the
+dependencies for every module in the directories under
+@MODULE_DIRECTORY@/_version_. It is used by *kmod* tools such as *modprobe* and
+libkmod.
 
 Its text counterpart is located in the same directory with the name
-modules.dep. The text version is maintained only for easy of reading by humans
-and is in no way used by any kmod tool.
+*modules.dep*. The text version is maintained only for easy of reading by humans
+and is in no way used by any *kmod* tool.
 
 These files are not intended for editing or use by any additional utilities as
 their format is subject to change in the future. You should use the *modinfo*(8)
diff --git a/man/rmmod.8.scd b/man/rmmod.8.scd
index 72947a6..7813448 100644
--- a/man/rmmod.8.scd
+++ b/man/rmmod.8.scd
@@ -29,7 +29,7 @@ is provided) from the kernel. Most users will want to use *modprobe*(8) with the
 *-s*, *--syslog*
 	Send errors to syslog instead of standard error.
 
-*-V --version*
+*-V*, *--version*
 	Show version of program and exit.
 
 # COPYRIGHT

-- 
2.45.0

