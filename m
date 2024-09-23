From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:31 +0100
Subject: [PATCH v2 03/16] check_whence.py: LC_ALL=C sort -u the filelist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-3-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1536;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=vmlCVRJbxEfo1wLPvzNCwHFHCqtETXk1ay13BZyXJX0=;
 b=5eozgF/r2TDlM3mTVAQi7Pb1pH6pg5Z+8UIsJAEK6H4TUHpim6rSGOSjrZjxnY9WiSx5T2C8V
 ojxeJ9IP+zeARBuQQMqRdz1+zseXhsZo+xmybn70EA0f28BkGXcLmFL
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sort the file list, so it's easier to manage.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 check_whence.py | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/check_whence.py b/check_whence.py
index d7742f1ed951acab6efc89916c7f6621ba56881b..dbbb68f7ab51b8db52c1d2334a6d4d20962bbef8 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -73,23 +73,23 @@ def main():
     whence_links = list(zip(*links_list))[0]
     known_files = set(name for name in whence_list if not name.endswith("/")) | set(
         [
-            ".gitignore",
             ".codespell.cfg",
+            ".gitignore",
             ".gitlab-ci.yml",
             ".pre-commit-config.yaml",
-            "build_packages.py",
-            "check_whence.py",
-            "configure",
+            "Dockerfile",
             "Makefile",
             "README.md",
-            "copy-firmware.sh",
             "WHENCE",
-            "Dockerfile",
+            "build_packages.py",
+            "check_whence.py",
+            "configure",
+            "contrib/process_linux_firmware.py",
             "contrib/templates/debian.changelog",
             "contrib/templates/debian.control",
             "contrib/templates/debian.copyright",
             "contrib/templates/rpm.spec",
-            "contrib/process_linux_firmware.py",
+            "copy-firmware.sh",
         ]
     )
     known_prefixes = set(name for name in whence_list if name.endswith("/"))

-- 
2.46.1

