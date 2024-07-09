From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/2] Watchdog: support for Amlogic SoC A4/A5
Date: Tue, 09 Jul 2024 16:48:24 +0800
Message-Id: <20240709-a4-a5_watchdog-v1-0-2ae852e05ec2@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFj5jGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDcwNL3UQT3UTT+PLEkuSMlPx0XeNkCxPDpKRU8yRDMyWgpoKi1LTMCrC
 B0bG1tQCGKsOqYAAAAA==
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-watchdog@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Huqiang Qin <huqiang.qin@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720514906; l=641;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=7xFWmZqAPbwyctuy8n9YTTEtQ0XcaDLndPTpjsgRAmo=;
 b=bGg4Jsddpfot2LQfW1JXBFEn1k0C3vVF6gJD+SLpLPT8OdvLjTJ1uEeHADGXVrplXYvbcQMaJ
 7+HMC6RuKKKBx+uBAp0e/2t85lsGv0ukBn6d25g+ug2ZhZy2D8WIg0X
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add watchdog for Amlogic A4/A5 SoC. 
A5's watchdog is the same as A4's.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Huqiang Qin (2):
      dt-bindings: watchdog: add support for Amlogic A4 SoCs
      arm64: dts: amlogic: add watchdog node for A4 SoCs

 .../devicetree/bindings/watchdog/amlogic,meson-gxbb-wdt.yaml        | 1 +
 arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi                  | 6 ++++++
 2 files changed, 7 insertions(+)
---
base-commit: 338c92a5d1956f1841f84b86923087676d1d0cea
change-id: 20240709-a4-a5_watchdog-3c841bbe7b16

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

