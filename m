From: Kyle Farnung <kfarnung@gmail.com>
Date: Mon, 30 Mar 2026 23:32:53 -0700
Subject: [PATCH v2] wifi: ath11k: apply existing PM quirk to ThinkPad P14s
 Gen 5 AMD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260330-p14s-pm-quirk-v2-1-ef18ce07996b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMSw7CIBSF4a00d+w1PMSkjtyH6QAptDdKQVCia
 di72LnD/yTnWyHbRDbDqVsh2UKZwtJC7Dows14mizS2BsHEkUnJMPJDxujx8aJ0Q6YVv2reC6k
 ctE9M1tF78y5D65nyM6TPxhf+W/9JhSNH44TTsjdGjOo8eU33vQkehlrrFwFGBJiqAAAA
X-Change-ID: 20260330-p14s-pm-quirk-0a51ba19235f
To: Jeff Johnson <jjohnson@kernel.org>, 
 Baochen Qiang <quic_bqiang@quicinc.com>
Cc: Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Kyle Farnung <kfarnung@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774938826; l=2024;
 i=kfarnung@gmail.com; s=20260330; h=from:subject:message-id;
 bh=goqTouCdFtdr9SNadM69GmR467yJ8YsnFiPC1yn5iAQ=;
 b=IdTKuCdL9uMN7+89uh+WWQM8YD+zhhN/m4BDbQDv4Ukh/UqXDAxT/kZFxTkgIyohPv/r4xmNp
 h+R43lTYheCDkjHeMkAMiQ3CqrP9or/GUtWD8C5oV/nlkR0bptu41P1
X-Developer-Key: i=kfarnung@gmail.com; a=ed25519;
 pk=47jis5OdLKFgZynNQVqkx1mTGiEgFTUX+MecmG9rbmE=
X-Endpoint-Received: by B4 Relay for kfarnung@gmail.com/20260330 with auth_id=706
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some ThinkPad P14s Gen 5 AMD systems experience suspend/resume
reliability issues similar to those reported in [1]. These platforms
were not previously included in the ath11k PM quirk table.

Add DMI matches for product IDs 21ME and 21MF to apply the existing
ATH11K_PM_WOW override, improving suspend/resume behavior on these
systems.

Tested on a ThinkPad P14s Gen 5 AMD (21ME) running 6.19.9.

[1] https://bugzilla.kernel.org/show_bug.cgi?id=219196
[2] https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/thinkpad-p-series-laptops/thinkpad-p14s-gen-5-type-21me-21mf/

Fixes: ce8669a27016 ("wifi: ath11k: determine PM policy based on machine model")
Cc: stable@vger.kernel.org
Signed-off-by: Kyle Farnung <kfarnung@gmail.com>
---
Changes in v2:
- Fix missing mailing list recipients (linux-wireless, ath11k, linux-kernel)
- Link to v1: https://lore.kernel.org/r/20260330-p14s-pm-quirk-v1-1-cf2fa39cc2d5@gmail.com
---
 drivers/net/wireless/ath/ath11k/core.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/core.c b/drivers/net/wireless/ath/ath11k/core.c
index 3f6f4db5b7ee1aba79fd7526e5d59d068e0f4a2e..21d366224e75904feeae6cb9c93d9ef692d127fe 100644
--- a/drivers/net/wireless/ath/ath11k/core.c
+++ b/drivers/net/wireless/ath/ath11k/core.c
@@ -1041,6 +1041,20 @@ static const struct dmi_system_id ath11k_pm_quirk_table[] = {
 			DMI_MATCH(DMI_PRODUCT_NAME, "21D5"),
 		},
 	},
+	{
+		.driver_data = (void *)ATH11K_PM_WOW,
+		.matches = { /* P14s G5 AMD #1 */
+			DMI_MATCH(DMI_BOARD_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "21ME"),
+		},
+	},
+	{
+		.driver_data = (void *)ATH11K_PM_WOW,
+		.matches = { /* P14s G5 AMD #2 */
+			DMI_MATCH(DMI_BOARD_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "21MF"),
+		},
+	},
 	{}
 };
 

---
base-commit: dbd94b9831bc52a1efb7ff3de841ffc3457428ce
change-id: 20260330-p14s-pm-quirk-0a51ba19235f

Best regards,
-- 
Kyle Farnung <kfarnung@gmail.com>

