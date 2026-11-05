From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH 0/3] wifi: ath10k/ath11k: firmware recovery deadlock and
 stale scan timeouts
Date: Thu, 05 Nov 2026 12:11:35 -0600
Message-Id: <20261105-ath-recovery-scan-timeout-v1-0-99a70d89e114@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANjG7GoC/yXMwQqDMAyA4VeRnBewigp7lbFDbOPMYO1IqmyI7
 75Oj9/h/zcwVmGDa7WB8iomKRa4SwV+pvhglFAMTd30ztUdUp5R2aeV9YvmKWKWF6clYzdQO7Y
 hDNRPUPq38iSf4327n7ZlfLLP/yHs+w/85mFEfQAAAA==
X-Change-ID: 20261105-ath-recovery-scan-timeout-57a3b3dd7a6f
To: Jeff Johnson <jjohnson@kernel.org>, Kalle Valo <kvalo@kernel.org>, 
 Hari Chandrakanthan <quic_haric@quicinc.com>, 
 Venkateswara Naralasetty <quic_vnaralas@quicinc.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 Anilkumar Kolli <quic_akolli@quicinc.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Maharaja Kennadyrajan <quic_mkenna@quicinc.com>, 
 John Crispin <john@phrozen.org>, 
 Govindaraj Saminathan <quic_gsamin@quicinc.com>, ath10k@lists.infradead.org, 
 Wen Gong <quic_wgong@quicinc.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902298; l=1437;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=W7jTq1TOtayC73926OLlkLF3M0Te4FBfzpormKp/UTk=;
 b=ksbVWRffEogZW1kkwDnEVhCHO1gq8XKyz1R0bHkd+15n80OhyJCy0aoRItaYBJ2S0EpiqhjaQ
 YjXViboSS83Di+DT6lrPdt6ju+v7bC9mjkPCBs8f/nFpvjRYCtD0z0d
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On an Arista C-360 (IPQ8074 with two QCN9074), a QCN9074 firmware crash
was never recovered. Patch 1 removes a conf_mutex deadlock between
ath11k_mac_op_start() and the restart work, which makes every recovery
time out when CONFIG_ATH11K_SPECTRAL is set.

The same crash left a scan timeout pending for a scan that had failed to
start, and it fired on freed memory after the driver was bound again.
Patch 2 stops arming it, and patch 3 does the same in ath10k, which has
the same code.

Tested on an Arista C-360 with the series applied to the ath11k of
OpenWrt's backports-7.2: before patch 1, two simulated asserts of the
QCN9074 firmware both ended in "Hardware became unavailable during
restart"; with it, two of two recovered in about 3 s. Patches 2
and 3 are compile-tested only (W=1); no scan failed to start in these
runs.

---
Christopher Griffin (3):
      wifi: ath11k: don't hold conf_mutex while waiting for recovery
      wifi: ath11k: don't arm the scan timeout for a scan that did not start
      wifi: ath10k: don't arm the scan timeout for a scan that did not start

 drivers/net/wireless/ath/ath10k/mac.c | 1 +
 drivers/net/wireless/ath/ath11k/mac.c | 6 ++++++
 2 files changed, 7 insertions(+)
---
base-commit: 5c8eab13e391aaabd5a1ad58f3ee4bb10ce7573e
change-id: 20261105-ath-recovery-scan-timeout-57a3b3dd7a6f

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

