From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 11 Sep 2026 20:18:49 +0200
Subject: [PATCH 3/4] common: Add Android bootloader parameter parsing
 helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-b4-android-bootargs-carryover-v1-3-6ebb43da3df0@protonmail.com>
References: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
In-Reply-To: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Simon Glass <sjg@chromium.org>, Kory Maincent <kory.maincent@bootlin.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Markus Niebel <Markus.Niebel@ew.tq-group.com>, 
 Alexey Charkov <alchark@gmail.com>, Heiko Schocher <hs@nabladev.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Anshul Dalal <anshuld@ti.com>, Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789150739; l=4609;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=ADTW9ak8hL9UuOnFKO7/IuU053qw6uSflnja4Upt8cc=;
 b=38dag9Zqw3SzsOnZ8PnlGY0aPm1TZwwnmb2ssJQi20si20oTXqXLOaZLE1HxNICtQPCGlFIu7
 BKRRxhzUrqCBUYiipJzLd7UlXlxB8UlsQalQLsMzQ/OnWkAtOwl2hII
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a convenience wrapper for parsing common Android bootloader
parameters from the kernel command line. This simplifies extracting
the numerous androidboot.* parameters used in Android systems.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 include/cmdline_utils.h | 32 +++++++++++++++++++
 lib/cmdline_utils.c     | 85 +++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 117 insertions(+)

diff --git a/include/cmdline_utils.h b/include/cmdline_utils.h
index fa6e20b2417..af9b5226dab 100644
--- a/include/cmdline_utils.h
+++ b/include/cmdline_utils.h
@@ -25,4 +25,36 @@ struct cmdline_mask_param {
 
 char *mask_cmdline_params(const char *cmdline, struct cmdline_mask_param *params, int count);
 
+struct androidboot_params {
+	char *hardware_ddr;
+	char *ddr_info;
+	char *ddr_size;
+
+	char *dsi_display0;
+
+	char *slot_suffix;
+	char *slot_retry_count;
+	char *slot_successful;
+
+	char *hardware_platform;
+	char *hardware;
+	char *revision;
+	char *hardware_sku;
+	char *hardware_majorid;
+
+	char *bootloader;
+	char *bootreason;
+	char *secure_boot;
+	char *mode;
+
+	char *cdt_hwid;
+	char *dtb_idx;
+
+	char *serialno;
+};
+
+int parse_androidboot_params(const char *cmdline, struct androidboot_params *params);
+
+void free_androidboot_params(struct androidboot_params *params);
+
 #endif /* _CMDLINE_UTILS_H_ */
diff --git a/lib/cmdline_utils.c b/lib/cmdline_utils.c
index 4355bdd45f4..f8fe5e79bb9 100644
--- a/lib/cmdline_utils.c
+++ b/lib/cmdline_utils.c
@@ -244,3 +244,88 @@ char *mask_cmdline_params(const char *cmdline, struct cmdline_mask_param *params
 	*dst_pos = '\0';
 	return result;
 }
+
+int parse_androidboot_params(const char *cmdline, struct androidboot_params *params)
+{
+	struct cmdline_param cmdline_params[] = {
+		{"androidboot.hardware.ddr", NULL, 0},
+		{"androidboot.ddr_info", NULL, 0},
+		{"androidboot.ddr_size", NULL, 0},
+		{"msm_drm.dsi_display0", NULL, 0},
+		{"androidboot.slot_suffix", NULL, 0},
+		{"androidboot.slot_retry_count", NULL, 0},
+		{"androidboot.slot_successful", NULL, 0},
+		{"androidboot.hardware.platform", NULL, 0},
+		{"androidboot.hardware", NULL, 0},
+		{"androidboot.revision", NULL, 0},
+		{"androidboot.bootloader", NULL, 0},
+		{"androidboot.hardware.sku", NULL, 0},
+		{"androidboot.secure_boot", NULL, 0},
+		{"androidboot.cdt_hwid", NULL, 0},
+		{"androidboot.hardware.majorid", NULL, 0},
+		{"androidboot.dtb_idx", NULL, 0},
+		{"androidboot.mode", NULL, 0},
+		{"androidboot.bootreason", NULL, 0},
+		{"androidboot.serialno", NULL, 0},
+	};
+	int ret, count = ARRAY_SIZE(cmdline_params);
+
+	if (!cmdline || !params)
+		return -EINVAL;
+
+	memset(params, 0, sizeof(struct androidboot_params));
+
+	ret = parse_cmdline_params(cmdline, cmdline_params, count);
+	if (ret < 0)
+		return ret;
+
+	params->hardware_ddr = cmdline_params[0].value;
+	params->ddr_info = cmdline_params[1].value;
+	params->ddr_size = cmdline_params[2].value;
+	params->dsi_display0 = cmdline_params[3].value;
+	params->slot_suffix = cmdline_params[4].value;
+	params->slot_retry_count = cmdline_params[5].value;
+	params->slot_successful = cmdline_params[6].value;
+	params->hardware_platform = cmdline_params[7].value;
+	params->hardware = cmdline_params[8].value;
+	params->revision = cmdline_params[9].value;
+	params->bootloader = cmdline_params[10].value;
+	params->hardware_sku = cmdline_params[11].value;
+	params->secure_boot = cmdline_params[12].value;
+	params->cdt_hwid = cmdline_params[13].value;
+	params->hardware_majorid = cmdline_params[14].value;
+	params->dtb_idx = cmdline_params[15].value;
+	params->mode = cmdline_params[16].value;
+	params->bootreason = cmdline_params[17].value;
+	params->serialno = cmdline_params[18].value;
+
+	return 0;
+}
+
+void free_androidboot_params(struct androidboot_params *params)
+{
+	if (!params)
+		return;
+
+	free(params->hardware_ddr);
+	free(params->ddr_info);
+	free(params->ddr_size);
+	free(params->dsi_display0);
+	free(params->slot_suffix);
+	free(params->slot_retry_count);
+	free(params->slot_successful);
+	free(params->hardware_platform);
+	free(params->hardware);
+	free(params->revision);
+	free(params->bootloader);
+	free(params->hardware_sku);
+	free(params->secure_boot);
+	free(params->cdt_hwid);
+	free(params->hardware_majorid);
+	free(params->dtb_idx);
+	free(params->mode);
+	free(params->bootreason);
+	free(params->serialno);
+
+	memset(params, 0, sizeof(struct androidboot_params));
+}

-- 
2.55.0

