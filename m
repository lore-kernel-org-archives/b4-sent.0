From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:45 +0100
Subject: [PATCH 10/16] copy-firmware.sh: add err() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-10-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=2187;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=EJ089N84vDRdbLAQhH8BQRLgcvQ7Br4Tp+pP9zwM87c=;
 b=dSQz5WRCq2SUhhkFcWy/Xb4ihMv9S9+y7oeySXT/f8oBL0rDX3MH1nIQ+EYKgYyK9IeHqaOHw
 FV3atA8aRcxA5H0B2yMMGAAYH2pT6PvLYVL+PMMQSZcMo3QLXoXCm5N
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 21 ++++++++++-----------
 1 file changed, 10 insertions(+), 11 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index e46bb9926f86a813bc76f1da1604c1b7a4980848..f59d8403ab3f4c6928f6976069c134dfb98b1246 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -10,6 +10,11 @@ prune=no
 compress=cat
 compext=
 
+err() {
+    echo "ERROR: $*"
+    exit 1
+}
+
 while test $# -gt 0; do
     case $1 in
         -v | --verbose)
@@ -25,8 +30,7 @@ while test $# -gt 0; do
 
         --xz)
             if test "$compext" = ".zst"; then
-                echo "ERROR: cannot mix XZ and ZSTD compression"
-                exit 1
+                err "cannot mix XZ and ZSTD compression"
             fi
             compress="xz --compress --quiet --stdout --check=crc32"
             compext=".xz"
@@ -35,8 +39,7 @@ while test $# -gt 0; do
 
         --zstd)
             if test "$compext" = ".xz"; then
-                echo "ERROR: cannot mix XZ and ZSTD compression"
-                exit 1
+                err "cannot mix XZ and ZSTD compression"
             fi
             # shellcheck disable=SC2209
             compress="zstd --compress --quiet --stdout"
@@ -46,8 +49,7 @@ while test $# -gt 0; do
 
         *)
             if test "x$destdir" != "x"; then
-                echo "ERROR: unknown command-line options: $*"
-                exit 1
+                err "unknown command-line options: $*"
             fi
 
             destdir="$1"
@@ -57,8 +59,7 @@ while test $# -gt 0; do
 done
 
 if test -z "$destdir"; then
-    echo "ERROR: destination directory was not specified"
-    exit 1
+    err "destination directory was not specified"
 fi
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
@@ -114,9 +115,7 @@ done
 
 # Verify no broken symlinks
 if test "$(find "$destdir" -xtype l | wc -l)" -ne 0 ; then
-    echo "ERROR: Broken symlinks found:"
-    find "$destdir" -xtype l
-    exit 1
+    err "Broken symlinks found:\n$(find "$destdir" -xtype l)"
 fi
 
 exit 0

-- 
2.46.1

