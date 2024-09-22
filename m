From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:46 +0100
Subject: [PATCH 11/16] copy-firmware.sh: warn if the destination folder is
 not empty
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-11-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=1132;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=FpS17/OqKat6PLGck0ZbQlIe9L7HVVTzBwCJ1Wi0jZE=;
 b=PxnqTIJFf142W8cXglmcY+1+Mt9+rrnfD3xJWLel8G+e8W/I+3R3Nw+zsbtOkq3s+1g9nVZ83
 h0G+yPofh65CgYyulC9sM1Yg7sXpmh8cmj/VLut5C9Qf3MZmwZj6C90
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the user provides their existing /usr/lib/firmware/ there is a high chance
we'll overwrite existing files. That may or may not be what they wanted.

Throw a warning about it.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index f59d8403ab3f4c6928f6976069c134dfb98b1246..dc959cbad3be3e79a1174afd0ff68b8d6c0567a5 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -15,6 +15,10 @@ err() {
     exit 1
 }
 
+warn() {
+    echo "WARNING: $*"
+}
+
 while test $# -gt 0; do
     case $1 in
         -v | --verbose)
@@ -62,6 +66,10 @@ if test -z "$destdir"; then
     err "destination directory was not specified"
 fi
 
+if test -d "$destdir"; then
+    find "$destdir" -type d -empty >/dev/null && warn "destination folder is not empty."
+fi
+
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
 grep -E '^(RawFile|File):' WHENCE | sed -E -e 's/^(RawFile|File): */\1 /;s/"//g' | while read k f; do
     test -f "$f" || continue

-- 
2.46.1

