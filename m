From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH ath-next 0/2] wifi: ath11k: two monitor destination ring
 fixes
Date: Sat, 24 Oct 2026 16:30:53 -0500
Message-Id: <20261024-ath11k-monitor-buffers-v1-0-ff155feca2f6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI0j3WoC/yWM0QrCMAwAf2Xk2UBTZkF/RXzYutRFsZWkk8HYv
 1v18TjuNjBWYYNzt4HyW0xKbkCHDuI85BujTI3BOx/I+R6HOhM98Fmy1KI4LimxGro+hhjIh+N
 0gha/lJOsv/EFWoOZ1wrXv7FlvHOs3y/s+wdJDL5uhAAAAA==
X-Change-ID: 20261024-ath11k-monitor-buffers-04c6c61265d9
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792877453; l=1099;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=L7gjGCmzyeulE7eU8L3X1sKQ8Bvh81x5kGFaYfXJVKI=;
 b=NJoaftq5eB0g13ykQ6+EM7DAMk3urNmrzlqGDQ+5julXoUdBraj0sIAVZMVoso915GM/3WYFo
 5v5y4nH06mtCyRd+Jrvhyl53Fm3xl2KByZyWn8P3ay6ZX3dtxBpGY7R
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for ath11k's monitor destination path (the one non-full
monitor mode uses, as on IPQ8074), found on an Arista C-360 running
OpenWrt with a monitor interface on each radio.

The first stops the driver freeing a buffer the device still holds when
the device lists a buffer it handed back already. With monitor
interfaces up this corrupted memory and crashed the AP every few hours.

The second fixes a small leak of MPDU chains each time the PPDU ID wraps
to 0.

The two are independent of each other; both apply to ath-next.

---
Christopher Griffin (2):
      wifi: ath11k: don't free a monitor buffer the device still holds
      wifi: ath11k: don't take a monitor PPDU ID of 0 for no change

 drivers/net/wireless/ath/ath11k/dp_rx.c  | 32 +++++++++++++++++++++++++-------
 drivers/net/wireless/ath/ath11k/hal_rx.h |  1 +
 2 files changed, 26 insertions(+), 7 deletions(-)
---
base-commit: cd026e68fdbf88b9cc522b76c7a9d92c9a41f709
change-id: 20261024-ath11k-monitor-buffers-04c6c61265d9

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

