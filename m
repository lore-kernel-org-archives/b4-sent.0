From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 26 May 2025 20:22:26 -0500
Subject: [PATCH] arm64: tegra: Set usb micro-b port to otg mode on P3450
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250526-p3450-otg-v1-1-acb80ca2dc63@gmail.com>
X-B4-Tracking: v=1; b=H4sIANETNWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDU0Nj3QJjE1MD3fySdN0kSxPzNGNDCxPjFAsloPqCotS0zAqwWdGxtbU
 Awu937VsAAAA=
X-Change-ID: 20250513-p3450-otg-b947f31843d8
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748308948; l=1025;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=1JUbkjCUHsRo77ibOj1eVsP3iKgmrocVJ93H88m4fC0=;
 b=1B6zbjxZikNUuRqKQI3D6EJGN/aUM7kbA1Qip2nE4pcdfC923tP0mgJaqiq5sRK2mtEL1XTvK
 nY0YsXz6I3pAgCQgN3Gy/cWNxJFqlP3aqDLdK//zfVEScAXCHCuL6jP
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usb micro-b port on p3450 is capable of otg and doesn't need
hardcoded to peripheral. No other supported tegra device is set up like
this, so align for consistency.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
index 0ecdd7243b2eb1abba9adbe9a404b226c29b85ef..019484a271c396edc30200e8592c713455a8e1a4 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
@@ -514,7 +514,7 @@ pcie-6 {
 		ports {
 			usb2-0 {
 				status = "okay";
-				mode = "peripheral";
+				mode = "otg";
 				usb-role-switch;
 
 				vbus-supply = <&vdd_5v0_usb>;

---
base-commit: 405e6c37c89ef0df2bfc7a988820a3df22dacb1b
change-id: 20250513-p3450-otg-b947f31843d8

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

