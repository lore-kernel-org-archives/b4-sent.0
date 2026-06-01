From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:57 +1000
Subject: [PATCH RESEND 16/16] button: remap phone HOMEPAGE button
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-16-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=1243;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=zFKECPQUM7NXvjsAPsLT2XslIs2BY83r61O3tGD/uCE=;
 b=M9ItX/5UZSwvRutBeR32p/VPoxOYEMDcaq5ri5tzw2TR8KMbLOvccUDKqXrr8U29ePmlHWbsS
 DIfOKdOXokQB2z+wITnbfgYNKFDOgEevYHqaGOqgpbYfi62HyEH1U81
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If I'm being honest, I thought of doing this primarily because I
haven't wired up the PMIC power button on my samsung-expressltexx yet.
But, I think it does make sense to remap the center button on older
Android phones to act as the Enter key anyway.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/button/Kconfig         | 2 +-
 drivers/button/button-uclass.c | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/button/Kconfig b/drivers/button/Kconfig
index 6cae16fcc8b..8e6bab74cf1 100644
--- a/drivers/button/Kconfig
+++ b/drivers/button/Kconfig
@@ -18,7 +18,7 @@ config BUTTON_REMAP_PHONE_KEYS
 	  are remapped to the following navigation keys:
 	  - Volume up: Up
 	  - Volume down: Down
-	  - Power: Enter
+	  - Home/Power: Enter
 
 config BUTTON_ADC
 	bool "Button adc"
diff --git a/drivers/button/button-uclass.c b/drivers/button/button-uclass.c
index 025917887e8..4e37180fc09 100644
--- a/drivers/button/button-uclass.c
+++ b/drivers/button/button-uclass.c
@@ -45,6 +45,7 @@ static int button_remap_phone_keys(int code)
 		return KEY_UP;
 	case KEY_VOLUMEDOWN:
 		return KEY_DOWN;
+	case KEY_HOMEPAGE:
 	case KEY_POWER:
 		return KEY_ENTER;
 	default:

-- 
2.54.0

