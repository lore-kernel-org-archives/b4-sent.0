From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 23:10:10 -0600
Subject: [PATCH ath-next] wifi: ath11k: don't report a QCN9074's chan-info
 noise floor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b90-qcn9074-chan-info-nf-v1-1-aa0a99ba7ba6@gmail.com>
X-B4-Tracking: v=1; b=H4sIADEb6GoC/yWMQQ6CMBBFr0Jm7STTKgJexbhoy1TGxaBtNSSEu
 1t0+fL/eytkTsIZLs0KiT+SZdYK5tBAmJzeGWWsDJbs2Rgy6AfCV9CBuhPuDxSNM2rEsSd3bPu
 2885C1Z+Joyy/9BVcmVB5KXD7L/ntHxzKXoZt+wKQB4RahgAAAA==
X-Change-ID: 20261101-b90-qcn9074-chan-info-nf-d80a35857ba2
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793596209; l=3286;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=te6WMy5xu/GQ3oR7I7RbrttS24vmR5JQGlg47fN/BYU=;
 b=5VJ/Pz90aEwcbk5GCIHHTA0lTd2rLG+H8/yyaGQjxH8jG3s125XWb5/pdt+Ikr9i5hnZ/FG5I
 E/fKuVMW4VUBcgkRscdQOdhy2YU0Ctv4CrNFxp0S2iexnDp8zxdOw5v
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a QCN9074 (and the QCN9072, which uses its hw_params) the noise floor
in WMI_CHAN_INFO_EVENTID's START_RESP is a fixed value, not a
measurement. On an Arista C-360 the QCN9072 scan radio read -107 dBm
+-1 on every 2.4, 5 and 6 GHz channel it visited (150 ms dwells), busy or
quiet: 5540 at 52 % busy read -110, its lowest. The IPQ8074's own radios,
on the same channels at the same time, read -95 to -98 and followed the
channel (-96, -97, -96 on 5200/5220/5240; -95 on 5785, -98 on 5885),
where the QCN9072 read -108, -107, -107, -107 and -106. -107 is also
below the ~-101 dBm thermal noise of 20 MHz.

Leave the noise out of a QCN9074's off-channel survey entries, so that
nothing takes the placeholder for a noise floor; their time and busy
counts are unchanged, as is every other chip.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/core.c | 1 +
 drivers/net/wireless/ath/ath11k/hw.h   | 2 ++
 drivers/net/wireless/ath/ath11k/wmi.c  | 8 +++++---
 3 files changed, 8 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/core.c b/drivers/net/wireless/ath/ath11k/core.c
index 766ae27306f43..d6848789dcff4 100644
--- a/drivers/net/wireless/ath/ath11k/core.c
+++ b/drivers/net/wireless/ath/ath11k/core.c
@@ -392,6 +392,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 		.cfr_support = false,
 		.cfr_num_stream_bufs = 0,
 		.cfr_stream_buf_size = 0,
+		.chan_info_nf_invalid = true,
 	},
 	{
 		.name = "wcn6855 hw2.0",
diff --git a/drivers/net/wireless/ath/ath11k/hw.h b/drivers/net/wireless/ath/ath11k/hw.h
index 4996536fbd14f..202430fa5b0da 100644
--- a/drivers/net/wireless/ath/ath11k/hw.h
+++ b/drivers/net/wireless/ath/ath11k/hw.h
@@ -231,6 +231,8 @@ struct ath11k_hw_params {
 	bool cfr_support;
 	u32 cfr_num_stream_bufs;
 	u32 cfr_stream_buf_size;
+	/* chan-info's noise floor is a fixed value, not a measurement */
+	bool chan_info_nf_invalid;
 };
 
 struct ath11k_hw_ops {
diff --git a/drivers/net/wireless/ath/ath11k/wmi.c b/drivers/net/wireless/ath/ath11k/wmi.c
index 08fd6795ed9e7..7c8b605b622cd 100644
--- a/drivers/net/wireless/ath/ath11k/wmi.c
+++ b/drivers/net/wireless/ath/ath11k/wmi.c
@@ -8031,9 +8031,11 @@ static void ath11k_chan_info_event(struct ath11k_base *ab, struct sk_buff *skb)
 	if (ch_info_ev.cmd_flags == WMI_CHAN_INFO_START_RESP) {
 		survey = &ar->survey[idx];
 		memset(survey, 0, sizeof(*survey));
-		survey->noise = ch_info_ev.noise_floor;
-		survey->filled = SURVEY_INFO_NOISE_DBM | SURVEY_INFO_TIME |
-				 SURVEY_INFO_TIME_BUSY;
+		survey->filled = SURVEY_INFO_TIME | SURVEY_INFO_TIME_BUSY;
+		if (!ab->hw_params.chan_info_nf_invalid) {
+			survey->noise = ch_info_ev.noise_floor;
+			survey->filled |= SURVEY_INFO_NOISE_DBM;
+		}
 		survey->time = div_u64(ch_info_ev.cycle_count, cc_freq_hz);
 		survey->time_busy = div_u64(ch_info_ev.rx_clear_count, cc_freq_hz);
 	}

---
base-commit: a3ddbb45768717b5c9f923489387cf55c838d1ad
change-id: 20261101-b90-qcn9074-chan-info-nf-d80a35857ba2

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

