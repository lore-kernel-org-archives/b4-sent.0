From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:07:57 +0000
Subject: [PATCH kmod] Remove unmaintained experimental tools
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-rm-experimental-v1-1-b97ab3004ae3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGxQymUC/x3MSwqAMAxF0a1IxhaaoAhuRRz4edWAVmlFhOLeL
 Q7v4NxEEUERqS0SBdwa9fA5uCxoWge/wOicm8RKZYXFhN3gOTPa4a9hM8Ls0DQYHdeU1Rng9Pm
 PXf++H66DmClhAAAA
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707757682; l=24543;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=y+RUZfomsZsunS5CjuBGe9RMo/aUxAOppQ8e48nl1go=;
 b=KregD2vlt5+R1n1oB623ReCnR3/YVLMrBCdqfAmMJKiWpj0XVh4OSy/MY8kiKfTsAG0dsTnJ4
 MdP0Wo+tx0lCDzN2Vjzz3yaXxHs0RAkxJw+2BBmf/O/nhJeRkYyGV/p
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kmod insert/remove tools were introduced back in 2015. Since then
they have recieved zero attention, unlike the insmod/rmmod variants.

Glancing around - neither of the following distributions (Arch, Fedora,
Gentoo, Debian) build them, so we're safe to say they have no users.

Remove them and alongside it the --enable-experimental toggle, which no
longer controls anything.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
With the recent removal of the experimental and unmaintained python
bindings, I've noticed that we still have the insert/remove tools.
---
 Makefile.am                                        |  16 ---
 configure.ac                                       |  10 --
 testsuite/.gitignore                               |   3 -
 .../insert/lib/modules/4.4.4/modules.alias         |   1 -
 .../insert/lib/modules/4.4.4/modules.alias.bin     | Bin 12 -> 0 bytes
 .../insert/lib/modules/4.4.4/modules.builtin       |   0
 .../insert/lib/modules/4.4.4/modules.builtin.bin   | Bin 12 -> 0 bytes
 .../insert/lib/modules/4.4.4/modules.dep           |   1 -
 .../insert/lib/modules/4.4.4/modules.dep.bin       | Bin 58 -> 0 bytes
 .../insert/lib/modules/4.4.4/modules.devname       |   1 -
 .../insert/lib/modules/4.4.4/modules.order         |   0
 .../insert/lib/modules/4.4.4/modules.softdep       |   1 -
 .../insert/lib/modules/4.4.4/modules.symbols       |   1 -
 .../insert/lib/modules/4.4.4/modules.symbols.bin   | Bin 12 -> 0 bytes
 .../remove/lib/modules/4.4.4/modules.alias         |   1 -
 .../remove/lib/modules/4.4.4/modules.alias.bin     | Bin 12 -> 0 bytes
 .../remove/lib/modules/4.4.4/modules.builtin       |   0
 .../remove/lib/modules/4.4.4/modules.builtin.bin   | Bin 12 -> 0 bytes
 .../remove/lib/modules/4.4.4/modules.dep           |   1 -
 .../remove/lib/modules/4.4.4/modules.dep.bin       | Bin 58 -> 0 bytes
 .../remove/lib/modules/4.4.4/modules.devname       |   1 -
 .../remove/lib/modules/4.4.4/modules.order         |   0
 .../remove/lib/modules/4.4.4/modules.softdep       |   1 -
 .../remove/lib/modules/4.4.4/modules.symbols       |   1 -
 .../remove/lib/modules/4.4.4/modules.symbols.bin   | Bin 12 -> 0 bytes
 .../sys/module/mod_simple/holders/.gitignore       |   0
 .../remove/sys/module/mod_simple/initstate         |   1 -
 .../test-tools/remove/sys/module/mod_simple/refcnt |   1 -
 testsuite/setup-rootfs.sh                          |   2 -
 testsuite/test-tools.c                             |  71 ----------
 tools/insert.c                                     | 128 -----------------
 tools/kmod.c                                       |   5 -
 tools/remove.c                                     | 153 ---------------------
 33 files changed, 400 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index 6d21ad2..9c35014 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -129,12 +129,6 @@ tools_kmod_SOURCES = \
 	tools/depmod.c tools/log.h tools/log.c \
 	tools/static-nodes.c
 
