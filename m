From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 29 Oct 2025 18:26:27 +0400
Subject: [PATCH 6/6] wifi: ath11k: add QCN6122 device support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251029-ath11k-qcn6122-v1-6-58ed68eba333@outlook.com>
References: <20251029-ath11k-qcn6122-v1-0-58ed68eba333@outlook.com>
In-Reply-To: <20251029-ath11k-qcn6122-v1-0-58ed68eba333@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761747997; l=1944;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=MO7KsMfpzKHk3Kbh2D8damE6MIZVTsMgz25SICdrEDs=;
 b=K3qK5c3f0lBX0CW0vl5IFl9pODMBfTzS0f2OsZsmCjYeksCdtIJiyhhes4SZWzKIzw18NU6EC
 egExsLPJIhlDMg0OgQbszxEu05a3cT04hTUgeQbovPISaaGNStZjFGi
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for QCN6122 wifi.
STA, AP, and MESH modes are supported.

Tested on: Linksys MX2000, Linksys MX6200, and GLiNET B3000 access
points for prolonged duration tests spanning multiple days with multiple
clients connected with firmware:
WLAN.HK.2.7.0.1-01744-QCAHKSWPL_SILICONZ-1

Although QCN6122 is a PCIe device, it is an IPQ5018 SoC specific
solution and uses shared IPQ5018/QCN6122 firmware.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/ahb.c  | 3 +++
 drivers/net/wireless/ath/ath11k/pcic.c | 9 +++++++++
 2 files changed, 12 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 820a383e88caf125892176e421b0121fed7e7055..6747fcdbf9a777d4214b9ef751dac2774a80c0ff 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -37,6 +37,9 @@ static const struct of_device_id ath11k_ahb_of_match[] = {
 	{ .compatible = "qcom,ipq5018-wifi",
 	  .data = (void *)ATH11K_HW_IPQ5018_HW10,
 	},
+	{ .compatible = "qcom,qcn6122-wifi",
+	  .data = (void *)ATH11K_HW_QCN6122_HW10,
+	},
 	{ }
 };
 
diff --git a/drivers/net/wireless/ath/ath11k/pcic.c b/drivers/net/wireless/ath/ath11k/pcic.c
index fc6e7da05c6028e30facf10d38a55f614067e44b..ac1e156ab3e0f0c47de1eb1ac5afea21addfd739 100644
--- a/drivers/net/wireless/ath/ath11k/pcic.c
+++ b/drivers/net/wireless/ath/ath11k/pcic.c
@@ -139,6 +139,15 @@ static const struct ath11k_msi_config ath11k_msi_config[] = {
 		},
 		.hw_rev = ATH11K_HW_QCA6698AQ_HW21,
 	},
+	{
+		.total_vectors = 13,
+		.total_users = 2,
+		.users = (struct ath11k_msi_user[]) {
+			{ .name = "CE", .num_vectors = 5, .base_vector = 0 },
+			{ .name = "DP", .num_vectors = 8, .base_vector = 5 },
+		},
+		.hw_rev = ATH11K_HW_QCN6122_HW10,
+	},
 };
 
 int ath11k_pcic_init_msi_config(struct ath11k_base *ab)

-- 
2.51.1

