From: Maria Lisina <sekoohaka.sarisan@gmail.com>
Date: Sun, 13 Sep 2026 17:49:11 +0500
Subject: [PATCH v2] mfd/intel-lpss: Fix DebugFS initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-intel-lpss-debugfs-v2-1-a1a4faf5cc63@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMabpmoC/32NSwqDQBAFryK9TgdnBkWzyj3EhY7d2uCPaSMJ4
 t0z8QBZVsGrd4BSEFJ4JAcE2kVlmSPYWwJ+aOaeULrIYFObp6VxKPNGI46rKnbUvnpWJGaXFWl
 nbJlBHK6BWN5XtKojD6LbEj7Xx25+9m9uN2iwcM63bc7Mvnz2UyPj3S8T1Od5fgFcEVjmtAAAA
 A==
X-Change-ID: 20260913-intel-lpss-debugfs-eff3580d1295
To: Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Lee Jones <lee@kernel.org>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Maria Lisina <sekoohaka.sarisan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2468;
 i=sekoohaka.sarisan@gmail.com; h=from:subject:message-id;
 bh=ObhylMvBLeRGP+c+qG/FbxaQVC32MIujLgILkv2Vqy4=;
 b=owEBbQKS/ZANAwAKARPrfuqZo5+iAcsmYgBqppvQHgPFedfrDk2pLoPHPjV5eByNXH1CK3RoH
 U9d2kUS6MqJAjMEAAEKAB0WIQQ8HZKKOdqg5DRiM0sT637qmaOfogUCaqab0AAKCRAT637qmaOf
 onR5D/9FAEnj5NRceIFDPBYNbMlWBvZXYvf4+Q8Yf/W575f4mH1DfVI9gijvSJ//EEex0TUEuaK
 QkGjniZ7HNA4guQc09yzNgGtq1nwpOqYBqhfcVVR9FWWE/Hw7JzyXLCxBTdsivgcNJIWD8FHWDl
 7ZQJdvo9oyt3+WaumB55pSPX2HfqIRj4kZw0N/nI1sTmmJpo3vSBSlhqjFcRJ82WONjbIRKYInM
 i+O2UxUPN2EtqI0rSYFCrOPRfMxfZUx4p20LIRteVTDKfozcLH04RiDBIBT/KisnQICj1NIPOSv
 jUG9AURr/SH3GuOJrLNy30K+lmRDqnZUYGF8FUzXjCrYjCFdI395TunAsyQRzPdtS5E9Ou07XhJ
 GUjIm1L6jDkGK6MKjnYTnDE/F8KiBMTqZxsMpLUAi8lDgBWCgyINVD6mLIRXzNbvOSJLTE8yhkV
 m5CEO5TxtstfVntpdWc6xhZE6cLQgqZ3PS3zo/tO634K+whnimVrviwo6O36lDaIiaqqhqt6QmE
 Ou9sbFeGw0hG8Ygs8t9lF96VVtd+Q6TrPzkOjAiBAJlrQtGWSEBXUQIvZ/ec1jLXvrs90zEva9j
 boPZtdIB/YS8ax/EKlhC0ppQgzlBVkyXtN3RNSP1Jb16MudQweGLTAUvYMawAUflcsciWVbeuqp
 kNCEUuxcI/mPdlQ==
X-Developer-Key: i=sekoohaka.sarisan@gmail.com; a=openpgp;
 fpr=3C1D928A39DAA0E43462334B13EB7EEA99A39FA2
X-Endpoint-Received: by B4 Relay for sekoohaka.sarisan@gmail.com/default with auth_id=1030
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original code defers DebugFS check with unnecessary warning message
which also appears when DebugFS is simply disabled.

Therefore it spams dmesg with these messages:

  intel-lpss 0000:00:15.0: Failed to create debugfs entries
  intel-lpss 0000:00:15.3: Failed to create debugfs entries
  intel-lpss 0000:00:1e.0: Failed to create debugfs entries
  intel-lpss 0000:00:1e.2: Failed to create debugfs entries

This patch adds proper checks to intel_lpss_exit() and
intel_lpss_debugfs_add() functions and removes warning message.

Signed-off-by: Maria Lisina <sekoohaka.sarisan@gmail.com>
---
Changes in v2:
- Fixed function name in comment section.
- Link to v1: https://lore.kernel.org/r/20260913-intel-lpss-debugfs-v1-1-833cbb6fffc9@gmail.com
---
 drivers/mfd/intel-lpss.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/drivers/mfd/intel-lpss.c b/drivers/mfd/intel-lpss.c
index 63d6694f71457b2e09d238af0a9bfb897a169a64..c2cb58c0f98a996d5a2718956092e74139f2a286 100644
--- a/drivers/mfd/intel-lpss.c
+++ b/drivers/mfd/intel-lpss.c
@@ -146,9 +146,12 @@ static int intel_lpss_debugfs_add(struct intel_lpss *lpss)
 {
 	struct dentry *dir;
 
+	if (!intel_lpss_debugfs) {
+		lpss->debugfs = NULL;
+		return 0;
+	}
+
 	dir = debugfs_create_dir(dev_name(lpss->dev), intel_lpss_debugfs);
-	if (IS_ERR(dir))
-		return PTR_ERR(dir);
 
 	/* Cache the values into lpss structure */
 	intel_lpss_cache_ltr(lpss);
@@ -432,10 +435,7 @@ int intel_lpss_probe(struct device *dev,
 		goto err_clk_register;
 
 	intel_lpss_ltr_expose(lpss);
-
-	ret = intel_lpss_debugfs_add(lpss);
-	if (ret)
-		dev_warn(dev, "Failed to create debugfs entries\n");
+	intel_lpss_debugfs_add(lpss);
 
 	if (intel_lpss_has_idma(lpss)) {
 		ret = mfd_add_devices(dev, lpss->devid, &intel_lpss_idma64_cell,
@@ -539,6 +539,13 @@ EXPORT_NS_GPL_DEV_PM_OPS(intel_lpss_pm_ops, INTEL_LPSS) = {
 static int __init intel_lpss_init(void)
 {
 	intel_lpss_debugfs = debugfs_create_dir("intel_lpss", NULL);
+
+	/* Ensure intel_lpss_debugfs stays NULL on error,
+	 * so intel_lpss_debugfs_add() exits properly.
+	 */
+	if (IS_ERR(intel_lpss_debugfs))
+		intel_lpss_debugfs = NULL;
+
 	return 0;
 }
 module_init(intel_lpss_init);

---
base-commit: 2f0c1cf72f4682178506f513bbf015e591b1aa4a
change-id: 20260913-intel-lpss-debugfs-eff3580d1295

Best regards,
-- 
Maria Lisina <sekoohaka.sarisan@gmail.com>

