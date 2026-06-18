From: Yu Chuanyu <lucayu.alight@gmail.com>
Date: Thu, 18 Jun 2026 21:45:25 +0800
Subject: [PATCH] rv: update rvgen monitor synthesis documentation path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-rvgen-doc-path-v1-1-9bcf0148417a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz1jCVAk/V0EMNHHBDAElgJCi3
 L2hHb/hvQiBvXCAvojg+ZIgm8ugsgCzTG5mFJsNdVXrSlOL/prZod0M7tOxIJHulFENqZeFHO2
 eP3L/hsP4dzjfK5vjuUBKX6t02E5yAAAA
X-Change-ID: 20260618-rvgen-doc-path-11695c57153d
To: Steven Rostedt <rostedt@goodmis.org>, 
 Gabriele Monaco <gmonaco@redhat.com>
Cc: linux-trace-kernel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yu Chuanyu <lucayu.alight@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781790327; l=1613;
 i=lucayu.alight@gmail.com; s=20260618; h=from:subject:message-id;
 bh=y70STU5WqHnmEwXDM8h6KvVTXzM4TCAuCZacgD+U7dQ=;
 b=jSEZoSXn/v+7KQENCUJMEVyZ9FtE804yj7QnCoqv/t6YPLvxrUDEdubT7WWpGdk+5aa1ci2Vc
 9TeLa2/k1z6CV0ic8hGvnJjDNtYns/lVbBzCkQ/CKb+zbJP4AkGIMjv
X-Developer-Key: i=lucayu.alight@gmail.com; a=ed25519;
 pk=ctVJlHrt5LLZUQdDrVWTtL5fYY5bukfU6L4wkFzuvZk=
X-Endpoint-Received: by B4 Relay for lucayu.alight@gmail.com/20260618 with auth_id=830
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rvgen source comments still refer to da_monitor_synthesis.rst, which
no longer exists. The documentation is now available in
monitor_synthesis.rst. Update both references to point to the current
file.

Signed-off-by: Yu Chuanyu <lucayu.alight@gmail.com>
---
 tools/verification/rvgen/__main__.py    | 2 +-
 tools/verification/rvgen/rvgen/dot2k.py | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/tools/verification/rvgen/__main__.py b/tools/verification/rvgen/__main__.py
index 5c923dc..2a2bb03 100644
--- a/tools/verification/rvgen/__main__.py
+++ b/tools/verification/rvgen/__main__.py
@@ -6,7 +6,7 @@
 # dot2k: transform dot files into a monitor for the Linux kernel.
 #
 # For further information, see:
-#   Documentation/trace/rv/da_monitor_synthesis.rst
+#   Documentation/trace/rv/monitor_synthesis.rst
 
 if __name__ == '__main__':
     from rvgen.dot2k import da2k, ha2k
diff --git a/tools/verification/rvgen/rvgen/dot2k.py b/tools/verification/rvgen/rvgen/dot2k.py
index 110cfd6..326984f 100644
--- a/tools/verification/rvgen/rvgen/dot2k.py
+++ b/tools/verification/rvgen/rvgen/dot2k.py
@@ -6,7 +6,7 @@
 # dot2k: transform dot files into a monitor for the Linux kernel.
 #
 # For further information, see:
-#   Documentation/trace/rv/da_monitor_synthesis.rst
+#   Documentation/trace/rv/monitor_synthesis.rst
 
 from collections import deque
 from .dot2c import Dot2c

---
base-commit: e771677c937da5808f7b6c1f0e4a97ec1a84f8a8
change-id: 20260618-rvgen-doc-path-11695c57153d

Best regards,
--  
Yu Chuanyu <lucayu.alight@gmail.com>

