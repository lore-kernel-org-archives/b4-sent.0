From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:21 +0400
Subject: [PATCH ath-next 15/16] wifi: ath11k: define userPDs for QCN6122
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-15-86729521a75c@outlook.com>
References: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
In-Reply-To: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vignesh Viswanathan <vignesh.viswanathan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=1850;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=FFy8ewtv5YTf5rGwmTdQsDE8baSwiwHWuB1HJc5LmDg=;
 b=eb9JZnJKMBo5WqcPLeJRSCtyF0njk0iSiffFtlOIYYT01K7J5kdS4ogRDIMaEHD5UQ24RFBzR
 tTweDJTOMvWD05gXR7sMdywUriNHUgh/mQMdn3JOBDttGONvOeuiyLH
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPQ5018 platform can come with one or two optional QCN6122 wifi
cards. To differentiate the two, the user PD instance number (1 or 2) is
added to the QMI service instance ID so the QCN6122 firmware knows which
radio instance to use and on what PCIe rail it is on.

On IPQ5018/QCN6122 boards, the default mapping is as follows:

          +-> User PD 1 ----> IPQ5018 Internal 2.4G Radio
         /
        /
Root PD +---> User PD 2 ----> QCN6122 5G/6G Radio on PCIe rail 1
        \
         \
          +-> User PD 3 ----> QCN6122 5G/6G Radio on PCIe rail 0

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/ahb.c | 8 ++++++++
 drivers/net/wireless/ath/ath11k/ahb.h | 2 ++
 2 files changed, 10 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 03936f574c8d..26110c927577 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -969,6 +969,14 @@ static int ath11k_ahb_init_userpd(struct ath11k_base *ab, int userpd_id)
 
 		ab_ahb->userpd_id = userpd_id;
 		break;
+	case ATH11K_HW_QCN6122_HW10:
+		if (userpd_id != ATH11K_AHB_USERPD_ID_2 &&
+		    userpd_id != ATH11K_AHB_USERPD_ID_3)
+			return -EINVAL;
+
+		ab_ahb->userpd_id = userpd_id;
+		ab->qmi.service_ins_id += (ab_ahb->userpd_id - 1);
+		break;
 	default:
 		return -EINVAL;
 	}
diff --git a/drivers/net/wireless/ath/ath11k/ahb.h b/drivers/net/wireless/ath/ath11k/ahb.h
index 0647bdb9ea62..ec89e0e89ca0 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.h
+++ b/drivers/net/wireless/ath/ath11k/ahb.h
@@ -28,6 +28,8 @@
 
 enum ath11k_ahb_userpd_id {
 	ATH11K_AHB_USERPD_ID_1 = 1,
+	ATH11K_AHB_USERPD_ID_2,
+	ATH11K_AHB_USERPD_ID_3,
 	ATH11K_AHB_USERPD_ID_MAX,
 };
 

-- 
2.53.0

