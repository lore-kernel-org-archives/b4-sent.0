From: Larisa Grigore <larisa.grigore@oss.nxp.com>
Date: Sat, 14 Nov 2026 12:55:41 +0100
Subject: [PATCH v11 09/14] ufs: dwc: Move shared M-PHY CR bitfield macros
 to ufshcd-dwc.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-ufs-s32n7-v11-9-dc36e11919d5@oss.nxp.com>
References: <20261114-b4-ufs-s32n7-v11-0-dc36e11919d5@oss.nxp.com>
In-Reply-To: <20261114-b4-ufs-s32n7-v11-0-dc36e11919d5@oss.nxp.com>
To: "Martin K. Petersen" <mkp@kernel.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Bart Van Assche <bvanassche@acm.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Rob Herring <robh@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>
Cc: devicetree@vger.kernel.org, Ajay Neeli <ajay.neeli@amd.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, linux-arm-msm@vger.kernel.org, 
 Peter Wang <peter.wang@mediatek.com>, linux-kernel@vger.kernel.org, 
 NXP S32 Linux Team <s32@nxp.com>, Asutosh Das <quic_asutoshd@quicinc.com>, 
 linux-arm-kernel@lists.infradead.org, Stanley Jhu <stanleyjhu@google.com>, 
 Frank Li <Frank.Li@nxp.com>, imx@lists.linux.dev, 
 linux-scsi@vger.kernel.org, Bean Huo <beanhuo@micron.com>, 
 linux-mediatek@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Pedro Sousa <pedrom.sousa@synopsys.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, eballetb@redhat.com, 
 Peter Griffin <peter.griffin@linaro.org>, echanude@redhat.com, 
 Chaotian Jing <chaotian.jing@mediatek.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>, 
 Sai Krishna Potthuri <sai.krishna.potthuri@amd.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, linux-rockchip@lists.infradead.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, clizzi@redhat.com, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Heiko Stuebner <heiko@sntech.de>, Matthias Brugger <matthias.bgg@gmail.com>, 
 Chunyan Zhang <zhang.lyra@gmail.com>, Can Guo <can.guo@oss.qualcomm.com>, 
 Orson Zhai <orsonzhai@gmail.com>, aruizrui@redhat.com, 
 linux-renesas-soc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794657370; l=1821;
 i=larisa.grigore@oss.nxp.com; s=20261114; h=from:subject:message-id;
 bh=JX2nsOabUy/TBGxhVK8w2TevyQp3cyFlyb2qe5sxI0A=;
 b=Fu0qGYjnE491KcaphLwzl6jBvpI8aINDS+ArWpneGGfhkK5KZuFvjmnMAB9ntT3OqYJIyWG7W
 tKG48vuTXGAADdc/rukgP8Jhq8bCxTikVSGDwCsvCJtMm3N+AHde+bm
X-Developer-Key: i=larisa.grigore@oss.nxp.com; a=ed25519;
 pk=Jpt52sb6ETKTtvWjUzhz5Sv5FjB9AEg9QKCcbpWFx3w=
X-Endpoint-Received: by B4 Relay for larisa.grigore@oss.nxp.com/20261114 with auth_id=1522
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bitfields of the FAST_FLAGS, FW_CALIB_CCFG, RX_OVRD_IN_1 and
RX_PCS_OUT M-PHY registers are defined in the AMD Versal2 driver, while
the register offsets themselves are already in ufshcd-dwc.h.

Move the bitfield macros next to the register offsets so other DWC based
drivers can program these registers without using raw values.

No functional change.

Signed-off-by: Larisa Grigore <larisa.grigore@oss.nxp.com>
---
 drivers/ufs/host/ufs-amd-versal2.c |  7 -------
 drivers/ufs/host/ufshcd-dwc.h      | 13 +++++++++++++
 2 files changed, 13 insertions(+), 7 deletions(-)

diff --git a/drivers/ufs/host/ufs-amd-versal2.c b/drivers/ufs/host/ufs-amd-versal2.c
index 4d6e08ac6ced..dcca6be5dad0 100644
--- a/drivers/ufs/host/ufs-amd-versal2.c
+++ b/drivers/ufs/host/ufs-amd-versal2.c
@@ -22,13 +22,6 @@
 /* PHY modes */
 #define UFSHCD_DWC_PHY_MODE_ROM         0
 
-#define MPHY_FAST_RX_AFE_CAL		BIT(2)
-#define MPHY_FW_CALIB_CFG_VAL		BIT(8)
-
-#define MPHY_RX_OVRD_EN			BIT(3)
-#define MPHY_RX_OVRD_VAL		BIT(2)
-#define MPHY_RX_ACK_MASK		BIT(0)
-
 #define TIMEOUT_MICROSEC	1000000
 
 struct ufs_versal2_host {
diff --git a/drivers/ufs/host/ufshcd-dwc.h b/drivers/ufs/host/ufshcd-dwc.h
index 1abf2b1deac4..a76009b42088 100644
--- a/drivers/ufs/host/ufshcd-dwc.h
+++ b/drivers/ufs/host/ufshcd-dwc.h
@@ -35,6 +35,19 @@
 #define RX_AFE_CTLE_IDAC(n)	(0x4001 + ((n) * 0x100))
 #define FW_CALIB_CCFG(n)	(0x404D + ((n) * 0x100))
 
+/* RX_OVRD_IN_1 */
+#define MPHY_RX_OVRD_EN			BIT(3)
+#define MPHY_RX_OVRD_VAL		BIT(2)
+
+/* RX_PCS_OUT */
+#define MPHY_RX_ACK_MASK		BIT(0)
+
+/* FAST_FLAGS */
+#define MPHY_FAST_RX_AFE_CAL		BIT(2)
+
+/* FW_CALIB_CCFG */
+#define MPHY_FW_CALIB_CFG_VAL		BIT(8)
+
 struct ufshcd_dme_attr_val {
 	u32 attr_sel;
 	u32 mib_val;

-- 
2.43.0

