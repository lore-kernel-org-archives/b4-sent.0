From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 26 May 2025 14:06:46 -0500
Subject: [PATCH RFC] arm64: tegra: Add reserved-memory node for P3450
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250526-p3450-mts-bug-v1-1-78500613f02c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMW7NGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDUyMz3QJjE1MD3dySYt2k0nRdAyNjS5PENGPDNINEJaCegqLUtMwKsHn
 RSkFuzkqxtbUAwMoqkGQAAAA=
X-Change-ID: 20250526-p3450-mts-bug-02394af31f0a
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748286407; l=1219;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=lJ7CQIivb8F58FIvgU/VSOHUF2zLzJTp4211UVT4t2k=;
 b=4GxshBtdNZF4P2qcPsOYPmwtNXVwDr983XH7CBMrDGcFV3kIdY9ox2nDfDqYubluUY3KErMon
 Nzgh1smI6qhCMY4V7h/d/9AgM2B6L6LyRV79IamYlphtEcFTjngbb+4
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra210 L4T bootloader ram training will corrupt the in-ram kernel
dt if no reserved-memory node exists. This prevents said bootloader from
being able to boot a kernel without this node, unless a chainloaded
bootloader loads the dt. Add the node to eliminate the requirement for
extra boot stages.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
index 0ecdd7243b2eb1abba9adbe9a404b226c29b85ef..8fc995e71696f2ef5e662a21feb96ea771c7a53f 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
@@ -22,6 +22,12 @@ chosen {
 		stdout-path = "serial0:115200n8";
 	};
 
+	reserved-memory {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+	};
+
 	memory@80000000 {
 		device_type = "memory";
 		reg = <0x0 0x80000000 0x1 0x0>;

---
base-commit: 0ff41df1cb268fc69e703a08a57ee14ae967d0ca
change-id: 20250526-p3450-mts-bug-02394af31f0a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

