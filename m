From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 14 Sep 2026 08:56:08 +0000
Subject: [PATCH] pmdomain: amlogic: Keep Amlogic A9 ETH domain always on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-a9-pwr-eth-v1-1-752005131135@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKe2p2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS0MT3URL3YLyIt3UkgxdM0MD0zQL8zTLNNNUJaCGgqLUtMwKsGHRsbW
 1AJXB/KxcAAAA
X-Change-ID: 20260914-a9-pwr-eth-6105f87f9f5e
To: Ulf Hansson <ulfh@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Qingpeng Yang <qingpeng.yang@amlogic.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789376170; l=1200;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=9qMUad9FU6+wYS82AvwnPOBXh42Rv4up5LorY693ESs=;
 b=tko0/R7PKuB0XsbGu+238gRyuJkZ2G0grG4LU/4gsM3oPW9tHndYA+300KtG/VVqHOmAvMpir
 Ar8z80zCKuDA/0AtjPVCXmk62hTUOYWVdPHEIVkPGRlzYqNptAjkhl8
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Qingpeng Yang <qingpeng.yang@amlogic.com>

Mark the A9 ethernet power domain as always-on since it is required
for ethernet online wakeup and must not be powered down.

Signed-off-by: Qingpeng Yang <qingpeng.yang@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Keep Amlogic A9 ETH domain always on.
---
 drivers/pmdomain/amlogic/meson-secure-pwrc.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pmdomain/amlogic/meson-secure-pwrc.c b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
index 133549956efa..daf09cf86335 100644
--- a/drivers/pmdomain/amlogic/meson-secure-pwrc.c
+++ b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
@@ -196,7 +196,8 @@ static const struct meson_secure_pwrc_domain_desc a9_pwrc_domains[] = {
 	SEC_PD(A9_VICP,		0),
 	SEC_PD(A9_SD_EMMC_A,	0),
 	SEC_PD(A9_SD_EMMC_B,	0),
-	SEC_PD(A9_ETH,		0),
+	/* ETH is for ethernet online wakeup, and should be always on */
+	SEC_PD(A9_ETH,		GENPD_FLAG_ALWAYS_ON),
 	SEC_PD(A9_PCIE_A,	0),
 	SEC_PD(A9_PCIE_B,	0),
 	SEC_PD(A9_NNA_4T,	0),

---
base-commit: 26b9ea4f00732908c4f87501483c20ecaaf4eca5
change-id: 20260914-a9-pwr-eth-6105f87f9f5e

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

