From: Miao Wang <shankerwangmiao@gmail.com>
Date: Thu, 08 Aug 2024 17:00:55 +0800
Subject: [PATCH v3] ACPI: introduce acpi_arch_init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240808-intro-acpi-arch-init-v3-1-ba510859baff@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEaJtGYC/4XNQQrCMBAF0KuUWTvSTsRYV95DugjppB2wTUlCU
 ErubuwFXL4P//8dIgfhCPdmh8BZovi1Qp0asLNZJ0YZq4FaurS3VqOsKXg0dhM0wc7VktDZvne
 sFF9phFrdAjt5H7PPoXqWmHz4HC+ZfumfwUzYYU+qY1JGa+oe02LkdbZ+gaGU8gWP0skDuAAAA
 A==
To: Hanjun Guo <guohanjun@huawei.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Sunil V L <sunilvl@ventanamicro.com>, Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-acpi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2560;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=eKOgTF8VhVeyKx0G1xa3uOLgNoi2NBf8PN9xLUwoWag=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmtIoacnmHXtf/2yn3WwFHLaPfqaWJRBUEo9FMx
 oRyn4yL9QCJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZrSKGgAKCRCwMePKe/7Z
 bnXBD/9pCBlIeUwE6hPCimjF22yrOgvcpqPQdiTygNgjLR8kd0BrfMtvQoouGoEAZFv5xGGVnZV
 2Y3dmmhvJP1l51duLAp+0buDO53GW1LKsKyKEptBjPwUglSuTzfHMG/AlH3Eh28FE+Wh1S1OR5y
 GRhhfVcUxat623ZmGuzAZBtwEZx2caAr6dC9l5W/VR1yOFHXhwoPjawoTBoU1CFawnVJfwWAzjL
 DXrnCBkaigLmgd70itGi9zJL4POJVge6cf8JjpfTrZXdXezPQCXQNAkIUoYl8vKPinh89Gu0qqC
 WH6oydsVNbp1SnUlHgijuxcZtfvh6vN1wP8iCmHRwRvR2rXq/lw/Z/vfwPy1BJCXwOMFQxXq2gt
 +1bYVHi6NJKBQEK0EiCp9qzxEMa0iaW3SbpXND+osw62DYzZSbmunq6Obf+zN9sbheQXDRsy+48
 y8aU8bIpQcxKW1A8mKPPUuC57Kc5r/ywhklp+nfJP9R4eNF6ij/D6cwKjw93Jk/RuehUau93uwh
 i2+i0ot9N1WHBCxHnglLXWC/AlPsu2RI2V9H/7+deGG6ZjjL5SoWEX8MUJNQQh8SXj/7CSDPmAQ
 T0zlH/aLkevO/hfC4JTb5h+fmHJvTf7Uf896qSt3wvwa3J7HPxvI+oQptRurUTlFXlVDzXpZ4TN
 iz9huz55A7n6bjg==
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
Reviewed-by: Sunil V L <sunilvl@ventanamicro.com>
Reviewed-by: Sudeep Holla <sudeep.holla@arm.com>
---
Changes from v1
- Change acpi_arch_init from a static inline stub to a weak function
  according to Haijun Guo's advice
---
Changes from v2:
- Add __init attribute to the weak acpi_arch_init stub
- Link to v2: https://lore.kernel.org/r/20240807-intro-acpi-arch-init-v2-1-9231e23a7721@gmail.com
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
index 284bc2e03580..3b319b163d82 100644
--- a/drivers/acpi/bus.c
+++ b/drivers/acpi/bus.c
@@ -1431,6 +1431,8 @@ static int __init acpi_bus_init(void)
 struct kobject *acpi_kobj;
 EXPORT_SYMBOL_GPL(acpi_kobj);
 
+void __weak __init acpi_arch_init(void) { }
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

