From: Miao Wang <shankerwangmiao@gmail.com>
Date: Thu, 21 Nov 2024 22:25:21 +0800
Subject: [PATCH v4] ACPI: introduce acpi_arch_init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241121-intro-acpi-arch-init-v4-1-b1fb517e7d8b@gmail.com>
X-B4-Tracking: v=1; b=H4sIANBCP2cC/4XNQQ6CMBCF4auYrq1ppyDUlfcwLkqZwiRCSUsaD
 eHuFlZsjMv/JfPNwiIGwshup4UFTBTJjzmK84nZ3owdcmpzMxBQiFpUnMY5eG7sRNwE2+emmTu
 rtUOl8Aoty6dTQEfvnX08c/cUZx8++5cE2/oHTMAl16AkgjJVBfLeDYZeF+sHtoFJHZH6B6Iy0
 phSirrUjXHuiKzr+gUBRyTj/QAAAA==
X-Change-ID: 20240807-intro-acpi-arch-init-fc99fe33e62d
To: Hanjun Guo <guohanjun@huawei.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Sunil V L <sunilvl@ventanamicro.com>, Sudeep Holla <sudeep.holla@arm.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>
Cc: linux-acpi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-riscv@lists.infradead.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3611;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=Jl9aXTAyOwV80IxKtP6Gua28eCTN9Fr/tbA9iL0gCVo=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBnP0Lbcf9PkzbBl6oc3sU4YtPr5VeRoXj99DkCl
 d0CRuCkc0KJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZz9C2wAKCRCwMePKe/7Z
 bpz2EAC9hdUoauiIhwZ41G6gzCpymFr9rJ4nwpqKCvLyOGfcEE8bTMTXxFb2Ms1anYnrPedeb2+
 ex9XY+8zVBkswP7VYOC2wKs6bQzoqkrRz9PfsMlmkxn/NVn4jI570uVVFjV+ad+TQt/ZhjRPptY
 b8epvh4sxKfhvB3K3/gqFlMHqh7cjA0FKTEsooBFeW0KUXhdNcjXVIvQXFBOlEeouEnFOGg4zLr
 yrX6rNFwKVHxmfjR1c1RcL6ghFr0+jTDdCpghP6Bp8bLlCjW3V+cPk3XiG2yLYsqFygZ1OZCVQQ
 n3C0btlKgxDAjRky5OCqkZ8O3O+o9QJT42X6eziQu4fj1YftCWzhUS/C1ZOPPf8J5u6uvnWxsal
 GZ7M3fDUybkuVwMhxny3MpkKZ8QEhg7pif4vszPts03u1zu22ePxckKdIBmLFjcb1OKvLzfIeVd
 f9eSyY7GD8Rc1iqa2vu49AuFlGAh8DpElw8t03wTRDrUV6+Dcy+nsAF6U+UINpLMyW2WOLDW/ig
 sj0NRHc6HGFRtRJAMOrjvaE9jPyXgT4uO6ypThNoqukknZwzpfkJbpELnbptK/RVSbqOni6lqft
 lBw880LaIK772r8VFO7eDwWigLlMEF8UfZIp/PiYQza8FXA7MfeVbBarS+FhReg+e/oMh0XCNwq
 CdhzVutnQBC+Dvg==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To avoid arch-specific code in general ACPI initialization flow,
we introduce a weak symbol acpi_arch_init. Currently, arm64 and
riscv can utillize this to insert their arch-specific flow. In
the future, other architectures can also have chance to define
their own arch-specific acpi initialization process if necessary.

Reviewed-by: Sunil V L <sunilvl@ventanamicro.com>
Reviewed-by: Sudeep Holla <sudeep.holla@arm.com>
Acked-by: Hanjun Guo <guohanjun@huawei.com>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes from v1
- Change acpi_arch_init from a static inline stub to a weak function
  according to Haijun Guo's advice
---
Changes from v2:
- Add __init attribute to the weak acpi_arch_init stub
- Link to v2: https://lore.kernel.org/r/20240807-intro-acpi-arch-init-v2-1-9231e23a7721@gmail.com
---
Changes in v4:
- Rebased to recent Linus's tree
- Consolidate acpi_arm_init and acpi_riscv_init into acpi_arch_init
- Link to v3: https://lore.kernel.org/r/20240808-intro-acpi-arch-init-v3-1-ba510859baff@gmail.com
---
 drivers/acpi/arm64/init.c |  2 +-
 drivers/acpi/bus.c        |  5 +++--
 drivers/acpi/riscv/init.c |  2 +-
 include/linux/acpi.h      | 12 +-----------
 4 files changed, 6 insertions(+), 15 deletions(-)

diff --git a/drivers/acpi/arm64/init.c b/drivers/acpi/arm64/init.c
index d0c8aed90fd16f9a7fe62b8c551c0cd091cb91ec..7a47d8095a7dd5f3dac6e0754d6271bf6de269ff 100644
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
index 16917dc3ad604cc537d05bb2c0034ff5a9181fd0..058910af82bca689577909e8967073ca3198b3c8 100644
--- a/drivers/acpi/bus.c
+++ b/drivers/acpi/bus.c
@@ -1434,6 +1434,8 @@ static int __init acpi_bus_init(void)
 struct kobject *acpi_kobj;
 EXPORT_SYMBOL_GPL(acpi_kobj);
 
+void __weak __init acpi_arch_init(void) { }
+
 static int __init acpi_init(void)
 {
 	int result;
@@ -1461,8 +1463,7 @@ static int __init acpi_init(void)
 	acpi_viot_early_init();
 	acpi_hest_init();
 	acpi_ghes_init();
-	acpi_arm_init();
-	acpi_riscv_init();
+	acpi_arch_init();
 	acpi_scan_init();
 	acpi_ec_init();
 	acpi_debugfs_init();
diff --git a/drivers/acpi/riscv/init.c b/drivers/acpi/riscv/init.c
index 5ef97905a72759ea2aab3195e56b7ee580eded96..673e4d5dd752719ae7ed0017c8b5b1c688cf9b4b 100644
--- a/drivers/acpi/riscv/init.c
+++ b/drivers/acpi/riscv/init.c
@@ -7,7 +7,7 @@
 #include <linux/acpi.h>
 #include "init.h"
 
-void __init acpi_riscv_init(void)
+void __init acpi_arch_init(void)
 {
 	riscv_acpi_init_gsi_mapping();
 }
diff --git a/include/linux/acpi.h b/include/linux/acpi.h
index 7dd24acd9ffeedbe47ac392bd939309408c0afa3..05f39fbfa4856d2e6b7d45d9580cc82963764d55 100644
--- a/include/linux/acpi.h
+++ b/include/linux/acpi.h
@@ -1530,17 +1530,7 @@ static inline int find_acpi_cpu_topology_hetero_id(unsigned int cpu)
 }
 #endif
 
-#ifdef CONFIG_ARM64
-void acpi_arm_init(void);
-#else
-static inline void acpi_arm_init(void) { }
-#endif
-
-#ifdef CONFIG_RISCV
-void acpi_riscv_init(void);
-#else
-static inline void acpi_riscv_init(void) { }
-#endif
+void acpi_arch_init(void);
 
 #ifdef CONFIG_ACPI_PCC
 void acpi_init_pcc(void);

---
base-commit: 43fb83c17ba2d63dfb798f0be7453ed55ca3f9c2
change-id: 20240807-intro-acpi-arch-init-fc99fe33e62d

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

