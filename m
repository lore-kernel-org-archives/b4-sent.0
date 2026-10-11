From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sun, 11 Oct 2026 19:02:10 -0300
Subject: [PATCH] wifi: ath10k: fill in WCN3990's channel counter frequency
 and wraparound
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-ath10k-wcn3990-survey-v1-1-c3d51f198a0f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ7CMAxA0atUnrEUBxJUroI6pMZQgxRQ3BZQ1
 bsTYHzD/wuYFBWDQ7NAkVlN77mCNg3wkPJFUE/V4J2P5IgwjQO5Gz45b9vWoU1lljfGHYeYfNg
 H7qG2jyJnff2+x+5vm/qr8Pidwbp+AFsFeat5AAAA
X-Change-ID: 20261011-ath10k-wcn3990-survey-64c56a2575cb
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791756129; l=3254;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=cMknKb3KJmpnu47125b2ZiM5JusGIo3IhX2PufK6Iv4=;
 b=2vi1fujkVV2kHJwYSs7GNEkatX33Gjc+IO3yvFzE1J0ekYEgwuJwuXZPIXGg2viH1g4BeWVUN
 jpdJGNXGPAODuA84tRBzl/LUul00gDuupAVfkK2Yt2OkVnpJ3M0caTn
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On WCN3990 firmware that reports channel info in pairs, such as
WLAN.HL.1.0.1, the survey's channel active and busy times are always 0:
its hw_params entry sets no channel_counters_freq_hz, so CCNT_TO_MSEC()
divides by zero, which arm64 evaluates to 0, and no cc_wraparound_type.

This firmware leaves mac_clk_mhz at 0, so the survey needs the counter
frequency from hw_params. Measured against the host clock, the counters
run at 120 MHz. On overflow the cycle counter drops by 2^31, as the
shifted wraparound types assume, while the rx clear counter wraps
around to 0, a pair no existing type describes, so add one that
corrects the cycle counter only.

Fixes: 03a72288c546 ("ath10k: wmi: add hw params entry for wcn3990")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on a Motorola Moto X4 (SDM630, WCN3990) with
reads between 13 and 150 ms, where it read 0. Without
the new wraparound type, a channel visit spanning a cycle counter
overflow reads about 17.9 s. Firmware that sends a single chan info
event per channel takes another path and is unaffected.

WLAN.HL.1.0.1.c2-00498: over 50 scans every channel's active time
---
 drivers/net/wireless/ath/ath10k/core.c | 2 ++
 drivers/net/wireless/ath/ath10k/hw.c   | 4 ++++
 drivers/net/wireless/ath/ath10k/hw.h   | 6 ++++++
 3 files changed, 12 insertions(+)

diff --git a/drivers/net/wireless/ath/ath10k/core.c b/drivers/net/wireless/ath/ath10k/core.c
index 7c2939cbde5f..e1172be4bd1e 100644
--- a/drivers/net/wireless/ath/ath10k/core.c
+++ b/drivers/net/wireless/ath/ath10k/core.c
@@ -716,7 +716,9 @@ static const struct ath10k_hw_params ath10k_hw_params_list[] = {
 		.bus = ATH10K_BUS_SNOC,
 		.name = "wcn3990 hw1.0",
 		.led_pin = 0,
+		.cc_wraparound_type = ATH10K_HW_CC_WRAP_SHIFTED_CC,
 		.continuous_frag_desc = true,
+		.channel_counters_freq_hz = 120000,
 		.tx_chain_mask = 0x7,
 		.rx_chain_mask = 0x7,
 		.max_spatial_stream = 4,
diff --git a/drivers/net/wireless/ath/ath10k/hw.c b/drivers/net/wireless/ath/ath10k/hw.c
index 6f5019bf0b7d..7d7b36ef2986 100644
--- a/drivers/net/wireless/ath/ath10k/hw.c
+++ b/drivers/net/wireless/ath/ath10k/hw.c
@@ -574,6 +574,10 @@ void ath10k_hw_fill_survey_time(struct ath10k *ar, struct survey_info *survey,
 			if (rcc < rcc_prev)
 				rcc_fix = 0x7fffffff;
 			break;
+		case ATH10K_HW_CC_WRAP_SHIFTED_CC:
+			if (cc < cc_prev)
+				cc_fix = 0x7fffffff;
+			break;
 		case ATH10K_HW_CC_WRAP_DISABLED:
 			break;
 		}
diff --git a/drivers/net/wireless/ath/ath10k/hw.h b/drivers/net/wireless/ath/ath10k/hw.h
index cd468b24bd33..53bfc3c6957a 100644
--- a/drivers/net/wireless/ath/ath10k/hw.h
+++ b/drivers/net/wireless/ath/ath10k/hw.h
@@ -481,6 +481,12 @@ enum ath10k_hw_cc_wraparound_type {
 	 * first type.
 	 */
 	ATH10K_HW_CC_WRAP_SHIFTED_EACH = 2,
+
+	/* The Cycle Counter wraps around to 0x7fffffff when it
+	 * overflows, and the Rx Clear Count wraps around to 0
+	 * independently of it.
+	 */
+	ATH10K_HW_CC_WRAP_SHIFTED_CC = 3,
 };
 
 enum ath10k_hw_refclk_speed {

---
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20261011-ath10k-wcn3990-survey-64c56a2575cb

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

