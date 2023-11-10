From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 11 Nov 2023 03:19:52 +0800
Subject: [PATCH v2] clk: check parent_name in clk_register to avoid
 confusing log_error() output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230807-clk-fix-v2-1-0b688e21fb4e@outlook.com>
X-B4-Tracking: v=1; b=H4sIAFeCTmUC/z2Nyw6CMBREf4Xctde0VdLiyv8wLEq5SMOjpK1EQ
 /h3WxJdnpmTmQ0CeUsBbsUGnlYbrJsTiFMBptfzk9C2iUEwcWGKSTTjgJ19I5ekqrKTleISkt3
 oQNh4PZs++5MOkXwuFk/JPy4edeLehuj853hceU5/49V/fOXIUDHVNprKK5V0d684OjecjZug3
 vf9C4qsuOm5AAAA
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699643996; l=1981;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=EhPK7ucNW+E0Yp0KcbIofxN1hvfnmLx5BFY4JsVqXag=;
 b=S31tMR/BIpt98MPWMGFJ0J2158bMKoiQnokSn5QZnWzECAor7fwieaaK7ukdTHbymTDHxmTYN
 UCNEyQRJpi4BPW9YnuTRTPlSSxjn5XOs3GQrC/WH9v4JXHAEQvfS/ba
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For some gate clocks and fixed clocks without a parent, calling
clk_register will print an useless error message indicating that parent
is missing. Fix that by gaurding log_xxx() with an if-statement.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
Suggested-by: Sean Anderson <seanga2@gmail.com>
---
It's found during my development for HiSilicon clock driver.
---
Changes in v2:
- drop the commit which exports clk_mux_register.
- drop the commit which is already merged
- drop ccf enable_count fix as it'll be in another patchset
- use Anderson's patch for clk_register()
- Link to v1: https://lore.kernel.org/r/20230809-clk-fix-v1-0-808dbae54e5e@outlook.com
---
 drivers/clk/clk.c | 18 ++++++++++--------
 1 file changed, 10 insertions(+), 8 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index a5a3461b66..6ede1b4d4d 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -18,17 +18,19 @@
 int clk_register(struct clk *clk, const char *drv_name,
 		 const char *name, const char *parent_name)
 {
-	struct udevice *parent;
+	struct udevice *parent = NULL;
 	struct driver *drv;
 	int ret;
 
-	ret = uclass_get_device_by_name(UCLASS_CLK, parent_name, &parent);
-	if (ret) {
-		log_err("%s: failed to get %s device (parent of %s)\n",
-			__func__, parent_name, name);
-	} else {
-		log_debug("%s: name: %s parent: %s [0x%p]\n", __func__, name,
-			  parent->name, parent);
+	if (parent_name) {
+		ret = uclass_get_device_by_name(UCLASS_CLK, parent_name, &parent);
+		if (ret) {
+			log_err("%s: failed to get %s device (parent of %s)\n",
+				__func__, parent_name, name);
+		} else {
+			log_debug("%s: name: %s parent: %s [0x%p]\n", __func__, name,
+				  parent->name, parent);
+		}
 	}
 
 	drv = lists_driver_lookup_name(drv_name);

---
base-commit: 580eb31199be8a822e62f20965854a242f895d03
change-id: 20230807-clk-fix-17e895f79817

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

