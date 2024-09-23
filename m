From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:34 +0100
Subject: [PATCH v2 06/16] Style update yaml files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-6-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=2390;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=D3r7VDxVgMX1puFG4ztKGYc90o6Oa/2niv3K/sqOewM=;
 b=AQB1gvoLqViFOM94VpsEVqqhd9SYNe4Ha/dEE9htoTP3W9PidvuWoL9un/UdPQOni6ICKFEtE
 SCmpGsjs/YsC0IktGJjXFwiu/RNjYq0R7QgV5XqAXzgtk2L6/+TxM04
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 .gitlab-ci.yml          |  2 +-
 .pre-commit-config.yaml | 38 +++++++++++++++++++-------------------
 2 files changed, 20 insertions(+), 20 deletions(-)

diff --git a/.gitlab-ci.yml b/.gitlab-ci.yml
index ae96f7d859fc34ebc74c93a93993f623e05d78a2..e05ef3bb81c8f15049a3b068daac9fff35184d17 100644
--- a/.gitlab-ci.yml
+++ b/.gitlab-ci.yml
@@ -11,7 +11,7 @@ check-commits:
   stage: test
   image: registry.gitlab.com/kernel-firmware/linux-firmware
   rules:
-   - if: $CI_MERGE_REQUEST_ID
+    - if: $CI_MERGE_REQUEST_ID
   script:
     - ci-fairy check-commits --signed-off-by --textwidth=0
 
diff --git a/.pre-commit-config.yaml b/.pre-commit-config.yaml
index 7a49d063250e755b531059fe24b5a571d311005f..370a2970616bda3a340ebe523cd2ee2bb57759c1 100644
--- a/.pre-commit-config.yaml
+++ b/.pre-commit-config.yaml
@@ -1,30 +1,30 @@
 default_stages: [commit]
 repos:
--   repo: https://github.com/pre-commit/pre-commit-hooks
+  - repo: https://github.com/pre-commit/pre-commit-hooks
     rev: v4.0.1
     hooks:
-    -   id: check-executables-have-shebangs
-    -   id: forbid-new-submodules
-    -   id: check-yaml
-    -   id: check-symlinks
-    -   id: destroyed-symlinks
--   repo: https://github.com/shellcheck-py/shellcheck-py
+      - id: check-executables-have-shebangs
+      - id: forbid-new-submodules
+      - id: check-yaml
+      - id: check-symlinks
+      - id: destroyed-symlinks
+  - repo: https://github.com/shellcheck-py/shellcheck-py
     rev: v0.9.0.5
     hooks:
-    -   id: shellcheck
--   repo: https://github.com/ambv/black
+      - id: shellcheck
+  - repo: https://github.com/ambv/black
     rev: 22.6.0
     hooks:
-    - id: black
--   repo: https://github.com/igorshubovych/markdownlint-cli
+      - id: black
+  - repo: https://github.com/igorshubovych/markdownlint-cli
     rev: v0.33.0
     hooks:
-    - id: markdownlint
-      args: ['--fix']
--   repo: local
+      - id: markdownlint
+        args: ['--fix']
+  - repo: local
     hooks:
-    - id: check-whence
-      name: Check whence
-      files: 'WHENCE'
-      language: script
-      entry: ./check_whence.py
+      - id: check-whence
+        name: Check whence
+        files: 'WHENCE'
+        language: script
+        entry: ./check_whence.py

-- 
2.46.1

