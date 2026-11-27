MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-pillow-sg-v1-4-cbcff72e5e81@certik.com>
References: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
In-Reply-To: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 10:05:11 +0000
Subject: [meta-python][scarthgap][PATCH 4/4] python3-pillow: patch
 CVE-2026-112406
To: openembedded-devel@lists.openembedded.org
Cc: Anuj Mittal <anuj.mittal@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795830619; l=2898;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=f0f1/8Xs4Bx9GcWebrCzo/t4/bZ2s1JSpSOy0JpVJzM=;
 b=s0xxUOIqNlKnxTtPY3/MEt64KXjSG9zvaNALzvugZrfJsgelSGfSbrwPAU6ykwvVI3ayMcgeq
 euyPgrEn4k2DaMbr+TPPrQBrqsHN7JnyCAOnw6J7UmFvOj7Rw0BqsA1
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Prevent infinite loop when rewriting PDF pages (#10125).

Upstream commit:
https://github.com/python-pillow/Pillow/commit/b3ebf20c694f2f12537a629c30229a1d5a53f777

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../python3-pillow/CVE-2026-112406.patch      | 26 +++++++++++++++++++
 .../python/python3-pillow_10.3.0.bb           |  1 +
 2 files changed, 27 insertions(+)
 create mode 100644 meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112406.patch

diff --git a/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112406.patch b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112406.patch
new file mode 100644
index 000000000..ab6e180d1
--- /dev/null
+++ b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112406.patch
@@ -0,0 +1,26 @@
+From b3ebf20c694f2f12537a629c30229a1d5a53f777 Mon Sep 17 00:00:00 2001
+From: Andrew Murray <3112309+radarhere@users.noreply.github.com>
+Date: Mon, 5 Oct 2026 18:12:40 +1100
+Subject: [PATCH] Prevent infinite loop when rewriting PDF pages (#10125)
+
+
+CVE: CVE-2026-112406
+Upstream-Status: Backport [https://github.com/python-pillow/Pillow/commit/b3ebf20c694f2f12537a629c30229a1d5a53f777]
+Backport note: Omit upstream test changes in Tests/test_pdfparser.py.
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+diff --git a/src/PIL/PdfParser.py b/src/PIL/PdfParser.py
+index 5f75cf4d3ee..e7ec6180b6c 100644
+--- a/src/PIL/PdfParser.py
++++ b/src/PIL/PdfParser.py
+@@ -502,7 +502,9 @@ def rewrite_pages(self) -> None:
+                     self.pages[j] = new_page_ref
+         # delete redundant Pages tree nodes from xref table
+         for pages_tree_node_ref in pages_tree_nodes_to_delete:
+-            while pages_tree_node_ref:
++            processed_refs = []
++            while pages_tree_node_ref and pages_tree_node_ref not in processed_refs:
++                processed_refs.append(pages_tree_node_ref)
+                 pages_tree_node = self.cached_objects[pages_tree_node_ref]
+                 if pages_tree_node_ref.object_id in self.xref_table:
+                     del self.xref_table[pages_tree_node_ref.object_id]
diff --git a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
index 374984d0e..d7adf8cef 100644
--- a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
+++ b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
@@ -17,6 +17,7 @@ SRC_URI = "git://github.com/python-pillow/Pillow.git;branch=main;protocol=https
            file://CVE-2026-112398_CVE-2026-112403.patch \
            file://CVE-2026-112900.patch \
            file://CVE-2026-112400.patch \
+           file://CVE-2026-112406.patch \
            "
 SRCREV = "5c89d88eee199ba53f64581ea39b6a1bc52feb1a"
 
