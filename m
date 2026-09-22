From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 20:28:17 -0400
Subject: [PATCH] firmware: imx: sm: publish the protocol handle after the
 ops pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-imx-sm-v1-1-39f17526d253@vt.edu>
X-B4-Tracking: v=1; b=H4sIAKDLsWoC/yXMywrCMBCF4Vcps3YkSY23VxEXSRztCIkyo6VQ+
 u4mdfkdDv8MSsKkcO5mEBpZ+VUq7KaDNITyIORbNTjj9ubkLOaInCfUjNH0R0rkvfUO6v8tdOd
 pbV2uf+s3Pil9WqA9YlDCKKGkoU0rx8O2R0k7WJYfL32Z2Y0AAAA=
X-Change-ID: 20260921-mb-imx-sm-b038ece55152
To: Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790036919; l=7699;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=MVi9AlTKi2qUQtZyArCJT4Gbtet0T4epZvMQSbFRRLc=;
 b=+HX5ho3X6G6TKmcmVBZqXdSKnvD/ZBoZe11QNj4rKhZp1o9Gt9MLVR53YC6JnddxMrPp+KFMa
 4bHBzgek/MABfU/R5+nDtB/2NNSaS7rt7j3JJIdrYX7G8iCKFEasN94
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sm-cpu, sm-lmm and sm-misc export helpers such as scmi_imx_cpu_start()
and scmi_imx_lmm_info() to imx_rproc, fsl_sai and the i.MX SOF driver.
Each helper gates on the file-scope protocol handle:

	if (!ph)
		return -EPROBE_DEFER;
	return imx_cpu_ops->cpu_start(ph, ...);

The probe functions set both globals in one statement:

	imx_cpu_ops = handle->devm_protocol_get(sdev, ..., &ph);

scmi_devm_protocol_get() stores *ph before it returns, so the gate
becomes non-NULL before the ops pointer it guards is written. A consumer
that passes the gate in that window dereferences imx_cpu_ops == NULL.
Nothing orders the two stores for a reader either: the writer has no
release, the reader has no acquire, and the load of imx_cpu_ops does not
depend on the value of ph.

Take the handle into a local, assign the ops pointer first and publish
the handle with smp_store_release(). Read it with smp_load_acquire() in
the exported helpers.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/firmware/imx/sm-cpu.c  | 24 ++++++++++++++++++------
 drivers/firmware/imx/sm-lmm.c  | 24 ++++++++++++++++++------
 drivers/firmware/imx/sm-misc.c | 24 ++++++++++++++++++------
 3 files changed, 54 insertions(+), 18 deletions(-)

diff --git a/drivers/firmware/imx/sm-cpu.c b/drivers/firmware/imx/sm-cpu.c
index 091b014f7..60ba700d0 100644
--- a/drivers/firmware/imx/sm-cpu.c
+++ b/drivers/firmware/imx/sm-cpu.c
@@ -16,7 +16,8 @@ static struct scmi_protocol_handle *ph;
 int scmi_imx_cpu_reset_vector_set(u32 cpuid, u64 vector, bool start, bool boot,
 				  bool resume)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	return imx_cpu_ops->cpu_reset_vector_set(ph, cpuid, vector, start,
@@ -26,7 +27,8 @@ EXPORT_SYMBOL(scmi_imx_cpu_reset_vector_set);
 
 int scmi_imx_cpu_start(u32 cpuid, bool start)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	if (start)
@@ -38,7 +40,8 @@ EXPORT_SYMBOL(scmi_imx_cpu_start);
 
 int scmi_imx_cpu_started(u32 cpuid, bool *started)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	if (!started)
@@ -51,6 +54,8 @@ EXPORT_SYMBOL(scmi_imx_cpu_started);
 static int scmi_imx_cpu_probe(struct scmi_device *sdev)
 {
 	const struct scmi_handle *handle = sdev->handle;
+	const struct scmi_imx_cpu_proto_ops *ops;
+	struct scmi_protocol_handle *cpu_ph;
 
 	if (!handle)
 		return -ENODEV;
@@ -60,9 +65,16 @@ static int scmi_imx_cpu_probe(struct scmi_device *sdev)
 		return -EEXIST;
 	}
 
-	imx_cpu_ops = handle->devm_protocol_get(sdev, SCMI_PROTOCOL_IMX_CPU, &ph);
-	if (IS_ERR(imx_cpu_ops))
-		return PTR_ERR(imx_cpu_ops);
+	ops = handle->devm_protocol_get(sdev, SCMI_PROTOCOL_IMX_CPU, &cpu_ph);
+	if (IS_ERR(ops))
+		return PTR_ERR(ops);
+
+	imx_cpu_ops = ops;
+	/*
+	 * ph is the gate the exported helpers test. Publish it only after
+	 * imx_cpu_ops is set, and pair with the smp_load_acquire() there.
+	 */
+	smp_store_release(&ph, cpu_ph);
 
 	return 0;
 }
