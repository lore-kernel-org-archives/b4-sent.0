From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:33 +0100
Subject: [PATCH v2 05/16] editorconfig: add initial config file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-5-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1431;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=7nXGnViA4hCUNMSGxxwriz54l/lbiqgNNrjlTL3v8V0=;
 b=a4DDBPmUlpNsZmNU5/Y5M/X3lxAiKdkajwVtMvESVZtaT3puT/61x8xtxGckON2NH1XB3EXkr
 lAvgEG4Hu23CfAsk+T3X5ja4GPdlGwP0PL1XLoFjGvMIpG5QZwPm9Pe
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's a simple format handled by practically every supported platform or program
out there.

Add an initial configuration file, so we reduce the style variation of the files
in-tree.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 .editorconfig   | 21 +++++++++++++++++++++
 check_whence.py |  1 +
 2 files changed, 22 insertions(+)

diff --git a/.editorconfig b/.editorconfig
new file mode 100644
index 0000000000000000000000000000000000000000..100bbcebaac4514cb2b8377c1e0b98f0c6964d9b
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
+max_line_length = 90
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

