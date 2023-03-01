From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:36 +0000
Subject: [PATCH v2 11/16] copy-firmware: remove unreachable symlink
 workarounds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-11-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=2246;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=RL0zpnggXIgb9Xy5qAr/DytoDfNyL33IoJUaYjrhiP0=;
 b=JsYz7qJtUlumDJzfc6JdPhSk7s2qB9Z/HeZZy+BQ8FsI1pv71inZSn4pBDOHPESXjfR/72BtW
 w8edI+IKqedDzEbsWVFFMVxbo6BPl/3OHpEN2X+38c3dbYKMwOF47mY
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are no symlinks in-tree and the earlier commit to check_whence.py
ensures new ones don't get added. Thus we can remove the consistency
checks and pruning code.

With this done we can also drop:
 - the --force argument for ln
 - the prune argument and related handling

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 36 +++---------------------------------
 1 file changed, 3 insertions(+), 33 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index e3f3176..0132244 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -5,7 +5,6 @@
 #
 
 verbose=:
-prune=no
 
 while test $# -gt 0; do
     case $1 in
@@ -14,11 +13,6 @@ while test $# -gt 0; do
             shift
             ;;
 
-        -P | --prune)
-            prune=yes
-            shift
-            ;;
-
         *)
             if test "x$destdir" != "x"; then
                 echo "ERROR: unknown command-line options: $@"
@@ -38,33 +32,9 @@ grep '^File:' WHENCE | sed -e's/^File: *//g' | while read f; do
 done
 
 grep -E '^Link:' WHENCE | sed -e's/^Link: *//g' -e's/-> //g' | while read f d; do
-    if test -L "$f"; then
-        test -f "$destdir/$f" && continue
-        $verbose "copying link $f"
-        install -d $destdir/$(dirname "$f")
-        cp -d "$f" $destdir/"$f"
-
-        if test "x$d" != "x"; then
-            target=`readlink "$f"`
-
-            if test "x$target" != "x$d"; then
-                $verbose "WARNING: inconsistent symlink target: $target != $d"
-            else
-                if test "x$prune" != "xyes"; then
-                    $verbose "WARNING: unneeded symlink detected: $f"
-                else
-                    $verbose "WARNING: pruning unneeded symlink $f"
-                    rm -f "$f"
-                fi
-            fi
-        else
-            $verbose "WARNING: missing target for symlink $f"
-        fi
-    else
-        $verbose "creating link $f -> $d"
-        install -d $destdir/$(dirname "$f")
-        ln -sf "$d" "$destdir/$f"
-    fi
+    $verbose "creating link $f -> $d"
+    install -d $destdir/$(dirname "$f")
+    ln -s "$d" "$destdir/$f"
 done
 
 exit 0

-- 
2.39.2

