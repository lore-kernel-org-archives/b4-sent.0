From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Tue, 25 Feb 2025 08:48:24 +0100
Subject: [PATCH] input: apple_z2: Fix potential confusion in KConfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250225-z2-kconfig-v1-1-a67d9b778a6c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMd1vWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIyNT3Soj3ezk/Ly0zHRdszTzRBPztKSkFPNkJaCGgqLUtMwKsGHRsbW
 1ANwzviBcAAAA
X-Change-ID: 20250225-z2-kconfig-6f7a47fbbd7c
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740469708; l=1031;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=M+k6ONNmhncbOygKgNxDfkOOv4aJ8TjDfJ9c96zbA9I=;
 b=nSePU+uFQ961+MUI2ngin8dOOursf0PVEzo8cjbR9e4JUizGvEHwqrRG0N1BuxRYwsFz3V4uS
 2E+jZRkT/heADUIdl/0m/6geVTC3etkLTAr4bjYPycIQIzZH+E6KBza
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dependency on ARCH_APPLE and clarify the description to make it more
obvious that this is for ARM machines, not x86 ones

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/input/touchscreen/Kconfig | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/input/touchscreen/Kconfig b/drivers/input/touchscreen/Kconfig
index 6c885cc58f323b3628538d41460248f8ab1dbf7d..91a2b584dab1469a3c907c0f1accfa10c4c4a3ca 100644
--- a/drivers/input/touchscreen/Kconfig
+++ b/drivers/input/touchscreen/Kconfig
@@ -106,9 +106,9 @@ config TOUCHSCREEN_ADC
 config TOUCHSCREEN_APPLE_Z2
 	tristate "Apple Z2 touchscreens"
 	default ARCH_APPLE
-	depends on SPI
+	depends on SPI && (ARCH_APPLE || COMPILE_TEST)
 	help
-	  Say Y here if you have an Apple device with
+	  Say Y here if you have an ARM Apple device with
 	  a touchscreen or a touchbar.
 
 	  If unsure, say N.

---
base-commit: 9995b98a4b2a704fa6744d2bee9c5d50b2c33836
change-id: 20250225-z2-kconfig-6f7a47fbbd7c

