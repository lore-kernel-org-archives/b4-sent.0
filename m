From: Renjiang Han <quic_renjiang@quicinc.com>
Date: Tue, 08 Oct 2024 16:46:35 +0530
Subject: [PATCH 2/2] media: venus: core: add qcs615 DT compatible and
 resource data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241008-add_qcs615_video-v1-2-436ce07bfc63@quicinc.com>
References: <20241008-add_qcs615_video-v1-0-436ce07bfc63@quicinc.com>
In-Reply-To: <20241008-add_qcs615_video-v1-0-436ce07bfc63@quicinc.com>
To: Vikash Garodia <quic_vgarodia@quicinc.com>
Cc: kernel@quicinc.com, Renjiang Han <quic_renjiang@quicinc.com>, 
 linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728386222; l=2818;
 i=quic_renjiang@quicinc.com; s=20241001; h=from:subject:message-id;
 bh=Q1QnwhQAJxUdLqNUWY5OfIjtDJPFF3bmncn+F/o0I3w=;
 b=UGUYGtdz5GtJdTQknjM76kY2aiYDm2kzYiE4VWQ2FIpDaYLv2vooBZa8aWysbgyhawB8HEa/8
 n/1VWGGsy8EB+1ZgwxHlB3DSwUAVydTDvY7NcxrRLsr/vCvwwLJCru0
X-Developer-Key: i=quic_renjiang@quicinc.com; a=ed25519;
 pk=8N59kMJUiVH++5QxJzTyHB/wh/kG5LxQ44j9zhUvZmw=
X-Endpoint-Received: by B4 Relay for quic_renjiang@quicinc.com/20241001 with auth_id=235
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add qcs615 DT compatible and resource data

Change-Id: I1a06f105f030cbf16f48a32f8c50c814f0dbde7a
Signed-off-by: Renjiang Han <quic_renjiang@quicinc.com>
---
 drivers/media/platform/qcom/venus/core.c | 50 ++++++++++++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/drivers/media/platform/qcom/venus/core.c b/drivers/media/platform/qcom/venus/core.c
index 84e95a46dfc9832981ac1c0c58e226a506896ade..15cd78279cb7487f5f1da4e5d617da7b4a481451 100644
--- a/drivers/media/platform/qcom/venus/core.c
+++ b/drivers/media/platform/qcom/venus/core.c
@@ -816,6 +816,55 @@ static const struct venus_resources sc7180_res = {
 	.fwname = "qcom/venus-5.4/venus.mbn",
 };
 
+static const struct freq_tbl qcs615_freq_table[] = {
+	{ 0, 460000000 },
+	{ 0, 410000000 },
+	{ 0, 380000000 },
+	{ 0, 300000000 },
+	{ 0, 240000000 },
+	{ 0, 133333333 },
+};
+
+static const struct bw_tbl qcs615_bw_table_enc[] = {
+	{  972000,  951000, 0, 1434000, 0 },	/* 3840x2160@30 */
+	{  489600,  723000, 0,  973000, 0 },	/* 1920x1080@60 */
+	{  244800,  370000, 0,	495000, 0 },	/* 1920x1080@30 */
+};
+
+static const struct bw_tbl qcs615_bw_table_dec[] = {
+	{ 1036800, 1987000, 0, 2797000, 0 },	/* 4096x2160@30 */
+	{  489600, 1040000, 0, 1298000, 0 },	/* 1920x1080@60 */
+	{  244800,  530000, 0,  659000, 0 },	/* 1920x1080@30 */
+};
+
+static const struct venus_resources qcs615_res = {
+	.freq_tbl = qcs615_freq_table,
+	.freq_tbl_size = ARRAY_SIZE(qcs615_freq_table),
+	.bw_tbl_enc = qcs615_bw_table_enc,
+	.bw_tbl_enc_size = ARRAY_SIZE(qcs615_bw_table_enc),
+	.bw_tbl_dec = qcs615_bw_table_dec,
+	.bw_tbl_dec_size = ARRAY_SIZE(qcs615_bw_table_dec),
+	.clks = {"core", "iface", "bus"},
+	.clks_num = 3,
+	.vcodec0_clks = {"vcodec0_core", "vcodec0_bus"},
+	.vcodec_clks_num = 2,
+	.vcodec_pmdomains = (const char *[]) { "venus", "vcodec0" },
+	.vcodec_pmdomains_num = 2,
+	.opp_pmdomain = (const char *[]) { "cx", NULL },
+	.vcodec_num = 1,
+	.hfi_version = HFI_VERSION_4XX,
+	.vpu_version = VPU_VERSION_AR50,
+	.vmem_id = VIDC_RESOURCE_NONE,
+	.vmem_size = 0,
+	.vmem_addr = 0,
+	.dma_mask = 0xe0000000 - 1,
+	.cp_start = 0,
+	.cp_size = 0x70800000,
+	.cp_nonpixel_start = 0x1000000,
+	.cp_nonpixel_size = 0x24800000,
+	.fwname = "qcom/venus-5.4/venus.mbn",
+};
+
 static const struct freq_tbl sm8250_freq_table[] = {
 	{ 0, 444000000 },
 	{ 0, 366000000 },
@@ -943,6 +992,7 @@ static const struct of_device_id venus_dt_match[] = {
 	{ .compatible = "qcom,sc7180-venus", .data = &sc7180_res, },
 	{ .compatible = "qcom,sc7280-venus", .data = &sc7280_res, },
 	{ .compatible = "qcom,sm8250-venus", .data = &sm8250_res, },
+	{ .compatible = "qcom,qcs615-venus", .data = &qcs615_res, },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, venus_dt_match);

-- 
2.34.1

