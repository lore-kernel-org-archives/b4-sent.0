From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:11 +0100
Subject: [PATCH kmod 11/20] man: depmod.d: document the config file order
 handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-11-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=2376;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=ddft5epJfJ7Syzl58yhh/w8V7UnnoNgSvHNj/DUisJQ=;
 b=2dLX7d3FGKruy7BchZS8mjaY+lunw72uun71hvwSaKKPWSwhajtTZ2eZSFuBdbc2k7WAF3EDn
 7qO58RkwByfA0Qcim5G5MOx5n+78FTx2Eg4fpmZecalWVjCCKUZy6VG
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The depmod.d configuration order/handling aligns with existing tools
such as sysctl.d, even though there is no mention in the manual.

Reorder the list in SYNOPSIS and add a bit of verbiage describing things.

Section is copied^Winspired by sysctl.d(5) ;-)

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/Makefile.am    |  1 +
 man/depmod.d.5.scd | 22 ++++++++++++++++++----
 2 files changed, 19 insertions(+), 4 deletions(-)

diff --git a/man/Makefile.am b/man/Makefile.am
index 25135e9..181f619 100644
--- a/man/Makefile.am
+++ b/man/Makefile.am
@@ -15,6 +15,7 @@ CLEANFILES = $(dist_man_MANS)
 
 define generate_manpage
 	$(AM_V_SCDOC)cat $< | \
+	sed -e 's|@SYSCONFDIR@|$(sysconfdir)|g' | \
 	sed -e 's|@DISTCONFDIR@|$(distconfdir)|g' | \
 	sed -e 's|@MODULE_DIRECTORY@|$(module_directory)|g' | \
 	$(SCDOC) > $@
diff --git a/man/depmod.d.5.scd b/man/depmod.d.5.scd
index 9cf99d5..9ee35e8 100644
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
 
@@ -29,6 +29,20 @@ lines and lines starting with '#' ignored (useful for adding comments). A '\\'
 at the end of a line causes it to continue on the next line, which makes the
 files a bit neater.
 
+# CONFIGURATION DIRECTORIES AND PRECEDENCE
+
+Configuration files are read from directories in @SYSCONFDIR@/, /run/,
+/usr/local/lib/, @DISTCONFDIR@/, and /lib/ in order of precedence, as listed in
+the SYNOPSIS section above. Files must have the ".conf" extension. Files in
+@SYSCONFDIR@/ override files with the same name in /run/, /usr/local/lib/,
+@DISTCONFDIR@/, and /lib/. Files in /run/ override files with the same name
+under /usr/, @DISTCONFDIR@/ and /lib/.
+
+All configuration files are sorted by their filename in lexicographic order,
+regardless of which of the directories they reside in. If multiple files specify
+the same option, the entry in the file with the lexicographically latest name
+will take precedence.
+
 # COMMANDS
 
 search _subdirectory..._

-- 
2.45.0

