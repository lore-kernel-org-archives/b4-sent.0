From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:06:04 -0400
Subject: [PATCH] firmware: arm_scpi: publish scpi_ops with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-arm-scpi-v1-1-6aabb6533a40@vt.edu>
X-B4-Tracking: v=1; b=H4sIAHvUsWoC/yXMwQrCMBAE0F8pe3YlSaMSf0U8JHG1KzSWXS1C6
 b+b1OMbZmYBJWFSOHcLCM2s/CoVdtdBHmJ5EPKtGpxxRxOcxTFhlBE1T4zBeOvtoTc+OKiLSej
 O3+3tcv1bP+lJ+d0uWiNFJUwSSx5atHE+7XuU7GFdf6Msln+PAAAA
X-Change-ID: 20260921-mb-arm-scpi-904141530492
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039166; l=2387;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=3KVpiTKpwcDUtFqj7qJGHnJiAK8nWMpTrAP15XXF8ko=;
 b=WDhOMCdo75FVRq3OYDKThPlrywAC6GR+ayE7wD4HqoJ06+9vz7zpkYbw6VB2BhdxF2Tbikr/B
 HQy2rcdcIPLB+92GFXNt8sIo8leFABkoCWpnS2dc91YZKTY7YNn9raE
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

scpi_probe() stores scpi_info early because scpi_init_versions() sends
messages through it, and sets scpi_drvinfo->scpi_ops as its last step.
get_scpi_ops() returns scpi_info->scpi_ops, so the ops pointer is the
gate that scpi-cpufreq, scpi_pm_domain, clk-scpi and scpi-hwmon test
before they use the driver.

Both accesses to scpi_ops are plain, and a consumer that passes the gate
reads scpi_info->channels, ->commands, ->num_chans and
->protocol_version through a fresh load of scpi_info rather than through
the ops pointer. The version fields are written by scpi_init_versions()
after scpi_info was published, so a consumer on another CPU can see a
non-NULL scpi_ops together with stale versions.

Publish scpi_ops with smp_store_release() and read it with
smp_load_acquire() in get_scpi_ops().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/firmware/arm_scpi.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/drivers/firmware/arm_scpi.c b/drivers/firmware/arm_scpi.c
index 68a730d22..eaf8134d7 100644
--- a/drivers/firmware/arm_scpi.c
+++ b/drivers/firmware/arm_scpi.c
@@ -809,7 +809,10 @@ static struct scpi_ops scpi_ops = {
 
 struct scpi_ops *get_scpi_ops(void)
 {
-	return scpi_info ? scpi_info->scpi_ops : NULL;
+	struct scpi_drvinfo *info = READ_ONCE(scpi_info);
+
+	/* Pairs with the smp_store_release() of scpi_ops in scpi_probe(). */
+	return info ? smp_load_acquire(&info->scpi_ops) : NULL;
 }
 EXPORT_SYMBOL_GPL(get_scpi_ops);
 
@@ -1029,7 +1032,13 @@ static int scpi_probe(struct platform_device *pdev)
 			 FIELD_GET(FW_REV_PATCH_MASK,
 				   scpi_drvinfo->firmware_version));
 
-	scpi_drvinfo->scpi_ops = &scpi_ops;
+	/*
+	 * scpi_info is already visible (scpi_init_versions() needs it), so the
+	 * scpi_ops field is what get_scpi_ops() callers gate on. Publish it
+	 * with release semantics so that a consumer that sees the ops also
+	 * sees the channels, the command table and the version fields.
+	 */
+	smp_store_release(&scpi_drvinfo->scpi_ops, &scpi_ops);
 
 	ret = devm_of_platform_populate(dev);
 	if (ret)

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-arm-scpi-904141530492

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

