From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Apr 2025 09:35:37 -0500
Subject: [PATCH] arm64: tegra: Add uartd serial alias for Jetson TX1 module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250420-tx1-bt-v1-1-153cba105a4e@gmail.com>
X-B4-Tracking: v=1; b=H4sIADgGBWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0NL3ZIKQ92kEl3TNKBIonmqSXJishJQcUFRalpmBdig6NjaWgBGD1t
 MWAAAAA==
X-Change-ID: 20250419-tx1-bt-5f202a7e4cac
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Tomasz Maciej Nowak <tmn505@gmail.com>
Cc: Thierry Reding <treding@nvidia.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745159738; l=1081;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=s5PVuRKvd6CVIIO1qFvDhPIiDwgl5quGNSuOC1OhL7M=;
 b=tnSSFZwOfguUzNM3zleHB3uCj3aIawzpDFK6Qv9DPsuELzx6WbQRO825xb1LpP8J2+Y5b/eTq
 XgBvci+4zi5BTpRT+QMO9qJRCjH4K05RI9sHD5RhwIFZGHVkC4OE4wH
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a serial-tegra interface does not have an alias, the driver fails to
probe with an error:
serial-tegra 70006300.serial: failed to get alias id, errno -19
This prevents the bluetooth device from being accessible.

Fixes: 6eba6471bbb7 ("arm64: tegra: Wire up Bluetooth on Jetson TX1 module")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi b/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi
index 9b9d1d15b0c7eafd3895f02db1bc747d7cc8923c..1bb1f9640a800af6c10fabf0ee3916f2566a6d4b 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi
@@ -11,6 +11,7 @@ aliases {
 		rtc0 = "/i2c@7000d000/pmic@3c";
 		rtc1 = "/rtc@7000e000";
 		serial0 = &uarta;
+		serial3 = &uartd;
 	};
 
 	chosen {

---
base-commit: 119009db267415049182774196e3cce9e13b52ef
change-id: 20250419-tx1-bt-5f202a7e4cac

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

