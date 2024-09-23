From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:40 +0100
Subject: [PATCH v2 12/16] copy-firmware.sh: warn if the destination folder
 is not empty
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-12-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1186;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=WJ8am6j5YgaMLhScDdjum39RpN5ff2d6IJBAx7vkpJ8=;
 b=fj4I+ZPKlTFqwcBPf4pOcoq28FPw3TIk28jT9H+xDSzqhciym2k8c8zYYmCgx82WCkIGvyxnI
 Jx9lxHC8LqnALMQt4YWnLLRTW3D4HMR+4Y9Mow5euKBqgd7AbNOSXfA
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the user provides an existing non-empty folder (their /usr/lib/firmware/ or otherwise)
there is a high chance we'll silently overwrite existing files. That may or may not be what
they wanted, so throw a warning so highlight that.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 610c8b65b2b3bdb9f723da3656112ac121e51c84..12b97ae32f953c96a1c7612ccd14b1991a8687bf 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -16,6 +16,10 @@ err() {
     exit 1
 }
 
+warn() {
+    echo "WARNING: $*"
+}
+
 while test $# -gt 0; do
     case $1 in
         -v | --verbose)
@@ -63,6 +67,10 @@ if test -z "$destdir"; then
     err "destination directory was not specified"
 fi
 
+if test -d "$destdir"; then
+    find "$destdir" -type d -empty >/dev/null || warn "destination folder is not empty."
+fi
+
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
 grep -E '^(RawFile|File):' WHENCE | sed -E -e 's/^(RawFile|File): */\1 /;s/"//g' | while read k f; do
     test -f "$f" || continue

-- 
2.46.1

