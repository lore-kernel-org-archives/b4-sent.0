From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:15 +0100
Subject: [PATCH kmod v2 07/17] man: depmod.d: document the config file
 order handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-7-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=2297;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=PAvjWYoZgIb8yJI4fuG/sOZcmrnJqbKRc4WY3D6CsBc=;
 b=lchggi4LFvuHfqfR6Aj4s+QV7DRKbs1on1OAfBuelfteWZdhTlk0EPEBYO3waO2D/tZHeCgqI
 jiyso6P6YmHDamT8tj7pVnbjz8vO4EfhkwRsSo3odeWqE1WSTk8IU81
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The depmod.d configuration order/handling aligns with existing tools
such as sysctl.d, even though there is no mention in the manual.

Reorder the list in SYNOPSIS and add a bit of verbiage describing things.

Section is inspired by sysctl.d(5) and sysctl(8).

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
v2: Reword as per Lucas' suggestion.
---
 man/Makefile.am    |  1 +
 man/depmod.d.5.scd | 20 ++++++++++++++++----
 2 files changed, 17 insertions(+), 4 deletions(-)

diff --git a/man/Makefile.am b/man/Makefile.am
index 39a0015..6356d87 100644
--- a/man/Makefile.am
+++ b/man/Makefile.am
@@ -15,6 +15,7 @@ CLEANFILES = $(filter-out $(MAN_STUB), $(dist_man_MANS))
 
 define generate_manpage
 	$(AM_V_SCDOC)cat $< | \
+	sed -e 's|@SYSCONFDIR@|$(sysconfdir)|g' | \
 	sed -e 's|@DISTCONFDIR@|$(distconfdir)|g' | \
 	sed -e 's|@MODULE_DIRECTORY@|$(module_directory)|g' | \
 	$(SCDOC) > $@
diff --git a/man/depmod.d.5.scd b/man/depmod.d.5.scd
index 9cf99d5..bd1291b 100644
--- a/man/depmod.d.5.scd
+++ b/man/depmod.d.5.scd
@@ -6,15 +6,15 @@ depmod.d - Configuration directory for depmod
 
 # SYNOPSIS
 
-/lib/depmod.d/\*.conf
+@SYSCONFDIR@/depmod.d/\*.conf
 
-@DISTCONFDIR@/depmod.d/\*.conf
+/run/depmod.d/\*.conf
 
 /usr/local/lib/depmod.d/\*.conf
 
-/run/depmod.d/\*.conf
+@DISTCONFDIR@/depmod.d/\*.conf
 
-/etc/depmod.d/\*.conf
+/lib/depmod.d/\*.conf
 
 # DESCRIPTION
 
@@ -29,6 +29,18 @@ lines and lines starting with '#' ignored (useful for adding comments). A '\\'
 at the end of a line causes it to continue on the next line, which makes the
 files a bit neater.
 
+# CONFIGURATION DIRECTORIES AND PRECEDENCE
+
+Configuration files are read from directories in listed in SYNOPSYS in that
+order of precedence. Once a file of a given filename is loaded, any file of the
+same name in subsequent directories is ignored.
+
+All configuration files are sorted in lexicographic order, regardless of the
+directory they reside in. Configuration files can either be completely replaced
+(by having a new configuration file with the same name in a directory of higher
+priority) or partially replaced (by having a configuration file that is ordered
+later).
+
 # COMMANDS
 
 search _subdirectory..._

-- 
2.45.2

