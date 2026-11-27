MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-pillow-sg-v1-2-cbcff72e5e81@certik.com>
References: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
In-Reply-To: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 10:05:10 +0000
Subject: [meta-python][scarthgap][PATCH 2/4] python3-pillow: patch
 CVE-2026-112900
To: openembedded-devel@lists.openembedded.org
Cc: Anuj Mittal <anuj.mittal@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795830619; l=2776;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=16Rh8FWN4l5+tnO/L2TgvGdspo0bZ/e/VtaB726qM/Y=;
 b=hRs4fAAq0lBqyh0N38dY6ZT+tXB31RA1RIk72oQmBDxLTfuIH9Bgdo0hYuyeB/jF1YUlLrjEd
 y70DdJboBEfCGnKqqH+gOydOwnZGPLD0+dEZVJw8NIuZv5kLbRkk3fJ
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Transform EPS file name to an absolute path before invoking Ghostscript
(#10090).

Upstream commit:
https://github.com/python-pillow/Pillow/commit/a2c363141da31a265dd536c945677db4b64f3ec9

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../python3-pillow/CVE-2026-112900.patch      | 28 +++++++++++++++++++
 .../python/python3-pillow_10.3.0.bb           |  1 +
 2 files changed, 29 insertions(+)
 create mode 100644 meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112900.patch

diff --git a/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112900.patch b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112900.patch
new file mode 100644
index 000000000..1d50a3097
--- /dev/null
+++ b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112900.patch
@@ -0,0 +1,28 @@
+From a2c363141da31a265dd536c945677db4b64f3ec9 Mon Sep 17 00:00:00 2001
+From: Andrew Murray <3112309+radarhere@users.noreply.github.com>
+Date: Thu, 1 Oct 2026 14:44:00 +1000
+Subject: [PATCH] Transform EPS file name to an absolute path before invoking
+ Ghostscript (#10090)
+
+
+CVE: CVE-2026-112900
+Upstream-Status: Backport [https://github.com/python-pillow/Pillow/commit/a2c363141da31a265dd536c945677db4b64f3ec9]
+Backport note: Drop the upstream test change in Tests/test_file_eps.py.
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+diff --git a/src/PIL/EpsImagePlugin.py b/src/PIL/EpsImagePlugin.py
+index 5eaefe339a5..a3336894ada 100644
+--- a/src/PIL/EpsImagePlugin.py
++++ b/src/PIL/EpsImagePlugin.py
+@@ -103,7 +103,10 @@ def Ghostscript(
+ 
+     infile_temp = None
+     if hasattr(fp, "name") and os.path.exists(fp.name):
+-        infile = fp.name
++        # Make the path absolute so that a filename beginning with "-" or "@"
++        # can never be interpreted by Ghostscript's argument parser
++        # as an option or an @-file token
++        infile = os.path.abspath(fp.name)
+     else:
+         in_fd, infile_temp = tempfile.mkstemp()
+         os.close(in_fd)
diff --git a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
index 844892f0c..5f228b227 100644
--- a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
+++ b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
@@ -15,6 +15,7 @@ SRC_URI = "git://github.com/python-pillow/Pillow.git;branch=main;protocol=https
            file://CVE-2026-59204.patch \
            file://CVE-2026-112393.patch \
            file://CVE-2026-112398_CVE-2026-112403.patch \
+           file://CVE-2026-112900.patch \
            "
 SRCREV = "5c89d88eee199ba53f64581ea39b6a1bc52feb1a"
 
