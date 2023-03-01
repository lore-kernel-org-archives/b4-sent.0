From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:40 +0000
Subject: [PATCH v2 15/16] copy-firmware: silence the last shellcheck
 warnings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-15-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=1200;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Zs82VHfS/5xk78pKSX1uPibhzfoBqL1Wh86aqKB5sOk=;
 b=1kN95Ld5DiIRLw8UpiUvFAVQzu9mQtyEZmGtJVmzYDwkJZO+Z1Ar5sY+ftQMlCXX/r2X3ITr6
 8vwR1tLkeyWC4jj1ecixTXPkCLRBuzmfWGh5S/nqVoOYUfFmCznZqax
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 5a5e1a8..a52b847 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -9,13 +9,14 @@ verbose=:
 while test $# -gt 0; do
     case $1 in
         -v | --verbose)
+            # shellcheck disable=SC2209
             verbose=echo
             shift
             ;;
 
         *)
             if test "x$destdir" != "x"; then
-                echo "ERROR: unknown command-line options: $@"
+                echo "ERROR: unknown command-line options: $*"
                 exit 1
             fi
 
@@ -25,12 +26,14 @@ while test $# -gt 0; do
     esac
 done
 
+# shellcheck disable=SC2162
 grep '^File:' WHENCE | sed -e 's/^File: *//g' | while read f; do
     $verbose "copying file $f"
     install -d "$destdir/$(dirname "$f")"
     cp "$f" "$destdir/$f"
 done
 
+# shellcheck disable=SC2162
 grep -E '^Link:' WHENCE | sed -e 's/^Link: *//g;s/-> //g' | while read f d; do
     $verbose "creating link $f -> $d"
     install -d "$destdir/$(dirname "$f")"

-- 
2.39.2

