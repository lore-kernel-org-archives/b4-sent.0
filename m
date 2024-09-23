From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:38 +0100
Subject: [PATCH v2 10/16] copy-firmware.sh: fix indentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-10-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=989;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=+r5WUVjJ+XuyJapH4H1mtRiqcqINneESKVagNaYTEaA=;
 b=wLzMK8FyFj3WDGVvkP9C0C/IAStNUSCkflVnArIVYOnS6ur8ajLONbBGDq4ybuCruKtt+UHQe
 fp/7HbAaP5YD/zheVwAsB5V3q/XC7W3gPF1QyGu7GXbxpRV1xaqbes0
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 65a1b39b93293d1f876ea0cd2991e811247e9ecd..f83b4775cd2ce873b0f6fa76c4d61df3bcf1b5df 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -58,8 +58,8 @@ while test $# -gt 0; do
 done
 
 if test -z "$destdir"; then
-	echo "ERROR: destination directory was not specified"
-	exit 1
+    echo "ERROR: destination directory was not specified"
+    exit 1
 fi
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
@@ -115,9 +115,9 @@ done
 
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

