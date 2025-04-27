From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 26 Apr 2025 19:45:32 -0500
Subject: [PATCH] arm64: tegra: p3310: Explicitly enable GPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250426-tx2-gpu-v1-1-fa1c78dcdbdc@gmail.com>
X-B4-Tracking: v=1; b=H4sIACt+DWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyMz3ZIKI930glJdw5S0lBQLE0OLJENDJaDqgqLUtMwKsEnRsbW1AHc
 nTzZZAAAA
X-Change-ID: 20250426-tx2-gpu-1dfdd8418b11
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745714735; l=1085;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=1qwq1cir+VfwVl8dxdzM8N5/93zGvcNjh8ZMxb/dTUA=;
 b=/3z+hRDAhqVhbJV7GtS0ycYT8SD07OitzJS9dZ0VpCAlSDVL13n+LmOziCze6bnicQ5Io0DDN
 he4ClbHSx2YA1sOUozlsS8qjeR/rhh6ql13r1nOWL3VI+WjQuigWeyd
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gpu node originally was explicitly left disabled as it was expected
for the bootloader to enable it. However, this is only done in u-boot.
If u-boot is not in the boot chain, this will never be enabled. Other
Tegra186 devices already explicitly enable the gpu, so make p3310 match.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra186-p3310.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra186-p3310.dtsi b/arch/arm64/boot/dts/nvidia/tegra186-p3310.dtsi
index e2d6857a37097c5acc38dcbfd12800d59510f1c6..8aec6999603059107ba05cdbbe8bb497e3824a06 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186-p3310.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra186-p3310.dtsi
@@ -191,6 +191,10 @@ pmc@c360000 {
 		nvidia,invert-interrupt;
 	};
 
+	gpu@17000000 {
+		status = "okay";
+	};
+
 	bpmp {
 		i2c {
 			status = "okay";

---
base-commit: 5bc1018675ec28a8a60d83b378d8c3991faa5a27
change-id: 20250426-tx2-gpu-1dfdd8418b11

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

