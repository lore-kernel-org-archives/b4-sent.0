From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:49 +0100
Subject: [PATCH 14/16] copy-firmware.sh: remove no longer reachable test -L
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-14-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=2811;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=6JIJTB67rL7JBtr8PvNUbCbQP5/EbanpD2p2MG/PEYM=;
 b=pIeGFiqXAzHE/NrB7ROZwKJL5HHeZ6/M+I077rRoB5LYCslJ5PzCQkHdXtHAEOUoLa4hccuDl
 1sNpLTuFd8gD1ybUpjXrx8J2faVPR9/HL2gCjRyUvsFsXlqZTf4m3s6
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The check_whence.py script ensures that links defined in WHENCE are not in-tree.
Since we're calling the script, we no longer need the convoluted path and
associated --prune tag.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 46 ++++++++--------------------------------------
 1 file changed, 8 insertions(+), 38 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index d1d526f43d2c71a5f1456ed6c09ed94a73a1229e..8de3774153d783d6a79443aa789f03da5f04b2c7 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -5,7 +5,6 @@
 #
 
 verbose=:
-prune=no
 # shellcheck disable=SC2209
 compress=cat
 compext=
@@ -27,11 +26,6 @@ while test $# -gt 0; do
             shift
             ;;
 
-        -P | --prune)
-            prune=yes
-            shift
-            ;;
-
         --xz)
             if test "$compext" = ".zst"; then
                 err "cannot mix XZ and ZSTD compression"
@@ -87,39 +81,15 @@ done
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
 grep -E '^Link:' WHENCE | sed -e 's/^Link: *//g;s/-> //g' | while read f d; do
-    if test -L "$f$compext"; then
-        test -f "$destdir/$f$compext" && continue
-        $verbose "copying link $f$compext"
-        install -d "$destdir/$(dirname "$f")"
-        cp -d "$f$compext" "$destdir/$f$compext"
-
-        if test "x$d" != "x"; then
-            target="$(readlink "$f")"
-
-            if test "x$target" != "x$d"; then
-                $verbose "WARNING: inconsistent symlink target: $target != $d"
-            else
-                if test "x$prune" != "xyes"; then
-                    $verbose "WARNING: unneeded symlink detected: $f"
-                else
-                    $verbose "WARNING: pruning unneeded symlink $f"
-                    rm -f "$f$compext"
-                fi
-            fi
-        else
-            $verbose "WARNING: missing target for symlink $f"
-        fi
+    directory="$destdir/$(dirname "$f")"
+    install -d "$directory"
+    target="$(cd "$directory" && realpath -m -s "$d")"
+    if test -e "$target"; then
+        $verbose "creating link $f -> $d"
+        ln -s "$d" "$destdir/$f"
     else
-        directory="$destdir/$(dirname "$f")"
-        install -d "$directory"
-        target="$(cd "$directory" && realpath -m -s "$d")"
-        if test -e "$target"; then
-            $verbose "creating link $f -> $d"
-            ln -s "$d" "$destdir/$f"
-        else
-            $verbose "creating link $f$compext -> $d$compext"
-            ln -s "$d$compext" "$destdir/$f$compext"
-        fi
+        $verbose "creating link $f$compext -> $d$compext"
+        ln -s "$d$compext" "$destdir/$f$compext"
     fi
 done
 

-- 
2.46.1

