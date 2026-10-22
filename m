From: John Macias <dencity7@gmail.com>
Date: Wed, 21 Oct 2026 23:42:37 -0700
Subject: [PATCH ath-next v2 1/2] wifi: ath11k: bound READY MAC address
 array reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-rdy-mac-array-bounds-v2-1-cf7f45f868dd@gmail.com>
References: <20261021-rdy-mac-array-bounds-v2-0-cf7f45f868dd@gmail.com>
In-Reply-To: <20261021-rdy-mac-array-bounds-v2-0-cf7f45f868dd@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, ath12k@lists.infradead.org, 
 John Macias <dencity7@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792651359; l=2463;
 i=dencity7@gmail.com; s=20261015; h=from:subject:message-id;
 bh=Fqs87XxAhySy9Ng8R56w4xVx0qjiqfm2ePiFbvNvI0Y=;
 b=1rbPMf1BSr/GGfj65eUpIJF4yZRe3hLo3DA3U+vzKR3WDcbWXpQY9t3TZ8elaMNfkv4yepyYd
 lFF8gZuF23zAyAOAqk4W+O+tuDj1WP4STFq19BtPLc4uNM6z0yIq6dY
X-Developer-Key: i=dencity7@gmail.com; a=ed25519;
 pk=z7cMHA0B6NULvJzsST/bbOOegMB6xCo9+/ytQure7B8=
X-Endpoint-Received: by B4 Relay for dencity7@gmail.com/20261015 with auth_id=1198
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The READY event carries a fixed record whose num_extra_mac_addr field
advertises how many per-radio MAC addresses follow, and a separate
WMI_TAG_ARRAY_FIXED_STRUCT TLV holding that array. The TLV iterator
only ensures that the array TLV fits inside the event;
ath11k_wmi_tlv_rdy_parse() then copies one address per radio without
checking that the array really holds num_radios entries.

If firmware advertises at least num_radios extra addresses but sends a
shorter array, for example two radios with an eight-byte array, the second
ether_addr_copy() reads past the end of the TLV value.

Check the array length against num_radios before copying. When it is too
short, warn and leave pdevs_macaddr_valid unset, so the driver falls back
to deriving the per-radio addresses as it does when no array is provided,
instead of failing READY processing.

Found by code review while bringing up a device with older firmware; a
userspace harness that includes the unmodified parser reports a 6-byte
heap-buffer-overflow read under AddressSanitizer for this input, and
the fixed parser passes. Compile tested on ath-next (W=1). The same
change has also run on an IPQ8074 hw1.0 board (with out-of-tree
enablement patches) on every boot since 16 Oct 2026; that firmware
sends a well-formed array, so this exercises only the normal path,
which still assigns both per-radio addresses and prints no warning.

Tested-on: IPQ8074 hw1.0 AHB WLAN.HK.2.0-01792-QCAHKSWPL_SILICONZ-1

Fixes: d5c65159f289 ("ath11k: driver for Qualcomm IEEE 802.11ax devices")
Assisted-by: LLM
Signed-off-by: John Macias <dencity7@gmail.com>
---
 drivers/net/wireless/ath/ath11k/wmi.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/wmi.c b/drivers/net/wireless/ath/ath11k/wmi.c
index 08fd6795ed..6ae4e881f8 100644
--- a/drivers/net/wireless/ath/ath11k/wmi.c
+++ b/drivers/net/wireless/ath/ath11k/wmi.c
@@ -7330,6 +7330,12 @@ static int ath11k_wmi_tlv_rdy_parse(struct ath11k_base *ab, u16 tag, u16 len,
 		if (!(ab->num_radios > 1 && num_mac_addr >= ab->num_radios))
 			break;
 
+		if (len < ab->num_radios * sizeof(*addr_list)) {
+			ath11k_warn(ab, "ready event mac address array too short: %u bytes for %d radios\n",
+				    len, ab->num_radios);
+			break;
+		}
+
 		for (i = 0; i < ab->num_radios; i++) {
 			pdev = &ab->pdevs[i];
 			ether_addr_copy(pdev->mac_addr, addr_list[i].addr);

-- 
2.47.3

