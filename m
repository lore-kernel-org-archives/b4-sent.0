From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:39 +0100
Subject: [PATCH v2 11/16] copy-firmware.sh: add err() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-11-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=2185;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=hpFql0wR1inuIFybmeadySKAL2U9S4WFEHSFv4xsKF0=;
 b=bBaaE+3m+ocMWXJxFS7ZqN3Zgqd8piVW7ex7fLWhvucAyGIMTPKV94fyZ5oTKtYIlditSNwk2
 5Ty/M38echHDAVkFI1PKdeHMdT40PHUjnywc8dGuHhmuhcLd8Xt/ova
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 21 ++++++++++-----------
 1 file changed, 10 insertions(+), 11 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index f83b4775cd2ce873b0f6fa76c4d61df3bcf1b5df..610c8b65b2b3bdb9f723da3656112ac121e51c84 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -11,6 +11,11 @@ compress=cat
 compext=
 destdir=
 
+err() {
+    echo -e "ERROR: $*"
+    exit 1
+}
+
 while test $# -gt 0; do
     case $1 in
         -v | --verbose)
@@ -26,8 +31,7 @@ while test $# -gt 0; do
 
         --xz)
             if test "$compext" = ".zst"; then
-                echo "ERROR: cannot mix XZ and ZSTD compression"
-                exit 1
+                err "cannot mix XZ and ZSTD compression"
             fi
             compress="xz --compress --quiet --stdout --check=crc32"
             compext=".xz"
@@ -36,8 +40,7 @@ while test $# -gt 0; do
 
         --zstd)
             if test "$compext" = ".xz"; then
-                echo "ERROR: cannot mix XZ and ZSTD compression"
-                exit 1
+                err "cannot mix XZ and ZSTD compression"
             fi
             # shellcheck disable=SC2209
             compress="zstd --compress --quiet --stdout"
@@ -47,8 +50,7 @@ while test $# -gt 0; do
 
         *)
             if test -n "$destdir"; then
-                echo "ERROR: unknown command-line options: $*"
-                exit 1
+                err "unknown command-line options: $*"
             fi
 
             destdir="$1"
@@ -58,8 +60,7 @@ while test $# -gt 0; do
 done
 
 if test -z "$destdir"; then
-    echo "ERROR: destination directory was not specified"
-    exit 1
+    err "destination directory was not specified"
 fi
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
@@ -115,9 +116,7 @@ done
 
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

