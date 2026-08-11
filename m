From: Robin Snyders <robin@snyders.xyz>
Date: Wed, 12 Aug 2026 01:29:58 +0200
Subject: [PATCH 1/5] power: supply: qcom_smbx: include base when petting
 watchdog
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-qcom-smbx-fixes-v1-1-eb48246be599@snyders.xyz>
References: <20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz>
In-Reply-To: <20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786491008; l=1126;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=5e8CybsOw3LrBX999BFZbrVFBttifaKFh6Gt0NuubDo=;
 b=oy6lqXOFMCMsSLOoU2y5/zWcOFG7Eqq0F/839bPpaDZeEeHdu0Mh8siyH2921BWi2qQZhYRPd
 0rzXWQ08o0XASpYThe57fLhE/5UNhM7qjytNiybyiWizOmCjyqIOV5I
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BARK_BITE_WDOG_PET is an offset from the charger peripheral base, but
the watchdog bark handler writes it as an absolute SPMI address. This can
write another PMIC peripheral and leave the charger watchdog unserviced.

Add the charger base, as all other qcom_smbx register accesses do.

Fixes: 8648aeb5d7b7 ("power: supply: add Qualcomm PMI8998 SMB2 Charger driver")
Cc: stable@vger.kernel.org
Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 drivers/power/supply/qcom_smbx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index 67fdb43353388..e6f2328f295c7 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -764,7 +764,7 @@ static irqreturn_t smb_handle_wdog_bark(int irq, void *data)
 
 	power_supply_changed(chip->chg_psy);
 
-	rc = regmap_write(chip->regmap, BARK_BITE_WDOG_PET,
+	rc = regmap_write(chip->regmap, chip->base + BARK_BITE_WDOG_PET,
 			  BARK_BITE_WDOG_PET_BIT);
 	if (rc < 0)
 		dev_err(chip->dev, "Couldn't pet the dog rc=%d\n", rc);

-- 
2.54.0