-if BUILD_EXPERIMENTAL
-tools_kmod_SOURCES += \
-	tools/insert.c \
-	tools/remove.c
-endif
-
 tools_kmod_LDADD = \
 	shared/libshared.la \
 	libkmod/libkmod-internal.la
@@ -260,11 +254,6 @@ TESTSUITE = \
 	testsuite/test-dependencies testsuite/test-depmod \
 	testsuite/test-list
 
-if BUILD_EXPERIMENTAL
-TESTSUITE += \
-	testsuite/test-tools
-endif
-
 check_PROGRAMS = $(TESTSUITE)
 TESTS = $(TESTSUITE)
 
@@ -307,11 +296,6 @@ testsuite_test_depmod_CPPFLAGS = $(TESTSUITE_CPPFLAGS)
 testsuite_test_list_LDADD = $(TESTSUITE_LDADD)
 testsuite_test_list_CPPFLAGS = $(TESTSUITE_CPPFLAGS)
 
-if BUILD_EXPERIMENTAL
-testsuite_test_tools_LDADD = $(TESTSUITE_LDADD)
-testsuite_test_tools_CPPFLAGS = $(TESTSUITE_CPPFLAGS)
-endif
-
 testsuite-distclean:
 	$(RM) -r $(ROOTFS)
 	$(RM) testsuite/stamp-rootfs
diff --git a/configure.ac b/configure.ac
index bfabbaa..8410ea1 100644
--- a/configure.ac
+++ b/configure.ac
@@ -175,15 +175,6 @@ AC_SUBST([bashcompletiondir], [$with_bashcompletiondir])
 # --enable-
 #####################################################################
 
-AC_ARG_ENABLE([experimental],
-        AS_HELP_STRING([--enable-experimental], [enable experimental tools and features. Do not enable it unless you know what you are doing. @<:@default=disabled@:>@]),
-        [], enable_experimental=no)
-AM_CONDITIONAL([BUILD_EXPERIMENTAL], [test "x$enable_experimental" = "xyes"])
-AS_IF([test "x$enable_experimental" = "xyes"], [
-	AC_DEFINE(ENABLE_EXPERIMENTAL, [1], [Experimental features.])
-])
-CC_FEATURE_APPEND([with_features], [enable_experimental], [EXPERIMENTAL])
-
 AC_ARG_ENABLE([tools],
         AS_HELP_STRING([--disable-tools], [disable building tools that provide same functionality as module-init-tools @<:@default=enabled@:>@]),
 	[], enable_tools=yes)
