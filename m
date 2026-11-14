From: Larisa Grigore <larisa.grigore@oss.nxp.com>
Date: Sat, 14 Nov 2026 12:55:40 +0100
Subject: [PATCH v11 08/14] ufs: dwc: Sort CBCRCTRL and CBREFCLKCTRL2 by
 offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-ufs-s32n7-v11-8-dc36e11919d5@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794657370; l=1160;
 i=larisa.grigore@oss.nxp.com; s=20261114; h=from:subject:message-id;
 bh=jFPb09TEw+o0co3IKimWFQwdujSqoSGN2BKqE5DQhEI=;
 b=ixpsDc5UGD5DMWn3XWZWIo71JIdLStTqgwVuwD42MliFUu4v4d8dPwsTNw9xryPPVqxhBXeFW
 B+Cnmgy6MATB1HDgNV7Osmu4wXB0v9u16j7fle2yFFwau9gIp59++8f
X-Developer-Key: i=larisa.grigore@oss.nxp.com; a=ed25519;
 pk=Jpt52sb6ETKTtvWjUzhz5Sv5FjB9AEg9QKCcbpWFx3w=
X-Endpoint-Received: by B4 Relay for larisa.grigore@oss.nxp.com/20261114 with auth_id=1522
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RMMI attribute defines in ufshcd-dwc.h are otherwise listed in
ascending register-offset order, but CBREFCLKCTRL2 (0x8132) and
CBCRCTRL (0x811F) were placed at the top out of order. Move them down
into their sorted position next to the other CBCREG* attributes.

Pure cleanup, no functional change.

Signed-off-by: Larisa Grigore <larisa.grigore@oss.nxp.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
---
 drivers/ufs/host/ufshcd-dwc.h | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/ufs/host/ufshcd-dwc.h b/drivers/ufs/host/ufshcd-dwc.h
index 53b523ef59df..1abf2b1deac4 100644
--- a/drivers/ufs/host/ufshcd-dwc.h
+++ b/drivers/ufs/host/ufshcd-dwc.h
@@ -13,8 +13,6 @@
 #include <ufs/ufshcd.h>
 
 /* RMMI Attributes */
-#define CBREFCLKCTRL2		0x8132
-#define CBCRCTRL		0x811F
 #define CBC10DIRECTCONF2	0x810E
 #define CBRATESEL		0x8114
 #define CBCREGADDRLSB		0x8116
@@ -24,6 +22,8 @@
 #define CBCREGRDLSB		0x811A
 #define CBCREGRDMSB		0x811B
 #define CBCREGRDWRSEL		0x811C
+#define CBCRCTRL		0x811F
+#define CBREFCLKCTRL2		0x8132
 
 #define CBREFREFCLK_GATE_OVR_EN		BIT(7)
 

-- 
2.43.0

