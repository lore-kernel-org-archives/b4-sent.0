From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH ath-next 0/2] wifi: ath11k/ath12k: don't bit-reverse the
 firmware's PPE thresholds
Date: Wed, 04 Nov 2026 23:17:25 -0600
Message-Id: <20261104-ath-ppe-thresholds-bit-order-v1-0-0f569106cbc4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGUR7GoC/yXMQQrCMBCF4auUWTvQ1LRSryJdpMloRiQpM1EKp
 Xc31eXP430bKAmTwrXZQOjDyjnVMKcGfHTpQcihNnRtNxjTWnQl4rIQliikMb+C4swFswQStOf
 B+XH0/cX2UIlF6M7rj7/B8Uy0Fpj+i77nJ/ly6LDvX7Fh+GyKAAAA
X-Change-ID: 20261104-ath-ppe-thresholds-bit-order-436ac99c5745
To: Jeff Johnson <jjohnson@kernel.org>, John Crispin <john@phrozen.org>, 
 Kalle Valo <kvalo@kernel.org>, 
 Shashidhar Lakkavalli <slakkavalli@datto.com>, 
 P Praneesh <quic_ppranees@quicinc.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 Karthikeyan Periyasamy <quic_periyasa@quicinc.com>, 
 Wen Gong <quic_wgong@quicinc.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Carl Huang <quic_cjhuang@quicinc.com>, 
 Ramya Gnanasekar <quic_rgnanase@quicinc.com>, 
 Balamurugan Selvarajan <quic_bselvara@quicinc.com>, 
 ath12k@lists.infradead.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793855845; l=877;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=m5qCJPR3zlN0I7usffBzkGSY2j42Ch9xFnvpnWZIrgk=;
 b=Z5yw6rhxUKTbuG0OPSbwUlFkZrVc4kVxxzD251A+6dAgW9FmfUZDyL05ogaZtDXVlN+ZWBzfG
 dD863UmHCdvAL086gJi8kz2T7tvy2dIbvyVY9oa5IZH2rfXEtyEG7sM
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k and ath12k build the PPE Thresholds field of their HE
capabilities from the firmware's WMI layout with each 3-bit threshold
bit-reversed (QPSK and 256-QAM swap places, 64-QAM becomes reserved),
while a peer's thresholds are converted the right way. Firmware that
reports 0 and 7 only, as IPQ8074 and QCN9074 do, hides it. One patch
per driver.

---
Christopher Griffin (2):
      wifi: ath11k: don't bit-reverse the firmware's PPE thresholds
      wifi: ath12k: don't bit-reverse the firmware's PPE thresholds

 drivers/net/wireless/ath/ath11k/mac.c | 3 +--
 drivers/net/wireless/ath/ath12k/mac.c | 3 +--
 2 files changed, 2 insertions(+), 4 deletions(-)
---
base-commit: a3ddbb45768717b5c9f923489387cf55c838d1ad
change-id: 20261104-ath-ppe-thresholds-bit-order-436ac99c5745

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

