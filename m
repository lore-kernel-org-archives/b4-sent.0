From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 15 Feb 2024 10:02:42 +0100
Subject: [PATCH 2/3] utest/tracefs-utest: add missing define
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240215-utest-fixes-v1-2-24678d859de2@gmail.com>
References: <20240215-utest-fixes-v1-0-24678d859de2@gmail.com>
In-Reply-To: <20240215-utest-fixes-v1-0-24678d859de2@gmail.com>
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707987764; l=600;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=WatW4A5ff1zXd0UKVabbH5FGJ0iBrroLNhZ+TKD11KQ=;
 b=TR7ztiuBuVrFS0D05PaJoFLNX5OXLrZmeCnDJHVnLRAofKi9x6ydjJfxyvQkoOeckUO08rEiJ
 CM4IgZbC4IoCgc+wiUg7TzXtxgx60orE6HCotSfqZHdfWe3EAFaz/Gg
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes FTBFS with clang >=15

Fixes: 0f45e68cb04a ("libtracefs: Add unit tests for tracefs_cpu functions")
Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
 utest/tracefs-utest.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/utest/tracefs-utest.c b/utest/tracefs-utest.c
index a798ace..e30e8e7 100644
--- a/utest/tracefs-utest.c
+++ b/utest/tracefs-utest.c
@@ -3,6 +3,8 @@
  * Copyright (C) 2020, VMware, Tzvetomir Stoyanov <tz.stoyanov@gmail.com>
  *
  */
+#define _LARGEFILE64_SOURCE
+
 #include <stdio.h>
 #include <stdlib.h>
 #include <sys/stat.h>

-- 
2.43.0

