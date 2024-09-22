From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:38 +0100
Subject: [PATCH 03/16] check_whence.py: LC_ALL=C sort -u the filelist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-3-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=1563;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=VnYRe1j4F10qAfma3aVuEsez52eYzjwTz1lMCI/GlrI=;
 b=dgXxBTVSE5wmv4eFkh0sOKNJT49zKW1nIOFYbFbGUFjewq6fN4pXzuXOAwsrCEnPA9tgtJjSY
 Nlbt0m2sU/cApIHiqUG348Dsq8FsjDtWFnyQYB9uX6aKlpiONzbh3OV
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sort the file list, to provide some sanity and make it easier to manage.

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

