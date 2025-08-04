From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 03 Aug 2025 22:14:30 -0500
Subject: [PATCH v2 1/2] arm64: tegra: Add reserved-memory node for P3450
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250803-p3450-mts-bug-v2-1-6307125408c3@gmail.com>
References: <20250803-p3450-mts-bug-v2-0-6307125408c3@gmail.com>
In-Reply-To: <20250803-p3450-mts-bug-v2-0-6307125408c3@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754277275; l=1065;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=54qVLzP/hgsWFyN6spzXC2/TI27xrBRmEzvsdBu2gLA=;
 b=wfTzZuO/9ZjlrgWh7QaEyWk3Okkkkb1T1RmlMgQy798olmerOcOc4QKon4NsyIxOHgoJFIdCJ
 o3ZHMq3mnFzBwpnU43eFPoA1GrX7Et7x+ys5O5zq6XsR9JyoTBA6ijG
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

-- 
2.50.1

