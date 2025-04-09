From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 09 Apr 2025 17:57:24 -0500
Subject: [PATCH v3 3/4] arm64: tegra: Add CEC controller on Tegra210
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250409-tegra-cec-v3-3-91640131dfa2@gmail.com>
References: <20250409-tegra-cec-v3-0-91640131dfa2@gmail.com>
In-Reply-To: <20250409-tegra-cec-v3-0-91640131dfa2@gmail.com>
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744239446; l=999;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=bblG65p7/xkPR55OcOIBpt0KSwsSdM49hsWkcsMIg5A=;
 b=P3u9NV0614vLxzoqbUnCwqdkboJF+ta7CovsH752XtpwlOyF0mMjlOnGKt2oUB+o6QLdJbdS6
 9tpt+z/QRslD/WJqK4JvuPLIMp9ZUKuIUR9/XoSC2WBteSte4UmIQIm
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CEC controller found on Tegra210 can be used to control consumer
devices using the HDMI CEC pin.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210.dtsi | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210.dtsi b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
index b6c84d195c0ef9ae90721fada09ffd46a9c11fa3..402b0ede1472af625d9d9e811f5af306d436cc98 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
@@ -959,6 +959,15 @@ fuse@7000f800 {
 		reset-names = "fuse";
 	};
 
+	cec@70015000 {
+		compatible = "nvidia,tegra210-cec";
+		reg = <0x0 0x070015000 0x0 0x1000>;
+		interrupts = <GIC_SPI 3 IRQ_TYPE_LEVEL_HIGH>;
+		clocks = <&tegra_car TEGRA210_CLK_CEC>;
+		clock-names = "cec";
+		status = "disabled";
+	};
+
 	mc: memory-controller@70019000 {
 		compatible = "nvidia,tegra210-mc";
 		reg = <0x0 0x70019000 0x0 0x1000>;

-- 
2.48.1

