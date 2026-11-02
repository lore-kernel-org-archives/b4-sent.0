From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH ath-next 0/3] wifi: ath11k: monitor frames: length, FCS
 failures and rates
Date: Sun, 01 Nov 2026 23:14:08 -0600
Message-Id: <20261101-b8-monitor-frames-v1-0-f0a43d9630e5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACAc6GoC/yWM0QqDMAwAf0XyvEAjTnS/MvbQapwZ2I6kDkH89
 3Xz8TjudjBWYYNbtYPyR0xSLECXCobZxyejjIWhdnVL5AhDh0uKkpPipH5hw9Bw3/UN8dWNULq
 38iTb/3kHn2eMvGV4nMbW8OIh/5ZwHF8H6ANHfwAAAA==
X-Change-ID: 20261101-b8-monitor-frames-b4e98941e50d
To: Jeff Johnson <jjohnson@kernel.org>, 
 Jouni Malinen <quic_jouni@quicinc.com>, Kalle Valo <kvalo@kernel.org>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Julia Lawall <julia.lawall@lip6.fr>, kbuild test robot <lkp@intel.com>, 
 Manikanta Pubbisetty <quic_mpubbise@quicinc.com>, 
 Venkateswara Naralasetty <quic_vnaralas@quicinc.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 Anilkumar Kolli <quic_akolli@quicinc.com>, Miles Hu <milehu@codeaurora.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Govindaraj Saminathan <quic_gsamin@quicinc.com>, 
 Sriram R <sriram.ramachandran@oss.qualcomm.com>, 
 Shashidhar Lakkavalli <slakkavalli@datto.com>, 
 Rajkumar Manoharan <rmanohar@codeaurora.org>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793596448; l=2389;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=aiMBWaeP4VCoKPc5rfu9vnen1taSbfQUzIsmGYDSs4g=;
 b=EfICl5+ggRkI4hafYcauThS/FzFKTwkOo0MqIeugjSa2A0B3CmWUvYtqbT3Kvnvxnci3pPJOO
 kfpnjyaJtM8C6ek9XVN0zdieLc+owJq1CIa0/3CS7yLosh0sf+RL/B8
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three fixes to what an ath11k monitor interface hands to mac80211, found
capturing with the QCN9072 scan radio of an Arista C-360:

1. Size monitor MPDUs by the chip's rx descriptor. On a QCN9074 a
   monitor frame kept its FCS plus 4 stale bytes, unflagged.
2. Hold back FCS-failed monitor frames unless a monitor asked for them
   (FIF_FCSFAIL), as ath10k does.
3. Report a monitor frame's MCS and NSS only when the PPDU's SIG was
   seen, so mac80211 no longer warns about, and drops, a VHT/HE rate
   with no NSS.

The series applies on top of these four, all still under review:
- [PATCH ath-next 0/2] wifi: ath11k: two monitor destination ring fixes
  <20261024-ath11k-monitor-buffers-v1-0-ff155feca2f6@gmail.com>
- [PATCH ath-next] wifi: ath11k: update rx_channel on a channel switch
  <20261024-ath11k-rx-channel-switch-v1-1-5fc2ba53ca8f@gmail.com>
- [PATCH ath-next] wifi: ath11k: report the measured noise floor of the
  channel in use
  <20261024-ath11k-survey-noise-floor-v1-1-8eb03002aab8@gmail.com>
- [PATCH ath-next] wifi: ath11k: add the measured noise floor, not -95,
  to a received signal
  <20261029-ath11k-signal-noise-floor-v1-1-8867d25298c8@gmail.com>

Tested on an Arista C-360 (IPQ8074 + QCN9074/QCN9072) with OpenWrt
main, these as backports, on the QCN9072 scan radio's monitor (no
fcsfail flag), comparing captures of the same air:
- frames ending in an unflagged FCS: 353 of 400 (88%) before, 0 of 800
  with the series; beacons whose elements end at the frame's end: 1 of
  43 before, 60 of 60 with it;
- frames with a bad FCS: 44 of 400 (11%) before, 0 of 800 with it;
- no "Rate marked as a VHT rate but data is invalid" warning during
  the run (it showed once before, in a longer capture).

---
Christopher Griffin (3):
      wifi: ath11k: size monitor MPDUs by the chip's rx descriptor
      wifi: ath11k: hold back FCS-failed monitor frames unless asked for
      wifi: ath11k: report a monitor frame's MCS and NSS only from the PPDU's SIG

 drivers/net/wireless/ath/ath11k/dp_rx.c | 75 +++++++++++++++++++++++++++------
 drivers/net/wireless/ath/ath11k/mac.c   |  3 +-
 2 files changed, 63 insertions(+), 15 deletions(-)
---
base-commit: c5546d76a980fc035b20fb7932e191e6138dcb91
change-id: 20261101-b8-monitor-frames-b4e98941e50d

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

