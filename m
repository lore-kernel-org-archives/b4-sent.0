From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 24 Jun 2025 08:50:44 -0500
Subject: [PATCH] lib: packing: Include necessary headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-packing-includes-v1-1-c23c81fab508@amd.com>
X-B4-Tracking: v=1; b=H4sIADOtWmgC/x3MQQqAIBBA0avIrBNKNKKrRItyxhoKE6UIxLsnL
 d/i/wyJIlOCUWSI9HDiy1d0jQC7L34jyVgNqlWm7ZWWYbEH+02yt+eNlKRBo/XakcOhh5qFSI7
 ffznNpXwe61EOYgAAAA==
X-Change-ID: 20250624-packing-includes-5d544b1efd86
To: Vladimir Oltean <olteanv@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750773056; l=1124;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=1ATmUuW12KVE9D3wPQ8yQHOTVuSIERg6h39NE9Fw3aU=;
 b=MCdarkHUxzygavkxODWUEUPh919s6qS4cud9Js0mf9mhf3nB8iySPhbIPLiptdn8Dt04gpKzc
 dds3LJ/Fj87BQiwrZReydyBFp7UXuZfCALw1r2AnszssNfMKYt3rtU3
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

packing.h uses ARRAY_SIZE(), BUILD_BUG_ON_MSG(), min(), max(), and
sizeof_field() without including the headers where they are defined,
potentially causing build failures.

Fix this in packing.h and sort the result.

Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 include/linux/packing.h | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/include/linux/packing.h b/include/linux/packing.h
index 0589d70bbe0434c418f41b842f92b3300a107762..20ae4d452c7bb4069eb625ba332d617c2a840193 100644
--- a/include/linux/packing.h
+++ b/include/linux/packing.h
@@ -5,8 +5,12 @@
 #ifndef _LINUX_PACKING_H
 #define _LINUX_PACKING_H
 
-#include <linux/types.h>
+#include <linux/array_size.h>
 #include <linux/bitops.h>
+#include <linux/build_bug.h>
+#include <linux/minmax.h>
+#include <linux/stddef.h>
+#include <linux/types.h>
 
 #define GEN_PACKED_FIELD_STRUCT(__type) \
 	struct packed_field_ ## __type { \

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250624-packing-includes-5d544b1efd86

Best regards,
-- 
Nathan Lynch <nathan.lynch@amd.com>

