From: Maria Lisina <sekoohaka.sarisan@gmail.com>
Date: Sun, 13 Sep 2026 17:53:53 +0500
Subject: [PATCH v3] mfd: intel-lpss: Fix DebugFS initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-intel-lpss-debugfs-v3-1-1b8e2b1f0992@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOCcpmoC/4XNTQ6CMBCG4auQrq2hrRBw5T2Mi9LOwCT8pYONh
 nB3CytXuny/ZJ5ZBUMgYHHNVhEgEtM0pjCnTLjOji1I8qmFznWZ18pIGhfoZT8zSw/Ns0WWgGi
 KKvdK14VIh3MApNeB3h+pO+JlCu/jR1T7+pOLSipZGeOapkREV9/awVJ/dtMgdi7q/4ROhFX2g
 hYL50rzTWzb9gGIcA0c9wAAAA==
X-Change-ID: 20260913-intel-lpss-debugfs-eff3580d1295
To: Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Lee Jones <lee@kernel.org>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Maria Lisina <sekoohaka.sarisan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2621;
 i=sekoohaka.sarisan@gmail.com; h=from:subject:message-id;
 bh=OVkJMMmF2nNAP+pSJ+NbAfwUA1hhsgKU2CZw5r4W0AY=;
 b=owEBbQKS/ZANAwAKARPrfuqZo5+iAcsmYgBqppzjEw0hXTFqWpVN3rqwYCWeMDGy5njMudwbP
 clhpm2zHJGJAjMEAAEKAB0WIQQ8HZKKOdqg5DRiM0sT637qmaOfogUCaqac4wAKCRAT637qmaOf
 oj8DD/9tdUlqGKBOVJOZG4JdnJe8DbuTY4weyNPBtJK2jgwUk9Y9V4cO5dVjlcFpTAv5P5DFTZE
 yvzbPS34JmdH216m7GcPWv9+gzPgf3w6XOWE52DbxSJFPBYFpcNcJABtwO4Fu9/4EaxnJn0o7M+
 d8OSS0nZPFw+COlkjgOv/wNBEB0oVTHLNes9NbdRtqw4Rw5I96pCVDBNpir9iZ7NAY92BxuEKUY
 MPumWSoVcsSy7OeIR5CN+ALgJ3uZavtDA//FPQb3NbmKVA/KTgBtDsgjuxHjw70p3R/DgzhjAXg
 hNrMYWP5JMHnY1sBv4aKNJ+iHFzKFgKDJFppXXZeyGr1B5+hHqjB2vSI0rthEp2f0xmQOrQwKKU
 faiwbSUxqrQYiay9upI0Cj+bSDYGRBFF1RtUnBfP3ZijPKT7VKmtfbx0RRGs0v7fTL5QZnG5Ma9
 GyOmKyxBfIIIeKG/W4nETwoK2U/HZIzsl6MWaVB4v5RVrrOrmDCVlPp/FJrpiix7SNLb/mi7P3C
 ueVsUUeNhXb00LAhLbqk8ZaQyteiwmy7aGa7En9ZH5ex39gWAiq8uE+aRjc3zvgmo6fqQjV5X28
 hwv3rJszGiq5pE6VNy2PD1OBGQWfhIjRetMLudcKKewEIlTcAsFdPOJ9yXhRjIqq46BhDEVpsYE
 H5qQ37aacTcYQjw==
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

This patch adds proper checks to intel_lpss_init() and
intel_lpss_debugfs_add() functions and removes warning message.

Signed-off-by: Maria Lisina <sekoohaka.sarisan@gmail.com>
---
Changes in v3:
- Fixed commit name and description.
- Link to v2: https://lore.kernel.org/r/20260913-intel-lpss-debugfs-v2-1-a1a4faf5cc63@gmail.com

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

