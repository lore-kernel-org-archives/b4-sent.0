From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Date: Wed, 18 Nov 2026 15:58:00 +0100
Subject: [PATCH 2/3] wifi: wcn36xx: Do not enforce interrupt trigger type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-wcnss-series-v1-v1-2-a64d82e151bf@atlr-engineering.com>
References: <20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com>
In-Reply-To: <20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795013892; l=1329;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=khOZHEXRcSQmbq7KDArufnHPyg+ogBAkMuAIzDyD5GI=;
 b=nII4Tr6E80HN1n9xJCpvsfRQtm3voa4KEvn2sUb3dTDXcNFbHiKQ1Jq+Xa7RgMMY+0XXn1unX
 8swV0TgKt1hB9hMZ9nFdCy06x0CvWp/RXPAMmDJqGYkbiJHEgW3AC9T
X-Developer-Key: i=arapaille@atlr-engineering.com; a=ed25519;
 pk=xskH/sIiNU/aZCeGeBB1TK/AuiG3MXlX0m2wMlbMl08=
X-Endpoint-Received: by B4 Relay for arapaille@atlr-engineering.com/20261118 with auth_id=1560
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Forcing IRQF_TRIGGER_HIGH over the DT type makes the re-probe after a WCNSS
restart fail ("type mismatch, failed to map hwirq"). Rely on the DT, as
commit 1ee6c5abebd3 ("ath10k: do not enforce interrupt trigger type") did.

Fixes: 8e84c2582169 ("wcn36xx: mac80211 driver for Qualcomm WCN3660/WCN3680 hardware")
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

