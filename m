From: Janne Grunau <j@jannau.net>
Date: Thu, 18 Apr 2024 21:00:28 +0200
Subject: [PATCH v2 4/5] arm: apple: Switch to standard boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240418-apple_config-v2-4-7e5c6b9a9db3@jannau.net>
References: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
In-Reply-To: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1472; i=j@jannau.net;
 h=from:subject:message-id; bh=bpZhuGl0+MTgE6TV+2Z005nzV5o0C5mfHTMqAQmaZOs=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhjTF3NObHu5eFxfXontTcIfmA73dhqJvlnRzFQZVP/Oxv
 ML+PDGvo5SFQYyLQVZMkSVJ+2UHw+oaxZjaB2Ewc1iZQIYwcHEKwEReb2FkODrDcsXX/euUTdps
 J3PZOD+NmzWtd6WCTODZCdrHq6bM2c7I0Ph+6pft02O7G7xDZ7Kn/dpXsVTotZ205Nd63QOfHX8
 u5QUA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use standard boot instead of the distro boot scripts. Use
BOOTSTD_FULL instead of BOOTSTD_DEFAULTS for easier interactive use.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm/Kconfig        |  2 +-
 include/configs/apple.h | 20 ++------------------
 2 files changed, 3 insertions(+), 19 deletions(-)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 01d6556c42..9b83b2e6f8 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1034,7 +1034,7 @@ config ARCH_APPLE
 	select USB
 	imply CMD_DM
 	imply CMD_GPT
-	imply DISTRO_DEFAULTS
+	imply BOOTSTD_FULL
 	imply OF_HAS_PRIOR_STAGE
 
 config ARCH_OWL
diff --git a/include/configs/apple.h b/include/configs/apple.h
index a70440b3ad..1e08b11448 100644
--- a/include/configs/apple.h
+++ b/include/configs/apple.h
@@ -9,26 +9,10 @@
 	"stdout=vidconsole,serial\0" \
 	"stderr=vidconsole,serial\0"
 
-#if IS_ENABLED(CONFIG_CMD_NVME)
-	#define BOOT_TARGET_NVME(func) func(NVME, nvme, 0)
-#else
-	#define BOOT_TARGET_NVME(func)
-#endif
-
-#if IS_ENABLED(CONFIG_CMD_USB)
-	#define BOOT_TARGET_USB(func) func(USB, usb, 0)
-#else
-	#define BOOT_TARGET_USB(func)
-#endif
-
-#define BOOT_TARGET_DEVICES(func) \
-	BOOT_TARGET_NVME(func) \
-	BOOT_TARGET_USB(func)
-
-#include <config_distro_bootcmd.h>
+#define BOOT_TARGETS	"nvme usb"
 
 #define CFG_EXTRA_ENV_SETTINGS \
 	ENV_DEVICE_SETTINGS \
-	BOOTENV
+	"boot_targets=" BOOT_TARGETS "\0"
 
 #endif

-- 
2.44.0

