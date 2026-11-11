From: Igor Velkov <iav@iav.lv>
Date: Wed, 11 Nov 2026 04:05:28 +0200
Subject: [PATCH] pinctrl: rk805: Add the platform module alias
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-rk805-pinctrl-alias-v1-1-e0c6cdd5b823@iav.lv>
X-B4-Tracking: v=1; b=H4sIAGfN82oC/x2M0QpAQBAAf0X7bOtcHPkVeVhnsdHRnqTk313mb
 R5mHoiswhHa7AHlS6LsIUmRZ+AXCjOjjMnBGuuKBOramAoPCf7UDWkTiliPpqHSOucHglQeypP
 c/7Xr3/cDlZuxA2UAAAA=
To: Linus Walleij <linusw@kernel.org>
Cc: Heiko Stuebner <heiko@sntech.de>, linux-gpio@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1626; i=iav@iav.lv;
 h=from:subject:message-id; bh=Zndba/YdME6GY+mxEHq0lf95NjIbiNPv7gf3rw4Jcj4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmfz2Z2pj24epDrzR62HVc+Wr7yZ/Bw37x9jeT+b6/tH
 TKT5a4zdpSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJzBJh+MV86o3L96szfuwu
 kg+7F35kY5XC8bgWv9bNs2O3cbddvL+HkWGJ14Zf3UsfTMkPuLS8LPP06eW2XMbas2c6H9Kf/m/
 i4SAmAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rk8xx MFD core registers the pin controller of the RK805, RK806 and
RK816 as a platform device named "rk805-pinctrl", but the driver has
neither a MODULE_ALIAS nor a platform_device_id table. Built as a module
it is never loaded on its own, and everything that uses the PMIC GPIOs
waits for it: on the Pine64 ROCK64 the gpio-leds device with both
LEDs stays in deferred probe.

The other rk8xx cell drivers (rk805-pwrkey, rk808-regulator, rtc-rk808,
clk-rk808) carry such an alias. Add one here as well.

Fixes: ea479996c79b ("pinctrl: Add pinctrl driver for the RK805 PMIC")
Cc: stable@vger.kernel.org
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on a Pine64 ROCK64 (RK805) with v7.3.4 and CONFIG_PINCTRL_RK805=m:
without the alias the module is not loaded and both LEDs stay in
deferred probe over three boots; with it the module loads at boot, both
LEDs register and the deferred list is empty.
---
 drivers/pinctrl/pinctrl-rk805.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pinctrl/pinctrl-rk805.c b/drivers/pinctrl/pinctrl-rk805.c
index 22f576337faa..694a47d95e17 100644
--- a/drivers/pinctrl/pinctrl-rk805.c
+++ b/drivers/pinctrl/pinctrl-rk805.c
@@ -700,3 +700,4 @@ MODULE_DESCRIPTION("RK805 pin control and GPIO driver");
 MODULE_AUTHOR("Xu Shengfei <xsf@rock-chips.com>");
 MODULE_AUTHOR("Joseph Chen <chenjh@rock-chips.com>");
 MODULE_LICENSE("GPL v2");
+MODULE_ALIAS("platform:rk805-pinctrl");

---
base-commit: 4bc88b10a232db13219667e69616f6d2250d5e5f
change-id: 20261111-rk805-pinctrl-alias-7d08a4266cba

Best regards,
-- 
Igor Velkov <iav@iav.lv>

