From: Zhaoyang Li <heliolee0118@gmail.com>
Date: Mon, 19 Oct 2026 22:59:19 +0800
Subject: [PATCH wireless] wifi: wcn36xx: validate band and frequency in
 survey updates
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-codex-wcn36xx-survey-upstream-v1-1-7c7babc007c1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEYw1moC/yWMSw6CQBAFr0J6bccZUKJehbgYhgbayEC6+Ywh3
 F3QZb1XqRWUhEnhkawgNLNyH3awpwR860JDyNXOkJo0t8be0PcVRVx8yPIYUSeZ6YPToKOQ69B
 l19xcTFr7u4W9MQjVHH/9AhYWepMqPP+PTuWL/HjkD7d0SliKC749pl644XDuHAfYti/SYmkdq
 QAAAA==
X-Change-ID: 20261018-codex-wcn36xx-survey-upstream-a3560402fc91
To: linux-wireless@vger.kernel.org
Cc: loic.poulain@oss.qualcomm.com, kvalo@kernel.org, 
 bryan.odonoghue@linaro.org, wcn36xx@lists.infradead.org, 
 linux-kernel@vger.kernel.org, heliolee0118@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792421960; l=3270;
 i=heliolee0118@gmail.com; s=20261019; h=from:subject:message-id;
 bh=fjp9lLKvfDuTUpNB3hs+MBg5G86RlOJ8i6sh6ABw66g=;
 b=GxdIcTIQ+TqsO27OKrNCGs1UZcm9sYZkUXE73dACi14oz+4yxNUNXLQ92nQsJFcKUDgI3Rag6
 TUbr0tjbwmMAO4WGvPYbRsF/ubuf2cGgbTUbq1i0mVjOWNg4WBM/tSM
X-Developer-Key: i=heliolee0118@gmail.com; a=ed25519;
 pk=syMlenivwkqT00HeAmT4htw8EZeZVwsvh6UhTZcqANE=
X-Endpoint-Received: by B4 Relay for heliolee0118@gmail.com/20261019 with auth_id=1241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WCN3620 only registers the 2.4 GHz band. When scan RX metadata selects
the 5 GHz band, wcn36xx_update_survey() dereferences a NULL supported
band pointer while accessing its channels. This can crash the device
during scanning.

Skip survey updates when the selected band is not registered. Also
return when the frequency does not match any channel in the band,
otherwise the update overwrites the first survey entry for that band.

A retained MSM8916/WCN3620 diagnostic log reports a NULL read at
wcn36xx_rx_skb+0x178/0x720, consistent with accessing sband->channels.
The log lacks a runtime module hash and the raw RX descriptor, so the
exact crash path cannot be independently verified.

Fixes: 29696e0aa413 ("wcn36xx: Track SNR and RSSI for each RX frame")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Zhaoyang Li <heliolee0118@gmail.com>
---
Testing:
- Built the baseline, this fix, and the two-patch RFC series on
  wireless/main af32da41b032 with ARM64 GCC 14.2.0 and W=1.
  The baseline full build had 1067 whole-tree warnings; incremental
  builds reported none (these counts are not directly comparable).
- Rebuilt complete WCN36xx driver objects from clean for all three
  configurations: no warnings or errors; linking and modpost passed.
- Extracted-source ASan/UBSan tests reproduced the unfixed NULL access
  and unmatched-frequency overwrite. The fix passed 90 survey cases,
  256 synthetic scans, and two ordinary RX selections. Kernel APIs
  were stubbed; full RX and skb lifetimes were not exercised.
- Downstream 7.2.9-ufi-stable: 99/100 scans succeeded, one timed out,
  no survey NULL Oops was observed, and 16 pre-existing mac80211
  invalid-band WARNs remained.
- No native upstream kernel boot or dual-band hardware test was done.

Historical crash evidence:
An MSM8916/WCN3620 6.12.111-ufi-diag log reports a NULL read at
wcn36xx_rx_skb+0x178/0x720 with x0=0. In the retained diagnostic
module this is ldr x2, [x0], accessing sband->channels. Symbol spans
and caller return offsets match. The log lacks a runtime module hash
and the raw RX descriptor, so those cannot be independently verified.
---
 drivers/net/wireless/ath/wcn36xx/txrx.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/wireless/ath/wcn36xx/txrx.c b/drivers/net/wireless/ath/wcn36xx/txrx.c
index 8826998797d6..fc371963510f 100644
--- a/drivers/net/wireless/ath/wcn36xx/txrx.c
+++ b/drivers/net/wireless/ath/wcn36xx/txrx.c
@@ -286,6 +286,9 @@ static void wcn36xx_update_survey(struct wcn36xx *wcn, int rssi, int snr,
 		idx = wcn->hw->wiphy->bands[NL80211_BAND_2GHZ]->n_channels;
 
 	sband = wcn->hw->wiphy->bands[band];
+	if (!sband)
+		return;
+
 	channel = sband->channels;
 
 	for (i = 0; i < sband->n_channels; i++, channel++) {
@@ -295,6 +298,9 @@ static void wcn36xx_update_survey(struct wcn36xx *wcn, int rssi, int snr,
 		}
 	}
 
+	if (i == sband->n_channels)
+		return;
+
 	spin_lock(&wcn->survey_lock);
 	wcn->chan_survey[idx].rssi = rssi;
 	wcn->chan_survey[idx].snr = snr;

---
base-commit: af32da41b0327b9c6a37856ba82b6760d6c8d10e
change-id: 20261018-codex-wcn36xx-survey-upstream-a3560402fc91

Best regards,
--  
Zhaoyang Li <heliolee0118@gmail.com>

