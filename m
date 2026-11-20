From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Date: Fri, 20 Nov 2026 09:05:46 +0100
Subject: [PATCH v2 2/3] wifi: wcn36xx: Do not enforce interrupt trigger
 type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-wcnss-series-v1-v2-2-3fed518decfb@atlr-engineering.com>
References: <20261120-wcnss-series-v1-v2-0-3fed518decfb@atlr-engineering.com>
In-Reply-To: <20261120-wcnss-series-v1-v2-0-3fed518decfb@atlr-engineering.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Luca Weiss <luca@lucaweiss.eu>, Eugene Krasnikov <k.eugene.e@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, wcn36xx@lists.infradead.org, 
 linux-wireless@vger.kernel.org, 
 Alexandre Rapaille <arapaille@atlr-engineering.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795161947; l=1310;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=fl24+QXJej14ixsS3PP+/Yde4CZKV/tbL7KavByENog=;
 b=jOVeRhQploDdl2usEZ5kRoAUO7AklsBT9dK43kVpb1jIaOBVKD3GKmgYmTUUsDNGa5PZKLwmu
 x0+dmbYMrPMBruIEGeq5p2t2SYrvYCDuQYwsi8Tx5yGBbQx71AY5Imz
X-Developer-Key: i=arapaille@atlr-engineering.com; a=ed25519;
 pk=xskH/sIiNU/aZCeGeBB1TK/AuiG3MXlX0m2wMlbMl08=
X-Endpoint-Received: by B4 Relay for arapaille@atlr-engineering.com/20261118 with auth_id=1560
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

request_irq() with IRQF_TRIGGER_HIGH stores level on the IRQ mapping,
which outlives the driver, so a DT with another type gets "type
mismatch" and -ENXIO on the next probe. Rely on the DT as ath10k does;
every in-tree qcom,wcnss-wlan node is level high (msm8974 since the
previous patch).

Signed-off-by: Alexandre Rapaille <arapaille@atlr-engineering.com>
---
 drivers/net/wireless/ath/wcn36xx/dxe.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/wcn36xx/dxe.c b/drivers/net/wireless/ath/wcn36xx/dxe.c
index 801f1218ef..7852f71368 100644
--- a/drivers/net/wireless/ath/wcn36xx/dxe.c
+++ b/drivers/net/wireless/ath/wcn36xx/dxe.c
@@ -552,14 +552,14 @@ static int wcn36xx_dxe_request_irqs(struct wcn36xx *wcn)
 {
 	int ret;
 
-	ret = request_irq(wcn->tx_irq, wcn36xx_irq_tx_complete,
-			  IRQF_TRIGGER_HIGH, "wcn36xx_tx", wcn);
+	ret = request_irq(wcn->tx_irq, wcn36xx_irq_tx_complete, 0,
+			  "wcn36xx_tx", wcn);
 	if (ret) {
 		wcn36xx_err("failed to alloc tx irq\n");
 		goto out_err;
 	}
 
-	ret = request_irq(wcn->rx_irq, wcn36xx_irq_rx_ready, IRQF_TRIGGER_HIGH,
+	ret = request_irq(wcn->rx_irq, wcn36xx_irq_rx_ready, 0,
 			  "wcn36xx_rx", wcn);
 	if (ret) {
 		wcn36xx_err("failed to alloc rx irq\n");

-- 
2.43.0

