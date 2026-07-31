From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 31 Jul 2026 10:17:09 +0200
Subject: [PATCH] platform: raspberrypi: Fix typos in Kconfig files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260731-brcm-typos-v1-1-740551aba0fe@gmail.com>
X-B4-Tracking: v=1; b=H4sIAARabGoC/yXMyw5AMBBA0V+RWWvS8Uz8ilhQg5F4pFNCxL8rl
 mdx7wVClkmgCC6wtLPwMntgGIAZ6rknxa03RDrKdB6jaqyZlDvXRVTeYpyYVGOKGfhgtdTx8c3
 K6rdszUjGvQe47wfsZBvQbgAAAA==
X-Change-ID: 20260731-brcm-typos-7d134c501516
To: Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
Cc: linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Matous Hybl <hyblmatous@gmail.com>, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785485841; l=1817;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=YKRM9m7pQ12Ss81G6YQHueSF8cBMFRNn9Gd+XSDd5BQ=;
 b=9H6aGW6hIZe9IFy/4f6RU5NoAvrII1mU7qYcMssL9dDWBboNZzamc0u4Ns27Mg4TOoSMq5WKU
 Pf4yTT3fZjeC8A/8Ak9RCz8JXIGZF/9MErHgDmn5K59gc4K5h2iQjmz
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct minor typographical errors in Kconfig help texts.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/platform/raspberrypi/Kconfig            | 4 ++--
 drivers/platform/raspberrypi/vchiq-mmal/Kconfig | 2 +-
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/platform/raspberrypi/Kconfig b/drivers/platform/raspberrypi/Kconfig
index 2c928440a47c..cdf98509cd1b 100644
--- a/drivers/platform/raspberrypi/Kconfig
+++ b/drivers/platform/raspberrypi/Kconfig
@@ -8,7 +8,7 @@ menuconfig BCM_VIDEOCORE
 	help
 		Support for Broadcom VideoCore services including
 		the BCM2835 family of products which is used
-		by the Raspberry PI.
+		by the Raspberry Pi.
 
 if BCM_VIDEOCORE
 
@@ -26,7 +26,7 @@ config BCM2835_VCHIQ
 		API, which is in turn used by several multimedia services on the
 		BCM2835 family of SoCs.
 
-		Defaults to Y when the Broadcom Videocore services are included
+		Defaults to Y when the Broadcom VideoCore services are included
 		in the build, N otherwise.
 
 if BCM2835_VCHIQ
diff --git a/drivers/platform/raspberrypi/vchiq-mmal/Kconfig b/drivers/platform/raspberrypi/vchiq-mmal/Kconfig
index c99525a0bb45..827e73a97afb 100644
--- a/drivers/platform/raspberrypi/vchiq-mmal/Kconfig
+++ b/drivers/platform/raspberrypi/vchiq-mmal/Kconfig
@@ -4,4 +4,4 @@ config BCM2835_VCHIQ_MMAL
 	help
 	  Enables the MMAL API over VCHIQ interface as used for the
 	  majority of the multimedia services on VideoCore.
-	  Defaults to Y when the Broadcomd BCM2835 camera host is selected.
+	  Defaults to Y when the Broadcom BCM2835 camera host is selected.

---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260731-brcm-typos-7d134c501516

Best regards,
--  
Kryštof Černý <cleverline1mc@gmail.com>

