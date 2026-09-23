From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Wed, 23 Sep 2026 18:13:26 +0900
Subject: [PATCH net-next v2 2/3] net: macb: Enable RX timestamping for
 specific PTPv1 filters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260923-macb-hwtstamp-rework-v2-2-75c909b2676d@khu.ac.kr>
References: <20260923-macb-hwtstamp-rework-v2-0-75c909b2676d@khu.ac.kr>
In-Reply-To: <20260923-macb-hwtstamp-rework-v2-0-75c909b2676d@khu.ac.kr>
To: netdev@vger.kernel.org, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Rafal Ozieblo <rafalo@cadence.com>
Cc: Conor Dooley <conor.dooley@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Nicolai Buchwitz <nb@tipi-net.de>, linux-kernel@vger.kernel.org, 
 Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790154804; l=1851;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=6FGYgmpXIFqBwfciSCD9Dq6gBdcnn4TCfNguIzs3JV0=;
 b=oL/mBViDgcttRMU7A2keEjBUTtZ0Qizg4L59MbiZILPop9TKSS/n9jMQnA7s46+g9OV1uxKgZ
 KZHydXlHXtAB28YV1HayygLMbA9NSepjkpOUM0qIfre0BRQ50lOF3m3
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Selecting a PTPv1 Sync or Delay_Req filter in gem_set_hwtst() returns
success, but leaves rx_bd_control at its initial value of
TSTAMP_DISABLED. The requested filter therefore appears to have been
applied, even though received packets have no hardware timestamps.

The PTPv1 event case already enables timestamping for all frames, so
use that path for Sync and Delay_Req as well. This enables timestamping
for both requests and returns HWTSTAMP_FILTER_ALL to tell the caller
which filter was actually applied.

Fixes: ab91f0a9b5f4 ("net: macb: Add hardware PTP support")
Reviewed-by: Nicolai Buchwitz <nb@tipi-net.de>
Reviewed-by: Théo Lebrun <theo.lebrun@bootlin.com>
Tested-by: Nicolai Buchwitz <nb@tipi-net.de>
Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/ethernet/cadence/macb_ptp.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/cadence/macb_ptp.c b/drivers/net/ethernet/cadence/macb_ptp.c
index 02face93a..af2e36f81 100644
--- a/drivers/net/ethernet/cadence/macb_ptp.c
+++ b/drivers/net/ethernet/cadence/macb_ptp.c
@@ -421,10 +421,6 @@ int gem_set_hwtst(struct net_device *netdev,
 	switch (rx_filter) {
 	case HWTSTAMP_FILTER_NONE:
 		break;
-	case HWTSTAMP_FILTER_PTP_V1_L4_SYNC:
-		break;
-	case HWTSTAMP_FILTER_PTP_V1_L4_DELAY_REQ:
-		break;
 	case HWTSTAMP_FILTER_PTP_V2_EVENT:
 	case HWTSTAMP_FILTER_PTP_V2_L2_EVENT:
 	case HWTSTAMP_FILTER_PTP_V2_L4_EVENT:
@@ -439,6 +435,8 @@ int gem_set_hwtst(struct net_device *netdev,
 		ncr_mask |= MACB_BIT(SRTSM);
 		ncr_bits |= MACB_BIT(SRTSM);
 		break;
+	case HWTSTAMP_FILTER_PTP_V1_L4_SYNC:
+	case HWTSTAMP_FILTER_PTP_V1_L4_DELAY_REQ:
 	case HWTSTAMP_FILTER_PTP_V1_L4_EVENT:
 	case HWTSTAMP_FILTER_ALL:
 		rx_bd_control = TSTAMP_ALL_FRAMES;

-- 
2.53.0

