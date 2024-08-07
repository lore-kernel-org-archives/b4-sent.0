From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 07 Aug 2024 14:36:12 +0800
Subject: [PATCH v2] ACPI: introduce acpi_arch_init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-intro-acpi-arch-init-v2-1-9231e23a7721@gmail.com>
X-B4-Tracking: v=1; b=H4sIANsVs2YC/x3MQQqAIBBA0avIrBsQi8quEi3ExpqNySgRhHdPW
 r7F/y9kEqYMi3pB6ObMV2wwnQJ/ungQ8t4MRptBz3pCjkUudD4xOvFnMxcM3tpAfU+j2aGlSSj
 w82/XrdYPmQDXLGYAAAA=
To: Hanjun Guo <guohanjun@huawei.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Sunil V L <sunilvl@ventanamicro.com>
Cc: linux-acpi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2274;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=PwRtjL6KwaJet/RgRLb11kIQcxlFiQsK9B6kUpBB98I=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmsxZzDbVLjrRb5y9D3vj5+ZJtq/uQt1buMk2J0
 yY/VdwFnQ2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZrMWcwAKCRCwMePKe/7Z
 bmhTD/0awF1iZkM4M3/RJ8uH0JLx9//MZ+4UbNQ/bk3rkzyx7eeYjW3yzIipcptQl2czV5bH4TK
 UHthyGbyJXXHnTSt9C7yv3lXmhVOxaLaJ0WvEWr6lxaW5HOL/5YPyQK5FlepvuHt917CcWxnN9P
 02fpZJbMVs4j2injz1uak/OMxzVP0+3dXFsw5wSRUMBjLvOAu3hw8WujVsKtJ3nQZH6eVqwxV9u
 Fpylxrqy5kvtMbrJ53/WUdNO0v9GUM2tmYX5TgBgnVHLXN15BNyHfMGSvjllG3GVRwFyhc+Fq23
 Q0gt7UqiY3lAb8+9vJ98IAbORIV53J3IjCZghu6kp/NLxP6s+pZyCg7Gnqk9G+S13kB69Y12jKf
 eEXbEhAAk/XVmBIvZcy/0r6Hh9Z7WlXcCN1H0seCikEmNEkkb9XJWGFPR3moPIjZYzdnIPXRIuW
 rpZMkkCHBTA1TM94iaSAfLCnWZ/vvvU9yQUPBR1nke6358Kq3zlbFqhJ975oI3dnBBKbG6e88aq
 iu2CDJV9P0aJtaJC0IQ4YjkdsNcvbdS45NBU+c3kC5Ib2QGBd1azGc3lg6kbrdpnd+u81HPxVit
 PXlDa0IR+autUP1X/f7hjdKTB3KlXEcJh2R9NDrZravfs5aSA3uCvfK54HS17DahgMAz+pdjYLj
 67jgYqyHg1TNIDw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To avoid arch-specific code in general ACPI initialization flow,
we introduce a weak symbol acpi_arch_init. Currently, arm64 can
utillize this to insert its specific flow. In the future,
other architectures can also have chance to define their own
arch-specific acpi initialization process if necessary.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes from v1
- Change acpi_arch_init from a static inline stub to a weak function
  according to Haijun Guo's advice
---
 drivers/acpi/arm64/init.c | 2 +-
 drivers/acpi/bus.c        | 4 +++-
 include/linux/acpi.h      | 6 +-----
 3 files changed, 5 insertions(+), 7 deletions(-)

diff --git a/drivers/acpi/arm64/init.c b/drivers/acpi/arm64/init.c
index d0c8aed90fd1..7a47d8095a7d 100644
--- a/drivers/acpi/arm64/init.c
+++ b/drivers/acpi/arm64/init.c
@@ -2,7 +2,7 @@
 #include <linux/acpi.h>
 #include "init.h"
 
-void __init acpi_arm_init(void)
+void __init acpi_arch_init(void)
 {
 	if (IS_ENABLED(CONFIG_ACPI_AGDI))
 		acpi_agdi_init();
diff --git a/drivers/acpi/bus.c b/drivers/acpi/bus.c
index 284bc2e03580..b47541e45a5a 100644
--- a/drivers/acpi/bus.c
+++ b/drivers/acpi/bus.c
@@ -1431,6 +1431,8 @@ static int __init acpi_bus_init(void)
 struct kobject *acpi_kobj;
 EXPORT_SYMBOL_GPL(acpi_kobj);
 
+void __weak acpi_arch_init(void) { }
+
 static int __init acpi_init(void)
 {
 	int result;
@@ -1458,7 +1460,7 @@ static int __init acpi_init(void)
 	acpi_viot_early_init();
 	acpi_hest_init();
 	acpi_ghes_init();
-	acpi_arm_init();
+	acpi_arch_init();
 	acpi_scan_init();
 	acpi_ec_init();
 	acpi_debugfs_init();
diff --git a/include/linux/acpi.h b/include/linux/acpi.h
index 0687a442fec7..52862c377747 100644
--- a/include/linux/acpi.h
+++ b/include/linux/acpi.h
@@ -1523,11 +1523,7 @@ static inline int find_acpi_cpu_topology_hetero_id(unsigned int cpu)
 }
 #endif
 
-#ifdef CONFIG_ARM64
-void acpi_arm_init(void);
-#else
-static inline void acpi_arm_init(void) { }
-#endif
+void acpi_arch_init(void);
 
 #ifdef CONFIG_ACPI_PCC
 void acpi_init_pcc(void);

---
base-commit: d4560686726f7a357922f300fc81f5964be8df04
change-id: 20240807-intro-acpi-arch-init-fc99fe33e62d

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

