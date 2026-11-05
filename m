From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 05 Nov 2026 12:11:36 -0600
Subject: [PATCH 1/3] wifi: ath11k: don't hold conf_mutex while waiting for
 recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ath-recovery-scan-timeout-v1-1-99a70d89e114@gmail.com>
References: <20261105-ath-recovery-scan-timeout-v1-0-99a70d89e114@gmail.com>
In-Reply-To: <20261105-ath-recovery-scan-timeout-v1-0-99a70d89e114@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902298; l=2653;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=1kehi+2vZf6P3L9xV8V0iKWZcplS1y+mhbwhClMV9fs=;
 b=UDI9djzv23u66x3aY4rEAvva7PSjSvaDNe5Vym41K6nCM8EKeDoolDxVnQMojqQ2QKiusFYSz
 xFM3ewGhjuzBs80CAlmyc608QIa7Fgnq69Y3ACAP8WVWTkH4SxnNK+U
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a firmware crash, mac80211's restart calls ath11k_mac_op_start(),
which waits in ath11k_mac_wait_reconfigure(), for up to
ATH11K_RECONFIGURE_TIMEOUT_HZ (10 s), for the restart work to finish
ath11k_core_reconfigure_on_crash(). It waits with ar->conf_mutex held.
But ath11k_core_reconfigure_on_crash() calls ath11k_spectral_deinit(),
which takes ar->conf_mutex on each radio where spectral scan is
enabled.

The wait came with commit 38194f3a605e ("ath11k: add synchronization
operation between reconfigure of mac80211 and ath11k_base"), the lock
in ath11k_spectral_deinit() a month later with the commit in the Fixes
tag.

So with CONFIG_ATH11K_SPECTRAL the restart work blocks until the wait
times out. op_start() then sends WMI commands while
ATH11K_FLAG_CRASH_FLUSH is still set, they fail with -ESHUTDOWN, and
mac80211 gives up on the radio. Recovery never succeeds.

Seen on a QCN9074 after simulate_fw_crash (debug_mask 0x1060). Firmware
start, the restart work's first step after the deinit, ran only once
op_start() had timed out and dropped the mutex:

  [  146.881170] ath11k_pci 0001:01:00.0: qmi firmware init done
  [  156.651121] ath11k_pci 0001:01:00.0: failed to send WMI_PDEV_SET_PARAM cmd
  [  156.651173] ath11k_pci 0001:01:00.0: failed to enable PMF QOS: (-108
  [  156.658853] ath11k_pci 0001:01:00.0: qmi firmware start
  [  156.663443] Hardware became unavailable during restart.

Drop conf_mutex across the wait. During the restart, op_start() runs
with the wiphy mutex held, so no other mac80211 callback can come in
meanwhile.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Fixes: 161c64de239c ("ath11k: disable spectral scan during spectral deinit")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/mac.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d1..5e4bb0ad057dd 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -6645,7 +6645,12 @@ static int ath11k_mac_op_start(struct ieee80211_hw *hw)
 		break;
 	case ATH11K_STATE_RESTARTING:
 		ar->state = ATH11K_STATE_RESTARTED;
+		/* The restart work takes conf_mutex (spectral deinit), so
+		 * don't hold it while waiting for that work to finish.
+		 */
+		mutex_unlock(&ar->conf_mutex);
 		ath11k_mac_wait_reconfigure(ab);
+		mutex_lock(&ar->conf_mutex);
 		break;
 	case ATH11K_STATE_RESTARTED:
 	case ATH11K_STATE_WEDGED:

-- 
2.43.0