diff --git a/drivers/firmware/imx/sm-lmm.c b/drivers/firmware/imx/sm-lmm.c
index 6807bf563..0e2cc7153 100644
--- a/drivers/firmware/imx/sm-lmm.c
+++ b/drivers/firmware/imx/sm-lmm.c
@@ -15,7 +15,8 @@ static struct scmi_protocol_handle *ph;
 
 int scmi_imx_lmm_info(u32 lmid, struct scmi_imx_lmm_info *info)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	if (!info)
@@ -27,7 +28,8 @@ EXPORT_SYMBOL(scmi_imx_lmm_info);
 
 int scmi_imx_lmm_reset_vector_set(u32 lmid, u32 cpuid, u32 flags, u64 vector)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	return imx_lmm_ops->lmm_reset_vector_set(ph, lmid, cpuid, flags, vector);
@@ -36,7 +38,8 @@ EXPORT_SYMBOL(scmi_imx_lmm_reset_vector_set);
 
 int scmi_imx_lmm_operation(u32 lmid, enum scmi_imx_lmm_op op, u32 flags)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	switch (op) {
@@ -57,6 +60,8 @@ EXPORT_SYMBOL(scmi_imx_lmm_operation);
 static int scmi_imx_lmm_probe(struct scmi_device *sdev)
 {
 	const struct scmi_handle *handle = sdev->handle;
+	const struct scmi_imx_lmm_proto_ops *ops;
+	struct scmi_protocol_handle *lmm_ph;
 
 	if (!handle)
 		return -ENODEV;
@@ -66,9 +71,16 @@ static int scmi_imx_lmm_probe(struct scmi_device *sdev)
 		return -EEXIST;
 	}
 
-	imx_lmm_ops = handle->devm_protocol_get(sdev, SCMI_PROTOCOL_IMX_LMM, &ph);
-	if (IS_ERR(imx_lmm_ops))
-		return PTR_ERR(imx_lmm_ops);
+	ops = handle->devm_protocol_get(sdev, SCMI_PROTOCOL_IMX_LMM, &lmm_ph);
+	if (IS_ERR(ops))
+		return PTR_ERR(ops);
+
+	imx_lmm_ops = ops;
+	/*
+	 * ph is the gate the exported helpers test. Publish it only after
+	 * imx_lmm_ops is set, and pair with the smp_load_acquire() there.
+	 */
+	smp_store_release(&ph, lmm_ph);
 
 	return 0;
 }
diff --git a/drivers/firmware/imx/sm-misc.c b/drivers/firmware/imx/sm-misc.c
index fb8d7bdb5..178a3f748 100644
--- a/drivers/firmware/imx/sm-misc.c
+++ b/drivers/firmware/imx/sm-misc.c
@@ -43,7 +43,8 @@ static const struct of_device_id allowlist[] = {
 
 int scmi_imx_misc_ctrl_set(u32 id, u32 val)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	return imx_misc_ctrl_ops->misc_ctrl_set(ph, id, 1, &val);
@@ -52,7 +53,8 @@ EXPORT_SYMBOL(scmi_imx_misc_ctrl_set);
 
 int scmi_imx_misc_ctrl_get(u32 id, u32 *num, u32 *val)
 {
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -EPROBE_DEFER;
 
 	return imx_misc_ctrl_ops->misc_ctrl_get(ph, id, num, val);
@@ -82,7 +84,8 @@ static int syslog_show(struct seq_file *file, void *priv)
 	if (!syslog)
 		return -ENOMEM;
 
-	if (!ph)
+	/* Pairs with the smp_store_release() in the probe function. */
+	if (!smp_load_acquire(&ph))
 		return -ENODEV;
 
 	ret = imx_misc_ctrl_ops->misc_syslog(ph, &size, syslog);
@@ -153,6 +156,8 @@ static int scmi_imx_misc_ctrl_probe(struct scmi_device *sdev)
 {
 	const struct scmi_handle *handle = sdev->handle;
 	struct device_node *np = sdev->dev.of_node;
+	const struct scmi_imx_misc_proto_ops *ops;
+	struct scmi_protocol_handle *misc_ph;
 	struct dentry *scmi_imx_dentry;
 	u32 src_id, flags;
 	int ret, i, num;
@@ -165,9 +170,16 @@ static int scmi_imx_misc_ctrl_probe(struct scmi_device *sdev)
 		return -EEXIST;
 	}
 
-	imx_misc_ctrl_ops = handle->devm_protocol_get(sdev, SCMI_PROTOCOL_IMX_MISC, &ph);
-	if (IS_ERR(imx_misc_ctrl_ops))
-		return PTR_ERR(imx_misc_ctrl_ops);
+	ops = handle->devm_protocol_get(sdev, SCMI_PROTOCOL_IMX_MISC, &misc_ph);
+	if (IS_ERR(ops))
+		return PTR_ERR(ops);
+
+	imx_misc_ctrl_ops = ops;
+	/*
+	 * ph is the gate the exported helpers test. Publish it only after
+	 * imx_misc_ctrl_ops is set, and pair with the smp_load_acquire() there.
+	 */
+	smp_store_release(&ph, misc_ph);
 
 	num = of_property_count_u32_elems(np, "nxp,ctrl-ids");
 	if (num % 2) {

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-imx-sm-b038ece55152

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

