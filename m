From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:07 +0100
Subject: [PATCH kmod 07/20] man: misc punctuation fixes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-7-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=2203;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=O4mu2lAXXNBJUE43RRJdu3Q2copKlkDtEMzQhh1mrMU=;
 b=bf27jvIz4dFXaGJTtn3WmEq7Zgtaa13pPfUuJXq51d7ys1Hhj/hkNjTTUpgK7iFsvLOXn/XBc
 2L+zcwx2TYDBXrH6R9KTuA0wVDkBXsY5J2W7afxNZkQhqB+ASDSavUF
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some commas and a full stop was missing ;-)

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/depmod.d.5.scd | 2 +-
 man/kmod.8.scd     | 4 ++--
 man/lsmod.8.scd    | 2 +-
 man/modprobe.8.scd | 2 +-
 man/rmmod.8.scd    | 2 +-
 5 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/man/depmod.d.5.scd b/man/depmod.d.5.scd
index 4e05b93..9cf99d5 100644
--- a/man/depmod.d.5.scd
+++ b/man/depmod.d.5.scd
@@ -73,7 +73,7 @@ exclude _excludedir_
 	This specifies the trailing directories that will be excluded during the
 	search for kernel modules.
 
-	The _excludedir_ is the trailing directory to exclude
+	The _excludedir_ is the trailing directory to exclude.
 
 # COPYRIGHT
 
diff --git a/man/kmod.8.scd b/man/kmod.8.scd
index 7bef863..2007a2d 100644
--- a/man/kmod.8.scd
+++ b/man/kmod.8.scd
@@ -15,10 +15,10 @@ Linux Kernel modules. Most users will only run it using its other names.
 
 # OPTIONS
 
-*-V --version*
+*-V*, *--version*
 	Show the program version and exit.
 
-*-h --help*
+*-h*, *--help*
 	Show the help message.
 
 # COMMANDS
diff --git a/man/lsmod.8.scd b/man/lsmod.8.scd
index 7195cba..eb2f2e8 100644
--- a/man/lsmod.8.scd
+++ b/man/lsmod.8.scd
@@ -19,7 +19,7 @@ Maintained by Jon Masters and others.
 
 # SEE ALSO
 
-*insmod*(8), *modprobe*(8), *modinfo*(8) *depmod*(8)
+*insmod*(8), *modprobe*(8), *modinfo*(8), *depmod*(8)
 
 # AUTHORS
 
diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index aac3a74..f4ce0be 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -202,7 +202,7 @@ Maintained by Jon Masters and others.
 
 # SEE ALSO
 
-*modprobe.d*(5), *insmod*(8), *rmmod*(8), *lsmod*(8), *modinfo*(8) *depmod*(8)
+*modprobe.d*(5), *insmod*(8), *rmmod*(8), *lsmod*(8), *modinfo*(8), *depmod*(8)
 
 # AUTHORS
 
diff --git a/man/rmmod.8.scd b/man/rmmod.8.scd
index 7813448..e1f656f 100644
--- a/man/rmmod.8.scd
+++ b/man/rmmod.8.scd
@@ -39,7 +39,7 @@ Maintained by Jon Masters and others.
 
 # SEE ALSO
 
-*modprobe*(8), *insmod*(8), *lsmod*(8), *modinfo*(8) *depmod*(8)
+*modprobe*(8), *insmod*(8), *lsmod*(8), *modinfo*(8), *depmod*(8)
 
 # AUTHORS
 

-- 
2.45.0

