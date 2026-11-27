From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:26:28 +0100
Subject: [PATCH 5/5] media: qcom: camss: csid-gen2: support plain 16-bit
 LSB RAW10 formats
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-camss-titan17x-fixes-v1-5-541ab39e5889@gmail.com>
References: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
In-Reply-To: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Andrey Konovalov <andrey.konovalov@linaro.org>, 
 Atanas Filipov <atanas.filipov@oss.qualcomm.com>, 
 Milen Mitkov <quic_mmitkov@quicinc.com>, 
 Gjorgji Rosikopulos <quic_grosikop@quicinc.com>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811183; l=2857;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=OWlbMqX8jFwDrOqApkzGhlVoUAPe5r3DiPbb52QR850=;
 b=hBozxEXAM7jf3vqt18NhHBdNwpzBWbqrHNSqcNsEdz+Zj443e+itwIY77vkCP21gWeHygp5Qm
 lBNSbo/njsODp8xkh0d0pjBkMlfEnRULe2CEPBHmAnZ88i8Z4rX3ik1
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

csid_src_pad_code() and vfe_formats_rdi_845 already expose
MEDIA_BUS_FMT_SBGGR10_2X8_PADHI_LE and MEDIA_BUS_FMT_Y10_2X8_PADHI_LE
for unpacked 16-bit RAW10 capture, but formats_gen2[] omitted both
codes and __csid_configure_rdi_stream() unconditionally configured
DECODE_FORMAT_PAYLOAD_ONLY.

Add both PADHI_LE formats to formats_gen2[] and configure
DECODE_FORMAT_UNCOMPRESSED_10_BIT with PLAIN_FORMAT_PLAIN16 and
PLAIN_ALIGNMENT_LSB in __csid_configure_rdi_stream() when selected.

Fixes: 729fc005c8e2 ("media: qcom: camss: Split testgen, RDI and RX for CSID 170")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-csid-gen2.c | 11 +++++++++--
 drivers/media/platform/qcom/camss/camss-csid.c      | 14 ++++++++++++++
 2 files changed, 23 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-gen2.c b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
index 44c6c214f50be13dfbb8ba5d9e2e16964ded9ef6..de9e2a3191448c617a4c732edbba346bf9eb5673 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-gen2.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
@@ -282,8 +282,15 @@ static void __csid_configure_rdi_stream(struct csid_device *csid, bool enable,
 	val = 1 << RDI_CFG0_BYTE_CNTR_EN;
 	val |= 1 << RDI_CFG0_FORMAT_MEASURE_EN;
 	val |= 1 << RDI_CFG0_TIMESTAMP_EN;
-	/* note: for non-RDI path, this should be format->decode_format */
-	val |= DECODE_FORMAT_PAYLOAD_ONLY << RDI_CFG0_DECODE_FORMAT;
+	if (input_format->code == MEDIA_BUS_FMT_SBGGR10_2X8_PADHI_LE ||
+	    input_format->code == MEDIA_BUS_FMT_Y10_2X8_PADHI_LE) {
+		val |= format->decode_format << RDI_CFG0_DECODE_FORMAT;
+		val |= PLAIN_FORMAT_PLAIN16 << RDI_CFG0_PLAIN_FORMAT;
+		val |= PLAIN_ALIGNMENT_LSB << RDI_CFG0_PLAIN_ALIGNMENT;
+	} else {
+		/* note: for non-RDI path, this should be format->decode_format */
+		val |= DECODE_FORMAT_PAYLOAD_ONLY << RDI_CFG0_DECODE_FORMAT;
+	}
 	val |= format->data_type << RDI_CFG0_DATA_TYPE;
 	val |= vc << RDI_CFG0_VIRTUAL_CHANNEL;
 	val |= dt_id << RDI_CFG0_DT_ID;
diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index 123c097ee54bfdcafbba02a6c01f51c545bf472e..12ffa438284806bc37fd150ca0e4c74d0706d2d1 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -424,6 +424,20 @@ static const struct csid_format_info formats_gen2[] = {
 		10,
 		1,
 	},
+	{
+		MEDIA_BUS_FMT_Y10_2X8_PADHI_LE,
+		MIPI_CSI2_DT_RAW10,
+		DECODE_FORMAT_UNCOMPRESSED_10_BIT,
+		16,
+		1,
+	},
+	{
+		MEDIA_BUS_FMT_SBGGR10_2X8_PADHI_LE,
+		MIPI_CSI2_DT_RAW10,
+		DECODE_FORMAT_UNCOMPRESSED_10_BIT,
+		16,
+		1,
+	},
 	{
 		MEDIA_BUS_FMT_SBGGR12_1X12,
 		MIPI_CSI2_DT_RAW12,

-- 
2.47.3

