From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH 0/2] wifi: ath11k: feed mac80211's airtime fairness
Date: Sun, 08 Nov 2026 16:45:28 -0600
Message-Id: <20261108-ath11k-tx-airtime-v1-0-f1a02b2372d4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIj78GoC/yXMTQqEMAxA4atI1hMw9Q+8iswi1qhxGJW2Mwji3
 a26/Bbv7eDFqXiokx2c/NXrMkfQKwE78jwIahcNJjUlUVohh5Hog2FDVhf0K1hYyUrDbc9ZDrF
 bnfS63c/m/dj/2klsuEZwHCdhC9f+dQAAAA==
X-Change-ID: 20261107-ath11k-tx-airtime-5ce362abfa34
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794177928; l=1972;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=XIN8sZMXV6vtgjXMXA1MUFV8xymBm0XeIvXZSKIKisk=;
 b=m7xCdn3PX3XqZpB0fAoMoUJBb/tw02ZLgvB3bgHJoGwwhx2wcm03/bQ3z90IEyKZEBeWCcNyP
 7jrop2ClLl5AHwK3chMLcL4c17O/MnYOAtBdVkkJ4vBi6OOO9AIB07w
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k never reports airtime to mac80211, so airtime fairness does
nothing on any ath11k radio: every station's deficit stays where it
started and the TX queues are served round robin. Patch 1 registers
each PPDU's TX airtime from the HTT PPDU stats, the way ath10k and
mt76 already do. Patch 2 fixes two paths that free TX frames behind
mac80211's back (REINJ/INSPECT completions, and the datapath teardown
during firmware crash recovery), so that mac80211's per-frame state,
including any TX status a frame asked for, is reported.

Both were tested on an IPQ8074 AP (Arista C-360) with a QCN9074 radio
at 6 GHz, 160 MHz, against the same AP without them, with one and two
clients (TCP download, 30 s runs; for one client 6 runs with the
patches and 12 without): one client 1777 vs 1672 Mbit/s, two clients
1540/1524 vs 1569/1566,
95th percentile ping under the two-client load 42-50 vs 61 ms and
31-44 vs 56-77 ms.

This series does not advertise NL80211_EXT_FEATURE_AQL. With AQL on
as well, the same radio lost 22-44% of its throughput whatever the AQL
limits (5/12 to 20/48 ms), and lost more over minutes of load, while
pending airtime rarely reached the limits; turning off aql_enable or
airtime_flags at run time did not bring it back. That needs its own
look and is not part of this series.

The changes, the messages and the tests were written with Claude, an
AI coding assistant.

---
Christopher Griffin (2):
      wifi: ath11k: report TX airtime to mac80211
      wifi: ath11k: hand freed TX frames back to mac80211

 drivers/net/wireless/ath/ath11k/dp.c    | 12 +++++++++---
 drivers/net/wireless/ath/ath11k/dp_rx.c |  9 ++++++++-
 drivers/net/wireless/ath/ath11k/dp_tx.c |  4 ++--
 3 files changed, 19 insertions(+), 6 deletions(-)
---
base-commit: ad6bdd5f9030dbcf29a67f40ccdb3fa57afecff5
change-id: 20261107-ath11k-tx-airtime-5ce362abfa34

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

