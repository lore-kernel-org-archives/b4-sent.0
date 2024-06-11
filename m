From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:08 +0100
Subject: [PATCH kmod 08/20] man: some options take an argument, mention
 that
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-8-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=3010;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=ujIDwGUQV0FOmUpTbz7QEpgmiqJ/HE3dkWV2TNVcd/Y=;
 b=ZxbtX+lbUqtIULQ/Cq8wTcj19J34F/PJt1NxsI/SqhMNsFbSIhC5lAhMLEwfawBX4TCn8LLe4
 RcXN2fRQ3dvBudkctvV5FOgY5wdW2EQut1CaiE9CTq3m5+8ElEOH8ZS
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For example modinfo -F requires the field name, although the
documentation was missing the "field".

Similarly modprobe has omissions, so let's fix those as well.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
There are two different styles across the man pages:
 -s, --short foo
 -s foo, --short foo

A proposal to resolve these comes with a later patch in this series.
---
 man/depmod.8.scd   | 2 +-
 man/modinfo.8.scd  | 4 ++--
 man/modprobe.8.scd | 6 +++---
 3 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/man/depmod.8.scd b/man/depmod.8.scd
index 80cc48d..7a2e84b 100644
--- a/man/depmod.8.scd
+++ b/man/depmod.8.scd
@@ -72,7 +72,7 @@ rather than the current kernel version (as returned by *uname -r*).
 	assumption can break especially when additionally updated third party
 	drivers are not correctly installed or were built incorrectly.
 
-*-E*, *--symvers*
+*-E*, *--symvers* _Module.symvers_
 	When combined with the *-e* option, this reports any symbol versions
 	supplied by modules that do not match with the symbol versions provided
 	by the kernel in its _Module.symvers_. This option is mutually
diff --git a/man/modinfo.8.scd b/man/modinfo.8.scd
index 75267bc..9545257 100644
--- a/man/modinfo.8.scd
+++ b/man/modinfo.8.scd
@@ -31,8 +31,8 @@ architecture.
 *-V*, *--version*
 	Print the *modinfo* version.
 
-*-F*, *--field*
-	Only print this field value, one per line. This is most useful for
+*-F* _field_, *--field* _field_
+	Only print this _field_ value, one per line. This is most useful for
 	scripts. Field names are case-insensitive. Common fields (which may not
 	be in every module) include author, description, license, parm, depends,
 	and alias. There are often multiple parm, alias and depends fields. The
diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index f4ce0be..9594798 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -55,7 +55,7 @@ database.
 	configuration files (if any) to module names as well. It is usually used
 	by *udev*(7).
 
-*-C*, *--config*
+*-C* _directory_, *--config* _directory_
 	This option overrides the default configuration directory
 	(/etc/modprobe.d).
 
@@ -151,14 +151,14 @@ database.
 	require it. Your distribution kernel may not have been built to support
 	removal of modules at all.
 
-*-w*, *--wait=*TIMEOUT_MSEC
+*-w* _TIMEOUT_MSEC_, *--wait* _TIMEOUT_MSEC_
 	This option causes *modprobe -r *to continue trying to remove a module
 	if it fails due to the module being busy, i.e. its refcount is not 0 at
 	the time the call is made. Modprobe tries to remove the module with an
 	incremental sleep time between each tentative up until the maximum wait
 	time in milliseconds passed in this option.
 
-*-S*, *--set-version*
+*-S* _version_, *--set-version* _version_
 	Set the kernel version, rather than using *uname*(2) to decide on the
 	kernel version (which dictates where to find the modules).
 

-- 
2.45.0

