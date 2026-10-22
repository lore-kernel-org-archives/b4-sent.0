From: John Macias <dencity7@gmail.com>
Date: Wed, 21 Oct 2026 23:42:38 -0700
Subject: [PATCH ath-next v2 2/2] wifi: ath12k: bound READY MAC address
 array reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-rdy-mac-array-bounds-v2-2-cf7f45f868dd@gmail.com>
References: <20261021-rdy-mac-array-bounds-v2-0-cf7f45f868dd@gmail.com>
In-Reply-To: <20261021-rdy-mac-array-bounds-v2-0-cf7f45f868dd@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, ath12k@lists.infradead.org, 
 John Macias <dencity7@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792651359; l=1848;
 i=dencity7@gmail.com; s=20261015; h=from:subject:message-id;
 bh=Q7bR+qmBnYByCGbR1Dt5w8wYWTuypEv1iCd0orMgbPU=;
 b=iszuxz1/FBi89e2XnAoX0xyM5ZS1WT29ZYeAuY7KlQQiVQdr4s5xAI1f8R0Y2fUZ18SmHXrC1
 z7yvZPmE6i+AQEXadz7ju3C8X5cNlYyrxkHy25tJCQOt2cZ6Y3APOJB
X-Developer-Key: i=dencity7@gmail.com; a=ed25519;
 pk=z7cMHA0B6NULvJzsST/bbOOegMB6xCo9+/ytQure7B8=
X-Endpoint-Received: by B4 Relay for dencity7@gmail.com/20261015 with auth_id=1198
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath12k_wmi_rdy_parse() has the same pattern as ath11k: after checking
that the READY fixed record advertises at least num_radios extra MAC
addresses, it copies one address per radio from the
WMI_TAG_ARRAY_FIXED_STRUCT TLV without checking that the TLV actually
holds num_radios entries.

With two radios and an array shorter than two 8-byte entries, the second
ether_addr_copy() reads past the end of the TLV value.

Check the array length against num_radios before copying. When it is too
short, warn and leave pdevs_macaddr_valid unset, so the driver keeps its
default per-radio addresses instead of failing READY processing.

A userspace harness that includes the unmodified parser reports a 6-byte
heap-buffer-overflow read under AddressSanitizer for 8- and 12-byte
arrays with two radios, and the fixed parser passes. Compile tested only
(ath-next, W=1).

Fixes: d889913205cf ("wifi: ath12k: driver for Qualcomm Wi-Fi 7 devices")
Assisted-by: LLM
Signed-off-by: John Macias <dencity7@gmail.com>
---
 drivers/net/wireless/ath/ath12k/wmi.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/wireless/ath/ath12k/wmi.c b/drivers/net/wireless/ath/ath12k/wmi.c
index 75b259990c..ef070ace08 100644
--- a/drivers/net/wireless/ath/ath12k/wmi.c
+++ b/drivers/net/wireless/ath/ath12k/wmi.c
@@ -7099,6 +7099,12 @@ static int ath12k_wmi_rdy_parse(struct ath12k_base *ab, u16 tag, u16 len,
 		if (!(ab->num_radios > 1 && num_mac_addr >= ab->num_radios))
 			break;
 
+		if (len < ab->num_radios * sizeof(*addr_list)) {
+			ath12k_warn(ab, "ready event mac address array too short: %u bytes for %d radios\n",
+				    len, ab->num_radios);
+			break;
+		}
+
 		for (i = 0; i < ab->num_radios; i++) {
 			pdev = &ab->pdevs[i];
 			ether_addr_copy(pdev->mac_addr, addr_list[i].addr);

-- 
2.47.3