@@ -336,7 +327,6 @@ AC_MSG_RESULT([
 	cflags:			${with_cflags} ${CFLAGS}
 	ldflags:		${with_ldflags} ${LDFLAGS}
 
-	experimental features:  ${enable_experimental}
 	tools:			${enable_tools}
 	logging:		${enable_logging}
 	compression:		zstd=${with_zstd}  xz=${with_xz}  zlib=${with_zlib}
diff --git a/testsuite/.gitignore b/testsuite/.gitignore
index 9d26b88..5465b1a 100644
--- a/testsuite/.gitignore
+++ b/testsuite/.gitignore
@@ -18,7 +18,6 @@
 /test-modprobe
 /test-hash
 /test-list
-/test-tools
 /rootfs
 /stamp-rootfs
 /test-scratchbuf.log
@@ -53,5 +52,3 @@
 /test-testsuite.trs
 /test-list.log
 /test-list.trs
-/test-tools.log
-/test-tools.trs
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.alias b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.alias
deleted file mode 100644
index ba76e18..0000000
--- a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.alias
+++ /dev/null
@@ -1 +0,0 @@
-# Aliases extracted from modules themselves.
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.alias.bin b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.alias.bin
deleted file mode 100644
index 7075435..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.alias.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.builtin b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.builtin
deleted file mode 100644
index e69de29..0000000
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.builtin.bin b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.builtin.bin
deleted file mode 100644
index 7075435..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.builtin.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.dep b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.dep
deleted file mode 100644
index 5476653..0000000
--- a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.dep
+++ /dev/null
@@ -1 +0,0 @@
-kernel/mod-simple.ko:
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.dep.bin b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.dep.bin
deleted file mode 100644
index b09a854..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.dep.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.devname b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.devname
deleted file mode 100644
index 58f6d6d..0000000
--- a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.devname
+++ /dev/null
@@ -1 +0,0 @@
-# Device nodes to trigger on-demand module loading.
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.order b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.order
deleted file mode 100644
index e69de29..0000000
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.softdep b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.softdep
deleted file mode 100644
index 5554ccc..0000000
--- a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.softdep
+++ /dev/null
@@ -1 +0,0 @@
-# Soft dependencies extracted from modules themselves.
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.symbols b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.symbols
deleted file mode 100644
index 618c345..0000000
--- a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.symbols
+++ /dev/null
@@ -1 +0,0 @@
-# Aliases for symbols, used by symbol_request().
diff --git a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.symbols.bin b/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.symbols.bin
deleted file mode 100644
index 7075435..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/insert/lib/modules/4.4.4/modules.symbols.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.alias b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.alias
deleted file mode 100644
index ba76e18..0000000
--- a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.alias
+++ /dev/null
@@ -1 +0,0 @@
-# Aliases extracted from modules themselves.
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.alias.bin b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.alias.bin
deleted file mode 100644
index 7075435..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.alias.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.builtin b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.builtin
deleted file mode 100644
index e69de29..0000000
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.builtin.bin b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.builtin.bin
deleted file mode 100644
index 7075435..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.builtin.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.dep b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.dep
deleted file mode 100644
index 5476653..0000000
--- a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.dep
+++ /dev/null
@@ -1 +0,0 @@
-kernel/mod-simple.ko:
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.dep.bin b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.dep.bin
deleted file mode 100644
index b09a854..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.dep.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.devname b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.devname
deleted file mode 100644
index 58f6d6d..0000000
--- a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.devname
+++ /dev/null
@@ -1 +0,0 @@
-# Device nodes to trigger on-demand module loading.
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.order b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.order
deleted file mode 100644
index e69de29..0000000
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.softdep b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.softdep
deleted file mode 100644
index 5554ccc..0000000
--- a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.softdep
+++ /dev/null
@@ -1 +0,0 @@
-# Soft dependencies extracted from modules themselves.
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.symbols b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.symbols
deleted file mode 100644
index 618c345..0000000
--- a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.symbols
+++ /dev/null
@@ -1 +0,0 @@
-# Aliases for symbols, used by symbol_request().
diff --git a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.symbols.bin b/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.symbols.bin
deleted file mode 100644
index 7075435..0000000
Binary files a/testsuite/rootfs-pristine/test-tools/remove/lib/modules/4.4.4/modules.symbols.bin and /dev/null differ
diff --git a/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/holders/.gitignore b/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/holders/.gitignore
deleted file mode 100644
index e69de29..0000000
diff --git a/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/initstate b/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/initstate
deleted file mode 100644
index e23fe64..0000000
--- a/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/initstate
+++ /dev/null
@@ -1 +0,0 @@
-live
diff --git a/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/refcnt b/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/refcnt
deleted file mode 100644
index 573541a..0000000
--- a/testsuite/rootfs-pristine/test-tools/remove/sys/module/mod_simple/refcnt
+++ /dev/null
@@ -1 +0,0 @@
-0
diff --git a/testsuite/setup-rootfs.sh b/testsuite/setup-rootfs.sh
index a780f93..5477c69 100755
--- a/testsuite/setup-rootfs.sh
+++ b/testsuite/setup-rootfs.sh
@@ -103,8 +103,6 @@ map=(
     ["test-modinfo/mod-simple-sha256.ko"]="mod-simple.ko"
     ["test-modinfo/mod-simple-pkcs7.ko"]="mod-simple.ko"
     ["test-modinfo/external/lib/modules/external/mod-simple.ko"]="mod-simple.ko"
-    ["test-tools/insert$MODULE_DIRECTORY/4.4.4/kernel/"]="mod-simple.ko"
-    ["test-tools/remove$MODULE_DIRECTORY/4.4.4/kernel/"]="mod-simple.ko"
 )
 
 gzip_array=(
diff --git a/testsuite/test-tools.c b/testsuite/test-tools.c
deleted file mode 100644
index 4a9ee9b..0000000
--- a/testsuite/test-tools.c
+++ /dev/null
@@ -1,71 +0,0 @@
-/*
- * Copyright (C) 2015 Intel Corporation. All rights reserved.
- *
- * This program is free software; you can redistribute it and/or
- * modify it under the terms of the GNU Lesser General Public
- * License as published by the Free Software Foundation; either
- * version 2.1 of the License, or (at your option) any later version.
- *
- * This program is distributed in the hope that it will be useful,
- * but WITHOUT ANY WARRANTY; without even the implied warranty of
- * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
- * Lesser General Public License for more details.
- *
- * You should have received a copy of the GNU Lesser General Public
- * License along with this library; if not, see <http://www.gnu.org/licenses/>.
- */
-
-#include <errno.h>
-#include <inttypes.h>
-#include <stddef.h>
-#include <stdio.h>
-#include <stdlib.h>
-#include <string.h>
-#include <unistd.h>
-
-#include "testsuite.h"
-
-static noreturn int kmod_tool_insert(const struct test *t)
-{
-	const char *progname = ABS_TOP_BUILDDIR "/tools/kmod";
-	const char *const args[] = {
-		progname,
-		"insert", "mod-simple",
-		NULL,
-	};
-
-	test_spawn_prog(progname, args);
-	exit(EXIT_FAILURE);
-}
-DEFINE_TEST(kmod_tool_insert,
-	.description = "check kmod insert",
-	.config = {
-		[TC_UNAME_R] = "4.4.4",
-		[TC_ROOTFS] = TESTSUITE_ROOTFS "test-tools/insert",
-		[TC_INIT_MODULE_RETCODES] = "",
-	},
-	.modules_loaded = "mod-simple",
-	);
-
-static noreturn int kmod_tool_remove(const struct test *t)
-{
-	const char *progname = ABS_TOP_BUILDDIR "/tools/kmod";
-	const char *const args[] = {
-		progname,
-		"remove", "mod-simple",
-		NULL,
-	};
-
-	test_spawn_prog(progname, args);
-	exit(EXIT_FAILURE);
-}
-DEFINE_TEST(kmod_tool_remove,
-	.description = "check kmod remove",
-	.config = {
-		[TC_UNAME_R] = "4.4.4",
-		[TC_ROOTFS] = TESTSUITE_ROOTFS "test-tools/remove",
-		[TC_DELETE_MODULE_RETCODES] = "",
-	},
-	);
-
-TESTSUITE_MAIN();
diff --git a/tools/insert.c b/tools/insert.c
deleted file mode 100644
index 0ebcef9..0000000
--- a/tools/insert.c
+++ /dev/null
@@ -1,128 +0,0 @@
-/*
- * kmod-insert - insert a module into the kernel.
- *
- * Copyright (C) 2015 Intel Corporation. All rights reserved.
- * Copyright (C) 2011-2013  ProFUSION embedded systems
- *
- * This program is free software: you can redistribute it and/or modify
- * it under the terms of the GNU General Public License as published by
- * the Free Software Foundation, either version 2 of the License, or
- * (at your option) any later version.
- *
- * This program is distributed in the hope that it will be useful,
- * but WITHOUT ANY WARRANTY; without even the implied warranty of
- * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
- * GNU General Public License for more details.
- *
- * You should have received a copy of the GNU General Public License
- * along with this program.  If not, see <http://www.gnu.org/licenses/>.
- */
-
-#include <errno.h>
-#include <getopt.h>
-#include <stdlib.h>
-#include <string.h>
-
-#include <libkmod/libkmod.h>
-
-#include "kmod.h"
-
-static const char cmdopts_s[] = "h";
-static const struct option cmdopts[] = {
-	{"help", no_argument, 0, 'h'},
-	{ }
-};
-
-static void help(void)
-{
-	printf("Usage:\n"
-	       "\t%s insert [options] module\n"
-	       "Options:\n"
-	       "\t-h, --help        show this help\n",
-	       program_invocation_short_name);
-}
-
-static const char *mod_strerror(int err)
-{
-	switch (err) {
-	case KMOD_PROBE_APPLY_BLACKLIST:
-		return "Module is blacklisted";
-	case -EEXIST:
-		return "Module already in kernel";
-	case -ENOENT:
-		return "Unknown symbol in module or unknown parameter (see dmesg)";
-	default:
-		return strerror(-err);
-	}
-}
-
-static int do_insert(int argc, char *argv[])
-{
-	struct kmod_ctx *ctx;
-	struct kmod_list *list = NULL, *l;
-	const char *name;
-	int err, r = EXIT_SUCCESS;
-
-	for (;;) {
-		int c, idx = 0;
-		c = getopt_long(argc, argv, cmdopts_s, cmdopts, &idx);
-		if (c == -1)
-			break;
-		switch (c) {
-		case 'h':
-			help();
-			return EXIT_SUCCESS;
-		default:
-			ERR("Unexpected getopt_long() value '%c'.\n", c);
-			return EXIT_FAILURE;
-		}
-	}
-
-	if (optind >= argc) {
-		ERR("Missing module name\n");
-		return EXIT_FAILURE;
-	}
-
-	ctx = kmod_new(NULL, NULL);
-	if (!ctx) {
-		ERR("kmod_new() failed!\n");
-		return EXIT_FAILURE;
-	}
-
-	name = argv[optind];
-	err = kmod_module_new_from_lookup(ctx, name, &list);
-	if (err < 0) {
-		ERR("Could not lookup module matching '%s': %s\n", name, strerror(-err));
-		r = EXIT_FAILURE;
-		goto end;
-	}
-
-	if (list == NULL) {
-		ERR("No module matches '%s'\n", name);
-		r = EXIT_FAILURE;
-		goto end;
-	}
-
-	kmod_list_foreach(l, list) {
-		struct kmod_module *mod = kmod_module_get_module(l);
-
-		err = kmod_module_probe_insert_module(mod, KMOD_PROBE_APPLY_BLACKLIST, NULL, NULL, NULL, NULL);
-		if (err != 0) {
-			r = EXIT_FAILURE;
-			ERR("Could not insert '%s': %s\n", kmod_module_get_name(mod), mod_strerror(err));
-		}
-
-		kmod_module_unref(mod);
-	}
-
-	kmod_module_unref_list(list);
-end:
-	kmod_unref(ctx);
-	return r;
-}
-
-const struct kmod_cmd kmod_cmd_insert = {
-	.name = "insert",
-	.cmd = do_insert,
-	.help = "insert a module into the kernel",
-};
diff --git a/tools/kmod.c b/tools/kmod.c
index 55689c0..1015575 100644
--- a/tools/kmod.c
+++ b/tools/kmod.c
@@ -42,11 +42,6 @@ static const struct kmod_cmd *kmod_cmds[] = {
 	&kmod_cmd_help,
 	&kmod_cmd_list,
 	&kmod_cmd_static_nodes,
-
-#ifdef ENABLE_EXPERIMENTAL
-	&kmod_cmd_insert,
-	&kmod_cmd_remove,
-#endif
 };
 
 static const struct kmod_cmd *kmod_compat_cmds[] = {
diff --git a/tools/remove.c b/tools/remove.c
deleted file mode 100644
index 387ef0e..0000000
--- a/tools/remove.c
+++ /dev/null
@@ -1,153 +0,0 @@
-/*
- * kmod-remove - remove modules from the kernel.
- *
- * Copyright (C) 2015 Intel Corporation. All rights reserved.
- * Copyright (C) 2011-2013  ProFUSION embedded systems
- *
- * This program is free software: you can redistribute it and/or modify
- * it under the terms of the GNU General Public License as published by
- * the Free Software Foundation, either version 2 of the License, or
- * (at your option) any later version.
- *
- * This program is distributed in the hope that it will be useful,
- * but WITHOUT ANY WARRANTY; without even the implied warranty of
- * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
- * GNU General Public License for more details.
- *
- * You should have received a copy of the GNU General Public License
- * along with this program.  If not, see <http://www.gnu.org/licenses/>.
- */
-
-#include <errno.h>
-#include <getopt.h>
-#include <stdlib.h>
-#include <string.h>
-
-#include <libkmod/libkmod.h>
-
-#include "kmod.h"
-
-static const char cmdopts_s[] = "h";
-static const struct option cmdopts[] = {
-	{"help", no_argument, 0, 'h'},
-	{ }
-};
-
-static void help(void)
-{
-	printf("Usage:\n"
-	       "\t%s remove [options] module\n"
-	       "Options:\n"
-	       "\t-h, --help        show this help\n",
-	       program_invocation_short_name);
-}
-
-static int check_module_inuse(struct kmod_module *mod) {
-	struct kmod_list *holders;
-	int state, ret;
-
-	state = kmod_module_get_initstate(mod);
-
-	if (state == KMOD_MODULE_BUILTIN) {
-		ERR("Module %s is builtin.\n", kmod_module_get_name(mod));
-		return -ENOENT;
-	} else if (state < 0) {
-		ERR("Module %s is not currently loaded\n",
-				kmod_module_get_name(mod));
-		return -ENOENT;
-	}
-
-	holders = kmod_module_get_holders(mod);
-	if (holders != NULL) {
-		struct kmod_list *itr;
-
-		ERR("Module %s is in use by:", kmod_module_get_name(mod));
-
-		kmod_list_foreach(itr, holders) {
-			struct kmod_module *hm = kmod_module_get_module(itr);
-			fprintf(stderr, " %s", kmod_module_get_name(hm));
-			kmod_module_unref(hm);
-		}
-		fputc('\n', stderr);
-
-		kmod_module_unref_list(holders);
-		return -EBUSY;
-	}
-
-	ret = kmod_module_get_refcnt(mod);
-	if (ret > 0) {
-		ERR("Module %s is in use\n", kmod_module_get_name(mod));
-		return -EBUSY;
-	} else if (ret == -ENOENT) {
-		ERR("Module unloading is not supported\n");
-	}
-
-	return ret;
-}
-
-static int do_remove(int argc, char *argv[])
-{
-	struct kmod_ctx *ctx;
-	struct kmod_module *mod;
-	const char *name;
-	int err, r = EXIT_SUCCESS;
-
-	for (;;) {
-		int c, idx =0;
-		c = getopt_long(argc, argv, cmdopts_s, cmdopts, &idx);
-		if (c == -1)
-			break;
-		switch (c) {
-		case 'h':
-			help();
-			return EXIT_SUCCESS;
-
-		default:
-			ERR("Unexpected getopt_long() value '%c'.\n", c);
-			return EXIT_FAILURE;
-		}
-	}
-
-	if (optind >= argc) {
-		ERR("Missing module name\n");
-		return EXIT_FAILURE;
-	}
-
-	ctx = kmod_new(NULL, NULL);
-	if (!ctx) {
-		ERR("kmod_new() failed!\n");
-		return EXIT_FAILURE;
-	}
-
-	name = argv[optind];
-	err = kmod_module_new_from_name(ctx, name, &mod);
-	if (err < 0) {
-		ERR("Could not remove module %s: %s\n", name, strerror(-err));
-		goto end;
-	}
-
-	err = check_module_inuse(mod);
-	if (err < 0)
-		goto unref;
-
-	err = kmod_module_remove_module(mod, 0);
-	if (err < 0)
-		goto unref;
-
-unref:
-	kmod_module_unref(mod);
-
-end:
-	kmod_unref(ctx);
-	if (err < 0) {
-		r = EXIT_FAILURE;
-		ERR("Could not remove module %s: %s\n", name, strerror(-err));
-	}
-	return r;
-}
-
-const struct kmod_cmd kmod_cmd_remove = {
-	.name = "remove",
-	.cmd = do_remove,
-	.help = "remove module from kernel",
-};

---
base-commit: b29704cd448aaa455dba4e656fc0f0d3c686df3f
change-id: 20240212-rm-experimental-211fe77ebf15

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

