From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:37 +0100
Subject: [PATCH v2 09/16] copy-firmware.sh: reset and consistently handle
 destdir
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-9-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1306;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=UVkupopnR361tFh5PRnEldcqkJUyBqzhIYg5b+Y+tiY=;
 b=bEjMLniJQxAyhV0QjYZtRm9RDAN33D33wNA85AWF5npQ4+beAbqcDXoCpg4hb8H6hGprsM9ly
 hhKmdooPRi3DfsXk7pm+aOk502NjW3Hk6RipRXlfVoUGyOjgad0/czj
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently we don't reset/override the destdir variable, so we end up inheriting
whatever the caller's environment has for it. While it may work, it's not
particularly consistent (be that within the script or other tools) nor is it
obvious.

While in here, ensure we handle the variable with test -z/-n instead of varying
other constructs.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 21ed20d5886fe71588b923914265f992cf5c29b0..65a1b39b93293d1f876ea0cd2991e811247e9ecd 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -9,6 +9,7 @@ prune=no
 # shellcheck disable=SC2209
 compress=cat
 compext=
+destdir=
 
 while test $# -gt 0; do
     case $1 in
@@ -45,7 +46,7 @@ while test $# -gt 0; do
             ;;
 
         *)
-            if test "x$destdir" != "x"; then
+            if test -n "$destdir"; then
                 echo "ERROR: unknown command-line options: $*"
                 exit 1
             fi
@@ -56,7 +57,7 @@ while test $# -gt 0; do
     esac
 done
 
-if [ -z "$destdir" ]; then
+if test -z "$destdir"; then
 	echo "ERROR: destination directory was not specified"
 	exit 1
 fi

-- 
2.46.1

