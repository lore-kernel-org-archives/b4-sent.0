From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:40 +0100
Subject: [PATCH 05/16] editorconfig: add initial config file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-5-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=1450;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=QOHlBI2CZfjGlafZozbvBaFvhuBf7UyiCXDnO8wkb8g=;
 b=MhqZ0jcrNFDzohKn1O1plhr9Z5LylZ2y28Ah98aG/yI/WAhALgByrm1lAZCgP6ADAv55JRVDA
 YHM6ld9vMPJDW6xaoZE9ISfKZp58ckY4mde7ZoJw2eRMHFQARa6KPSW
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's a simple format supported by practically every supported platform or
program out there.

Add an initial configuration file, so we don't get notable style variations like
the ones we have in-tree.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 .editorconfig   | 21 +++++++++++++++++++++
 check_whence.py |  1 +
 2 files changed, 22 insertions(+)

diff --git a/.editorconfig b/.editorconfig
new file mode 100644
index 0000000000000000000000000000000000000000..2da3ba9694341dd4f1f5db9c3ad946ac96c5bdac
--- /dev/null
+++ b/.editorconfig
@@ -0,0 +1,21 @@
+# To use this config on you editor, follow the instructions at:
+# http://editorconfig.org
+
+root = true
+
+[*]
+charset = utf-8
+insert_final_newline = true
+tab_width = 8
+max_line_length = 80
+
+[Makefile]
+indent_style = tab
+
+[*.{sh,py}]
+indent_style = space
+indent_size = 4
+
+[*.{yml,yaml}]
+indent_style = space
+indent_size = 2
diff --git a/check_whence.py b/check_whence.py
index 64dc133551a68aeb24dbf7f02f617ea3913477b2..afe97a76cf5ed609117d07387a19c2092fa00c6c 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -74,6 +74,7 @@ def main():
     known_files = set(name for name in whence_list if not name.endswith("/")) | set(
         [
             ".codespell.cfg",
+            ".editorconfig",
             ".gitignore",
             ".gitlab-ci.yml",
             ".pre-commit-config.yaml",

-- 
2.46.1

