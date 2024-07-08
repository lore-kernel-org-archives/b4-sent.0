From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:22 +0100
Subject: [PATCH kmod v2 14/17] man: modprobe: remove hard-coded
 /etc/modprobe.d references
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-14-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=1742;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=4Ot9HoVqNcls9UI9Ao/pslii9zendemKxXz6i/+PB4w=;
 b=WdqfTupU3zFd1QfOy+k8MrAzeoAjPG82PP7zhOiAxzlBJiO8iZJzrRuIqNAehC+0YOEYKRVQD
 mlqpO+x+d7nBWhyXsgY4M1iyTiDbEkDQaAxaJCP4pTcDRqc3Bvy1BwF
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Point the users to modprobe.d(5) instead.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/modprobe.8.scd | 11 +++++------
 1 file changed, 5 insertions(+), 6 deletions(-)

diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index 321fa59..30ccc21 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -21,10 +21,9 @@ modprobe - Add and remove modules from the Linux Kernel
 that for convenience, there is no difference between \_ and - in module names
 (automatic underscore conversion is performed). *modprobe* looks in the module
 directory @DISTCONFDIR@/`uname -r` for all the modules and other files, except
-for the optional configuration files in the /etc/modprobe.d directory (see
-*modprobe.d*(5)). *modprobe* will also use module options specified on the
-kernel command line in the form of <module>.<option> and blacklists in the form
-of modprobe.blacklist=<module>.
+for the optional configuration files (see *modprobe.d*(5)). *modprobe* will also
+use module options specified on the kernel command line in the form of
+<module>.<option> and blacklists in the form of modprobe.blacklist=<module>.
 
 Note that unlike in 2.4 series Linux kernels (which are not supported by this
 tool) this version of *modprobe* does not do anything to the module itself: the
@@ -56,8 +55,8 @@ database.
 	by *udev*(7).
 
 *-C* _directory_, *--config* _directory_
-	This option overrides the default configuration directory
-	(/etc/modprobe.d).
+	This option overrides the default configuration directory. See
+	*modprobe.d*(5).
 
 	This option is passed through *install* or *remove* commands to other
 	*modprobe* commands in the MODPROBE_OPTIONS environment variable.

-- 
2.45.2

