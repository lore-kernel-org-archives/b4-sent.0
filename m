From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:44 +0100
Subject: [PATCH v2 16/16] copy-firmware.sh: rename variables in symlink
 hanlding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-16-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1507;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Z5/WxfoLZqkgFB6L8ZRR1GpWggGK55LAePYnh7qPIeY=;
 b=L4qfEt4ryL24H4JiUxSBVwDZXE5UXowZ37y/px22T0tCJOQaRWO6lsqIE4nE/xuIFEMj/giMg
 gRVk2FcgK9ZBNc9sdZtnemJQA948qEpMHatETovmLMzn9Mp6hZsm1TZ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently we use f(ile) and d(irectory), over the more common ones t(arget) and
l(ink). Rename things appropriately.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 57d43cd004231e34c5349ccff90072b26af63093..e2d2945c926872e55800c2a637574e8234908a5d 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -81,16 +81,16 @@ grep -E '^(RawFile|File):' WHENCE | sed -E -e 's/^(RawFile|File): */\1 /;s/"//g'
 done
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
-grep -E '^Link:' WHENCE | sed -e 's/^Link: *//g;s/-> //g' | while read f d; do
-    directory="$destdir/$(dirname "$f")"
+grep -E '^Link:' WHENCE | sed -e 's/^Link: *//g;s/-> //g' | while read l t; do
+    directory="$destdir/$(dirname "$l")"
     install -d "$directory"
-    target="$(cd "$directory" && realpath -m -s "$d")"
+    target="$(cd "$directory" && realpath -m -s "$t")"
     if test -e "$target"; then
-        $verbose "creating link $f -> $d"
-        ln -s "$d" "$destdir/$f"
+        $verbose "creating link $l -> $t"
+        ln -s "$t" "$destdir/$l"
     else
-        $verbose "creating link $f$compext -> $d$compext"
-        ln -s "$d$compext" "$destdir/$f$compext"
+        $verbose "creating link $l$compext -> $t$compext"
+        ln -s "$t$compext" "$destdir/$l$compext"
     fi
 done
 

-- 
2.46.1

