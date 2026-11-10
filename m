From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 05:36:57 +0000
Subject: [PATCH 3/8] arm64: dts: allwinner: h616: Add GPU OPP table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h616-zero2-dt-v1-3-05506d760f21@gmail.com>
References: <20261110-h616-zero2-dt-v1-0-05506d760f21@gmail.com>
In-Reply-To: <20261110-h616-zero2-dt-v1-0-05506d760f21@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Ryan Walklin <ryan@testtoast.com>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794289015; l=2428;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=23p6G19W/X5hVV956J5zGWaQGs0tQIUlVjJ9HWVYKfQ=;
 b=8apyikkzCyhldeAVIUTaFmRzkEFvnGO4kw+znwYqqhpT0t68S1QDbKycHAhn6MN99cULwYknH
 13GJTHHPRArCdEYI5rpOElmLJMgxPZzdknOrSbhz7MeuPThdomkxYCV
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the operating points of the H616/H618 Mali-G31, so that boards can
enable GPU DVFS through panfrost devfreq: 306 to 600 MHz at 810 to
950 mV. The table is the one of the vendor images (as recovered from a
KickPi K2B image, also carried by Armbian), and follows the H6 GPU OPP
table in using <target min max> voltage triplets with a common 990 mV
maximum, so a board can raise the minimum of the GPU supply without
losing operating points.

Like sun50i-h616-cpu-opp.dtsi, the table is in a separate file that
boards include once their GPU supply is described.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../boot/dts/allwinner/sun50i-h616-gpu-opp.dtsi    | 62 ++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-gpu-opp.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h616-gpu-opp.dtsi
new file mode 100644
index 000000000000..511174eee271
--- /dev/null
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-gpu-opp.dtsi
@@ -0,0 +1,62 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+// Copyright (C) 2026 Arun Iyengar <aiyengar1990@gmail.com>
+
+/ {
+	gpu_opp_table: opp-table-gpu {
+		compatible = "operating-points-v2";
+
+		opp-306000000 {
+			opp-hz = /bits/ 64 <306000000>;
+			opp-microvolt = <810000 810000 990000>;
+		};
+
+		opp-336000000 {
+			opp-hz = /bits/ 64 <336000000>;
+			opp-microvolt = <810000 810000 990000>;
+		};
+
+		opp-360000000 {
+			opp-hz = /bits/ 64 <360000000>;
+			opp-microvolt = <820000 810000 990000>;
+		};
+
+		opp-384000000 {
+			opp-hz = /bits/ 64 <384000000>;
+			opp-microvolt = <830000 810000 990000>;
+		};
+
+		opp-420000000 {
+			opp-hz = /bits/ 64 <420000000>;
+			opp-microvolt = <850000 810000 990000>;
+		};
+
+		opp-456000000 {
+			opp-hz = /bits/ 64 <456000000>;
+			opp-microvolt = <870000 810000 990000>;
+		};
+
+		opp-504000000 {
+			opp-hz = /bits/ 64 <504000000>;
+			opp-microvolt = <890000 810000 990000>;
+		};
+
+		opp-540000000 {
+			opp-hz = /bits/ 64 <540000000>;
+			opp-microvolt = <910000 810000 990000>;
+		};
+
+		opp-576000000 {
+			opp-hz = /bits/ 64 <576000000>;
+			opp-microvolt = <930000 810000 990000>;
+		};
+
+		opp-600000000 {
+			opp-hz = /bits/ 64 <600000000>;
+			opp-microvolt = <950000 810000 990000>;
+		};
+	};
+};
+
+&gpu {
+	operating-points-v2 = <&gpu_opp_table>;
+};

-- 
2.55.0

