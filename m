From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:44 +0100
Subject: [PATCH 09/16] copy-firmware.sh: fixup indentation, consistently
 use test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-9-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=1031;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=hy8iLu3uE3VAsqwRVOWbyYNgW2YyaPxQ9G4aBqD1ybc=;
 b=6MyzOxYKcppAsry/AcXMLFGPKVGpSJw9/iFLSyZSoaiDKx5HWl3joi0ZnOzMX6AbmDkipx2Jq
 dgPquYhZoqPA9hmy4n7ZZfHbH+GvaUELQWnW+PKNWnuCm7AUqCvvu5X
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 21ed20d5886fe71588b923914265f992cf5c29b0..e46bb9926f86a813bc76f1da1604c1b7a4980848 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -56,9 +56,9 @@ while test $# -gt 0; do
     esac
 done
 
-if [ -z "$destdir" ]; then
-	echo "ERROR: destination directory was not specified"
-	exit 1
+if test -z "$destdir"; then
+    echo "ERROR: destination directory was not specified"
+    exit 1
 fi
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
@@ -114,9 +114,9 @@ done
 
 # Verify no broken symlinks
 if test "$(find "$destdir" -xtype l | wc -l)" -ne 0 ; then
-        echo "ERROR: Broken symlinks found:"
-        find "$destdir" -xtype l
-        exit 1
+    echo "ERROR: Broken symlinks found:"
+    find "$destdir" -xtype l
+    exit 1
 fi
 
 exit 0

-- 
2.46.1

