From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Apr 2025 17:25:17 -0500
Subject: [PATCH] arm64: tegra: p2180: Explicitly enable GPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250420-tx1-gpu-v1-1-d500de18e43e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEx0BWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyMD3ZIKQ930glJdc+PEZDOzxOSkNHMTJaDqgqLUtMwKsEnRsbW1ACk
 6xWJZAAAA
X-Change-ID: 20250420-tx1-gpu-73ac66acbf74
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745187919; l=1054;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=xOP1qorYfIKy/JD/vdHL6TqHyXFrVOD0GptP/g0JEGI=;
 b=9vXoeUCh0EbCHiSvINcUZYlQArbvwD5xwC86x0cvYvS4Q04j8Q03UoJR1QPBXfqHJ6CQYA2+i
 gaSrOY0tvV4CK7LVW9Q7EOUJL/hvvOatysjCWm4sde9rYmcv9iiEUVF
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gpu node originally was explicitly left disabled as it was expected
for the bootloader to enable it. However, this is only done in u-boot.
If u-boot is not in the boot chain, this will never be enabled. Other
Tegra210 devices already explicitly enable the gpu, so make p2180 match.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi b/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi
index 9b9d1d15b0c7eafd3895f02db1bc747d7cc8923c..c57bd1356381933a16fc1ee64773961bedae957f 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi
@@ -24,6 +24,7 @@ memory@80000000 {
 
 	gpu@57000000 {
 		vdd-supply = <&vdd_gpu>;
+		status = "okay";
 	};
 
 	/* debug port */

---
base-commit: 9c32cda43eb78f78c73aee4aa344b777714e259b
change-id: 20250420-tx1-gpu-73ac66acbf74

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

