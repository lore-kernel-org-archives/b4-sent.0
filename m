From: Demeter Barna <me@fromdisposition.org>
Date: Thu, 05 Nov 2026 13:30:02 +0000
Subject: [PATCH 3/5] nvmem: qfprom: Add the SM8350 keepout regions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-b4-sm8350-gpu-v1-3-a7175cdd6512@fromdisposition.org>
References: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
In-Reply-To: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885419; l=1841;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=CDGO3hvRW7mymx++dDNgiaLDX/wtQ9qU8oYZYFNQPZ4=;
 b=fWovVqQLQJoPFa5Mc+441Nuesv3cWVgzRKAID6ngbH8CEfzc2VFXlf9TNCgPEeqS12fu0exvC
 beHxHlr/rgDBTDCVwwmp4H5SpWalxQsTkMBKlmQb3Ra/PQJiXiNoqs3
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some SM8350 fuse ranges are protected by the XPU, so the AP cannot read
them: a read in 0x0-0x11f, 0x128-0x147, 0x640-0x8df or 0x2110-0x216f
resets the SoC. The nvmem file in sysfs is readable by every user, so
once the QFPROM is described, anyone who reads the whole file resets the
device.

Keep those regions out, as for SC7180 and SC7280, which share the
0x128-0x147 one; they read as zeros.

The regions were measured on a Razer Edge 5G one 32-bit word at a time,
and each boundary was checked from both sides.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/nvmem/qfprom.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/nvmem/qfprom.c b/drivers/nvmem/qfprom.c
index 1de3435df..24958ed79 100644
--- a/drivers/nvmem/qfprom.c
+++ b/drivers/nvmem/qfprom.c
@@ -124,6 +124,18 @@ static const struct qfprom_soc_compatible_data sc7280_qfprom = {
 	.nkeepout = ARRAY_SIZE(sc7280_qfprom_keepout)
 };
 
+static const struct nvmem_keepout sm8350_qfprom_keepout[] = {
+	{.start = 0x0, .end = 0x120},
+	{.start = 0x128, .end = 0x148},
+	{.start = 0x640, .end = 0x8e0},
+	{.start = 0x2110, .end = 0x2170}
+};
+
+static const struct qfprom_soc_compatible_data sm8350_qfprom = {
+	.keepout = sm8350_qfprom_keepout,
+	.nkeepout = ARRAY_SIZE(sm8350_qfprom_keepout)
+};
+
 /**
  * qfprom_disable_fuse_blowing() - Undo enabling of fuse blowing.
  * @priv: Our driver data.
@@ -460,6 +472,7 @@ static const struct of_device_id qfprom_of_match[] = {
 	{ .compatible = "qcom,qfprom",},
 	{ .compatible = "qcom,sc7180-qfprom", .data = &sc7180_qfprom},
 	{ .compatible = "qcom,sc7280-qfprom", .data = &sc7280_qfprom},
+	{ .compatible = "qcom,sm8350-qfprom", .data = &sm8350_qfprom},
 	{/* sentinel */},
 };
 MODULE_DEVICE_TABLE(of, qfprom_of_match);

-- 
2.53.0

