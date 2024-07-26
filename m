From: Miao Wang <shankerwangmiao@gmail.com>
To: linux-acpi@vger.kernel.org,
    linux-arm-kernel@lists.infradead.org
Cc: "Rafael J. Wysocki" <rafael@kernel.org>,
    Len Brown <lenb@kernel.org>,
    Hanjun Guo <guohanjun@huawei.com>
Date: Fri, 26 Jul 2024 23:03:01 +0800
Subject: [PATCH] ACPI: rename acpi_arm_init to acpi_arch_init
Message-Id: 446b96d0-4b61-11ef-9239-3f7ac1938848@innull.com
X-Developer-Signature: v=1; a=openpgp-sha256; l=2132;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=CSwR7TCrsvxBPNO4Jtd8j8bvR9ZKzVr6G7jVKrKc2YE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmo70BNKf+wvGOF+OSz4/dfrlMNQTR+yfGwNLRI
 6Ww8gkp0iqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZqO9AQAKCRCwMePKe/7Z
 bqZZD/wLFGqmtueW+3Cie4OcSd8aAT6XB3iIl/wxoQSMWN87RcC0Nr578CQ2IGmbCP3BORRm/7B
 mflmMfxLruh0Yqp3tjXRMwXf3BRrD/u8LIC4ccLivlG5OJZZb3jvdnjB11WIj6cjqdpZBPe2XCi
 besJCMEwqLIkqd1N1LKa/rGKDLY8qmn6PQpNOhupGXNpBp/7DwNI7pcT1RolcFledN3ZZALCymY
 g3VUWWykFEh/u0djm8RHfsQ7V8KrIz22OYG5v+DTGfeasb0Bx9yqIxHMUbOkaZe+zd3lMI+QPJ4
 iak5imJ9yavYnMbs9I5GRouEK/QpyxzPsbZzmihSfkzSOe45UXDTcefLc9HqMWpj7Q5I5R714tT
 dDtO0vrnqAhYNJaZs2LMYVvTzoqrbl+PqIWYzayMzJc+rGESdBnx8oT/AJJfny43zGR5IS33xDi
 MWdJlwDpld+g/n+KMFoFw3oug2RGtB5sKUdztxUrwQLlBfGsS60mZbUHVya1QlHTYnCX8KijBfW
 aul8tJCCLdwOn3wOSSKH645tC/MijdHgi1WlcMXPeBvmP7ajS2Cnb4synIDS7Qe3xUv4Pe6b2IZ
 wik9FKwGZr3mimSOXyMUvZ4eIezqc7CLYE0djzCz326kl+5UrxX4/Ztn9kLLkiKlIAzp1BK+s4c
 CccvAn3xrX6qpcg==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit

So that we avoid arch-specific code in general ACPI initialization flow.
Other architectures can also have chance to define their own
arch-specific acpi initialization process if necessary.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 arch/arm64/include/asm/acpi.h | 2 ++
 drivers/acpi/arm64/init.c     | 2 +-
 drivers/acpi/bus.c            | 2 +-
 include/linux/acpi.h          | 6 +++---
 4 files changed, 7 insertions(+), 5 deletions(-)

diff --git a/arch/arm64/include/asm/acpi.h b/arch/arm64/include/asm/acpi.h
index a407f9cd549e..0d24e920e143 100644
--- a/arch/arm64/include/asm/acpi.h
+++ b/arch/arm64/include/asm/acpi.h
@@ -188,4 +188,6 @@ static inline void acpi_map_cpus_to_nodes(void) { }
 
 #define ACPI_TABLE_UPGRADE_MAX_PHYS MEMBLOCK_ALLOC_ACCESSIBLE
 
+#define ACPI_HAVE_ARCH_INIT
+
 #endif /*_ASM_ACPI_H*/
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
index 284bc2e03580..662f69e379ef 100644
--- a/drivers/acpi/bus.c
+++ b/drivers/acpi/bus.c
@@ -1458,7 +1458,7 @@ static int __init acpi_init(void)
 	acpi_viot_early_init();
 	acpi_hest_init();
 	acpi_ghes_init();
-	acpi_arm_init();
+	acpi_arch_init();
 	acpi_scan_init();
 	acpi_ec_init();
 	acpi_debugfs_init();
diff --git a/include/linux/acpi.h b/include/linux/acpi.h
index f0b95c76c707..3c3a83499c2d 100644
--- a/include/linux/acpi.h
+++ b/include/linux/acpi.h
@@ -1517,10 +1517,10 @@ static inline int find_acpi_cpu_topology_hetero_id(unsigned int cpu)
 }
 #endif
 
-#ifdef CONFIG_ARM64
-void acpi_arm_init(void);
+#ifdef ACPI_HAVE_ARCH_INIT
+void acpi_arch_init(void);
 #else
-static inline void acpi_arm_init(void) { }
+static inline void acpi_arch_init(void) { }
 #endif
 
 #ifdef CONFIG_ACPI_PCC
-- 
2.39.2

