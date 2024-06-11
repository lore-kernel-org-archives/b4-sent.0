From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:18 +0100
Subject: [PATCH kmod 18/20] man: modprobe: remove hard-coded
 /etc/modprobe.d references
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-18-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=1742;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=44XT6FvMPVBapnpGuwguSZLd6W0s8UiXzlVT/+SUTHo=;
 b=pxYCJRcz2FhZxKaQHKPkGqOXYnDpaxyZtS7dXF86jQEGNzjuy31kmjSr2f7QeNJiUJzkKm41E
 qHdtc2GLE7yAdm7hHs0BUcqdc+gKDMnoRQe5g64kYMDFhHITYZtbHoE
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
index b47908b..8354765 100644
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
2.45.0

