From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 05 Nov 2026 12:12:16 -0600
Subject: [PATCH] wifi: ath11k: don't report a regulatory event skipped in
 recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ath11k-recovery-regd-skip-v1-1-621538e64760@gmail.com>
X-B4-Tracking: v=1; b=H4sIAADH7GoC/yXMQQqDQAyF4atI1gbMFIX2KsWFzmQ0FVQSKy3i3
 R11977F+zcwVmGDV7aB8iom05hAeQa+b8aOUUIyuMJVREWJzdITDajsp5X1n0YX0AaZMXIZ4tP
 To3UVpP+sHOV3td/1bfu2H/bLGYR9PwDVGkOufQAAAA==
X-Change-ID: 20261105-ath11k-recovery-regd-skip-fe5df9c13b26
To: Jeff Johnson <jjohnson@kernel.org>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Wen Gong <quic_wgong@quicinc.com>, Kalle Valo <kvalo@kernel.org>
Cc: Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902336; l=1959;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=INYaQh0/zCuDz50Z8TnNyMsCxbzCWj5WLewSHjP8/pQ=;
 b=vEjMG+X+tk6vuWZJuhIkz0ixr+TOOkGvrHC3397VTx1kysdGNC1wU6eF0r9gVQ3SFKBDbNxgo
 YLRf3SC2g1FCi4GO6+EcvspkIIfkDbxQ6E8XvBfLC8O3L4TvSyviOhZ
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During firmware recovery, ath11k_reg_handle_chan_list() deliberately
ignores the regulatory event when the radio already has its default
regd, but it does so by returning -EINVAL, so every recovery logs a
failure:

  ath11k_pci 0001:01:00.0: failed to process regulatory info -22

Before commit 7004bdceef60 ("wifi: ath11k: store cur_regulatory_info
for each radio") moved this code out of ath11k_reg_chan_list_event(),
the skip freed the event's rules and returned 0.

Do that again for the event (IEEE80211_REG_UNSET_AP), the same way as
the skip of an unchanged default regd below it. The calls from mac.c
pass the stored rules with a 6 GHz power type, never
IEEE80211_REG_UNSET_AP; they keep getting -EINVAL during recovery, and
the stored rules are left alone.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Fixes: 7004bdceef60 ("wifi: ath11k: store cur_regulatory_info for each radio")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/reg.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath11k/reg.c b/drivers/net/wireless/ath/ath11k/reg.c
index 1030e119fd903..915400afaee1a 100644
--- a/drivers/net/wireless/ath/ath11k/reg.c
+++ b/drivers/net/wireless/ath/ath11k/reg.c
@@ -903,7 +903,10 @@ int ath11k_reg_handle_chan_list(struct ath11k_base *ab,
 	if (test_bit(ATH11K_FLAG_RECOVERY, &ab->dev_flags) &&
 	    ab->default_regd[pdev_idx]) {
 		spin_unlock_bh(&ab->base_lock);
-		goto retfail;
+		if (power_type != IEEE80211_REG_UNSET_AP)
+			goto retfail;
+		ath11k_reg_reset_info(reg_info);
+		return 0;
 	}
 	spin_unlock_bh(&ab->base_lock);
 

---
base-commit: 5c8eab13e391aaabd5a1ad58f3ee4bb10ce7573e
change-id: 20261105-ath11k-recovery-regd-skip-fe5df9c13b26

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

