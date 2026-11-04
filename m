From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 09:36:50 -0600
Subject: [PATCH ath-next] wifi: ath10k: don't warn about a pdev param the
 firmware lacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-ath10k-unsupported-pdev-param-v1-1-b3973cef8a72@gmail.com>
X-B4-Tracking: v=1; b=H4sIABFR62oC/yWNWwrCMBQFt1Lutxdy2yDoVsSPpDm1UUxDHqVQu
 nejfg6HM7NTRvLIdO12Slh99ktoIKeOxtmEB9i7xtSr/iyiNFvNpsyiXlxDrjEuqcBxdFg5mmT
 erI3YCwZYmUBNExMmv/0SN2pXDtgK3f9LrvaJsXwLdBwf/fZNAY4AAAA=
X-Change-ID: 20261104-b4-ath10k-unsupported-pdev-param-4a1b9e3eb1fe
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793806609; l=3220;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=FSA292u5sCTcbszeVed2MuneSQSw8t2SoCteAKWPoU8=;
 b=EBX0Q4NJ1xPErZiJJT39EEgLp79tCgdRVMqeWXrewECTgvMS4XI2mTCB3cMf+g6u3Kji10nhZ
 oYl0MGyNh20DLNAa9lOPEe5XSuU04DL9z5gt7mA4/hJT7E4zzZGjrDv
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On firmware other than WMI-TLV, every start of the radio logs

  ath10k_pci 0000:01:00.0: pdev param 0 not supported by firmware

and every association of a station interface logs it again, followed by

  ath10k_pci 0000:01:00.0: failed to enable peer stats info: -95

ath10k_start() sets idle_ps_config and ath10k_bss_assoc() sets
peer_stats_info_enable; only the WMI-TLV pdev param map has them, the
others hold WMI_PDEV_PARAM_UNSUPPORTED, and the set returns -EOPNOTSUPP
after the warning. ath10k_start() already takes -EOPNOTSUPP as no
error, so the warning tells nothing.

Report an unsupported pdev param at debug level, as an unsupported
vdev param already is, and let ath10k_bss_assoc() take -EOPNOTSUPP as
no error too. A caller that needs the param still warns with the
error.

Seen with QCA9882 radios on 10.1 firmware used as scanning and test
stations: 204 "pdev param 0" and 62 "peer stats info" warnings in ten
hours on one access point.

Tested-on: QCA988X hw2.0 PCI 10.1-ct-8x-__fW-023-23ea9f8e
Tested-on: IPQ4019 hw1.0 AHB 10.4b-ct-4019-fW-14-fcb240f0
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Tested with ath10k-ct's copy of these two functions, which carries the
same lines (OpenWrt's default ath10k driver for these chips), on a
QCA9882 scan radio and the IPQ4019 radios of an Arista W-118: before,
each firmware start and each station association logged the warnings;
with the change, none in two firmware starts of each radio and an
association of the QCA9882 as a station. This patch itself is
compile-tested on ath-next (wmi.o, mac.o, W=1).
---
 drivers/net/wireless/ath/ath10k/mac.c | 2 +-
 drivers/net/wireless/ath/ath10k/wmi.c | 4 ++--
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/mac.c b/drivers/net/wireless/ath/ath10k/mac.c
index 8e604697d6c20..20b91e8abb5be 100644
--- a/drivers/net/wireless/ath/ath10k/mac.c
+++ b/drivers/net/wireless/ath/ath10k/mac.c
@@ -3158,7 +3158,7 @@ static void ath10k_bss_assoc(struct ieee80211_hw *hw,
 
 	ret = ath10k_wmi_pdev_set_param(ar,
 					ar->wmi.pdev_param->peer_stats_info_enable, 1);
-	if (ret)
+	if (ret && ret != -EOPNOTSUPP)
 		ath10k_warn(ar, "failed to enable peer stats info: %d\n", ret);
 
 	ret = ath10k_wmi_vdev_up(ar, arvif->vdev_id, arvif->aid, arvif->bssid);
diff --git a/drivers/net/wireless/ath/ath10k/wmi.c b/drivers/net/wireless/ath/ath10k/wmi.c
index e57588c19c800..a2efd2188d111 100644
--- a/drivers/net/wireless/ath/ath10k/wmi.c
+++ b/drivers/net/wireless/ath/ath10k/wmi.c
@@ -6544,8 +6544,8 @@ ath10k_wmi_op_gen_pdev_set_param(struct ath10k *ar, u32 id, u32 value)
 	struct sk_buff *skb;
 
 	if (id == WMI_PDEV_PARAM_UNSUPPORTED) {
-		ath10k_warn(ar, "pdev param %d not supported by firmware\n",
-			    id);
+		ath10k_dbg(ar, ATH10K_DBG_WMI,
+			   "pdev param %d not supported by firmware\n", id);
 		return ERR_PTR(-EOPNOTSUPP);
 	}
 

---
base-commit: a3ddbb45768717b5c9f923489387cf55c838d1ad
change-id: 20261104-b4-ath10k-unsupported-pdev-param-4a1b9e3eb1fe

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

