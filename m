From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH 0/2] wifi: ath11k/ath12k: don't leave a monitor started
 when its stop fails
Date: Thu, 05 Nov 2026 12:12:21 -0600
Message-Id: <20261105-ath-monitor-unassign-v1-0-277f0fbadb91@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAbH7GoC/yXM0QqCQBBG4VeRuW7ANRLpVaKL0f50gmZjZ5VAf
 He3vPwuzlnJkRRO12qlhEVdoxWEU0XDJDaC9VFMTd20IdQXljzxO5rmmHg2cdfRuAXk3PVAkI5
 K+kl46ve/vd0P+9y/MOTfi7ZtB7y3T654AAAA
X-Change-ID: 20261105-ath-monitor-unassign-6eea38bee1a8
To: Jeff Johnson <jjohnson@kernel.org>, 
 Vasanthakumar Thiagarajan <vasanthakumar.thiagarajan@oss.qualcomm.com>, 
 Jouni Malinen <quic_jouni@quicinc.com>, Kalle Valo <kvalo@kernel.org>, 
 P Praneesh <quic_ppranees@quicinc.com>, 
 Ramya Gnanasekar <quic_rgnanase@quicinc.com>, 
 Wen Gong <quic_wgong@quicinc.com>, 
 Karthikeyan Periyasamy <quic_periyasa@quicinc.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 ath12k@lists.infradead.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793902344; l=1139;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=WeRf9b45ChxpBsM73VYTLNwPQgkMOLOEYToX9qAV0xk=;
 b=hnoBS4p00Pof2V4tXGckfxiEGJHvqOtZd66HQTJSo5geyMHYnenMRX4tGqdAvAmcM1y8UDW4a
 4+0m/a3PaDNAlMwjJa6OUBU8qaHxusjCF6xCj5hwHRuJcDvdg/tkqZt
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the monitor vdev stop fails in unassign_vif_chanctx(), ath11k and
ath12k return with the vif (link) still marked started, although
mac80211 has released the channel context. The next assignment then
warns and fails with -EBUSY.

A firmware crash during a monitor channel change hits it reliably:
three of three simulated asserts on a QCN9074 with a monitor interface
changing channel every few hundred milliseconds took this path. With
patch 1, none warned and every recovery completed (before: a WARNING
each time). Patch 2 makes the same change in ath12k, compile-tested
only (W=1).

---
Christopher Griffin (2):
      wifi: ath11k: don't leave a monitor vif started when its stop fails
      wifi: ath12k: don't leave a monitor link started when its stop fails

 drivers/net/wireless/ath/ath11k/mac.c |  6 ++----
 drivers/net/wireless/ath/ath12k/mac.c | 12 +++++-------
 2 files changed, 7 insertions(+), 11 deletions(-)
---
base-commit: 5c8eab13e391aaabd5a1ad58f3ee4bb10ce7573e
change-id: 20261105-ath-monitor-unassign-6eea38bee1a8

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

