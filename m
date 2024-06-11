From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:15 +0100
Subject: [PATCH kmod 15/20] man: modprobe.d: document the config file order
 handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-15-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=3167;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=XFaN2I0qhiijgB9eQQCG3OztiO1Rtxam4YIAmEXjq3A=;
 b=upsYJL2THvIlGkkZf02/JrNlyuuNBMWLAOjYhRstRFs9ijc4yAjRIQ81MLJTomqzpCCVaU5y5
 GoEk2/KlcHhA3wSZQ5rdmzI2WyGnTBe260h0PMTkc8YnkJx6LjFnx3t
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The modprobe.d configuration order/handling aligns with existing tools
such as sysctl.d, even though there is no mention in the manual.

Reorder the list in SYNOPSIS and add a bit of verbiage describing things.

Section is copied^Winspired by sysctl.d(5) ;-)

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
The documentation says ".conf", yet the code in libkmod-config.c also
permits for .alias files. I haven't dug through history - is that
intentional? Should we document why - in-code or manual page?
---
 man/modprobe.d.5.scd | 31 ++++++++++++++++++++++---------
 1 file changed, 22 insertions(+), 9 deletions(-)

diff --git a/man/modprobe.d.5.scd b/man/modprobe.d.5.scd
index 2907175..2f78dd7 100644
--- a/man/modprobe.d.5.scd
+++ b/man/modprobe.d.5.scd
@@ -6,25 +6,24 @@ modprobe.d - Configuration directory for modprobe
 
 # SYNOPSIS
 
-/lib/modprobe.d/\*.conf
+@SYSCONFDIR@/modprobe.d/\*.conf
 
-@DISTCONFDIR@/modprobe.d/\*.conf
+/run/modprobe.d/\*.conf
 
 /usr/local/lib/modprobe.d/\*.conf
 
-/run/modprobe.d/\*.conf
+@DISTCONFDIR@/modprobe.d/\*.conf
 
-/etc/modprobe.d/\*.conf
+/lib/modprobe.d/\*.conf
 
 # DESCRIPTION
 
 Because the *modprobe* command can add or remove more than one module, due to
 modules having dependencies, we need a method of specifying what options are to
-be used with those modules. All files underneath the /etc/modprobe.d directory
-which end with the .conf extension specify those options as required. They can
-also be used to create convenient aliases: alternate names for a module, or they
-can override the normal *modprobe* behavior altogether for those with special
-requirements (such as inserting more than one module).
+be used with those modules. One can also use them to create convenient aliases:
+alternate names for a module, or they can override the normal *modprobe*
+behavior altogether for those with special requirements (such as inserting more
+than one module).
 
 Note that module and alias names (like other module names) can have - or \_ in
 them: both are interchangeable throughout all the module commands as underscore
@@ -35,6 +34,20 @@ lines and lines starting with '#' ignored (useful for adding comments). A '\\'
 at the end of a line causes it to continue on the next line, which makes the
 file a bit neater.
 
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
 
 alias _wildcard_ _modulename_

-- 
2.45.0

