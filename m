From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 22 Feb 2024 11:16:21 +0100
Subject: [PATCH v2] utest/trace-utest: include libgen.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-utest-fixes-v2-1-7b8ee8dca0b7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPQe12UC/22MOw7CMBAFrxJtzSJ/MERU3AOlcOwlWYl8ZBsLF
 PnumNSU855mNogUmCJcmw0CZY68zBXUoQE32nkgZF8ZlFAnoaTBV6KY8MFviui88c5pao3uoRp
 roP2owr2rPHJMS/js8Sx/6/9OlihRu/5iVSuNOPvbMFl+Ht0yQVdK+QJ84vY9pgAAAA==
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708596981; l=995;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=6Ny3lyrBgkhFAqGaBY9h9ovP4pU1KSlRzmaYH3L7vp4=;
 b=g7no27a/CNeGdKT0TxMHMXmvcPkuv8xDcmAf7Rm698Hy/Vf3Rgk/TaxQLRN2KJuzvho4f7Ag7
 YQhZh5hPRoaAemc78tSFkiE3yhglhaxS35QG3/2ZAYDxGKyjbaZdLlu
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the build with musl + clang >=15; musl doesn't define
basename() anywhere else, and clang >=15 doesn't allow implicit
declarations.

Fixes: 58cbc1b2a84e ("libtraceevent: Add unit test framework for library commands")
Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
Changes in v2:
- Better commit description, message
- Link to v1: https://lore.kernel.org/r/20240215-utest-fixes-v1-1-3cb7a281506d@gmail.com
---
 utest/trace-utest.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/utest/trace-utest.c b/utest/trace-utest.c
index 1403c86..a26e42e 100644
--- a/utest/trace-utest.c
+++ b/utest/trace-utest.c
@@ -6,6 +6,7 @@
  *   Copyright (C) 2021, VMware, Steven Rostedt <rostedt@goodmis.org>
  *
  */
+#include <libgen.h>
 #include <stdio.h>
 #include <unistd.h>
 #include <getopt.h>

---
base-commit: 6f6d5802f31992e7527a4c32b43a32fda6bf6bdf
change-id: 20240215-utest-fixes-cd5dcc3e853b

Best regards,
-- 
Miko Larsson <mikoxyzzz@gmail.com>

