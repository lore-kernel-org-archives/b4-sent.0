From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Wed, 07 Sep 2022 09:40:48 -0400
Subject: [PATCH v9 3/4] arm64: dts: allwinner: h6: Add GPU OPP table
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v9-3-b88029795c86@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v9-0-b88029795c86@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v9-0-b88029795c86@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-1911d
X-Developer-Signature: v=1; a=openpgp-sha256; l=2686;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=cPb4THXWAmA0WG4dmJKAyjsXv6RQEI8fshXNA2cu9GY=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIl5id0T9vvzpcecvzQmhJvbod1tgpc3kfcpmw3KdM45VbY
 fcWxo5SFQYyLQVZMkaVsX+ymoMKHHnLpPaYwc1iZQIYwcHEKwET8vBgZVsgGvDm2mOfJvW0nnT4WRb
 /4srqc47nAXSsh16rSrW+8RBkZLrreP2aiMCnz2aLsN5PvKpfwTOXIUuphPlwgyRoVE5fMBAA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Clément Péron <peron.clem@gmail.com>

Add an Operating Performance Points table for the GPU to
enable Dynamic Voltage & Frequency Scaling on the H6.

The voltage range is set with minival voltage set to the target
and the maximal voltage set to 1.2V. This allow DVFS framework to
work properly on board with fixed regulator.

Signed-off-by: Clément Péron <peron.clem@gmail.com>
Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h6-gpu-opp.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h6-gpu-opp.dtsi
new file mode 100644
index 000000000000..a66204243515
--- /dev/null
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h6-gpu-opp.dtsi
@@ -0,0 +1,88 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+// Copyright (C) 2022 Clément Péron <peron.clem@gmail.com>
+
+/ {
+	gpu_opp_table: gpu-opp-table {
+		compatible = "operating-points-v2";
+
+		opp@216000000 {
+			opp-hz = /bits/ 64 <216000000>;
+			opp-microvolt = <810000 810000 1200000>;
+		};
+
+		opp@264000000 {
+			opp-hz = /bits/ 64 <264000000>;
+			opp-microvolt = <810000 810000 1200000>;
+		};
+
+		opp@312000000 {
+			opp-hz = /bits/ 64 <312000000>;
+			opp-microvolt = <810000 810000 1200000>;
+		};
+
+		opp@336000000 {
+			opp-hz = /bits/ 64 <336000000>;
+			opp-microvolt = <810000 810000 1200000>;
+		};
+
+		opp@360000000 {
+			opp-hz = /bits/ 64 <360000000>;
+			opp-microvolt = <820000 820000 1200000>;
+		};
+
+		opp@384000000 {
+			opp-hz = /bits/ 64 <384000000>;
+			opp-microvolt = <830000 830000 1200000>;
+		};
+
+		opp@408000000 {
+			opp-hz = /bits/ 64 <408000000>;
+			opp-microvolt = <840000 840000 1200000>;
+		};
+
+		opp@420000000 {
+			opp-hz = /bits/ 64 <420000000>;
+			opp-microvolt = <850000 850000 1200000>;
+		};
+
+		opp@432000000 {
+			opp-hz = /bits/ 64 <432000000>;
+			opp-microvolt = <860000 860000 1200000>;
+		};
+
+		opp@456000000 {
+			opp-hz = /bits/ 64 <456000000>;
+			opp-microvolt = <870000 870000 1200000>;
+		};
+
+		opp@504000000 {
+			opp-hz = /bits/ 64 <504000000>;
+			opp-microvolt = <890000 890000 1200000>;
+		};
+
+		opp@540000000 {
+			opp-hz = /bits/ 64 <540000000>;
+			opp-microvolt = <910000 910000 1200000>;
+		};
+
+		opp@576000000 {
+			opp-hz = /bits/ 64 <576000000>;
+			opp-microvolt = <930000 930000 1200000>;
+		};
+
+		opp@624000000 {
+			opp-hz = /bits/ 64 <624000000>;
+			opp-microvolt = <950000 950000 1200000>;
+		};
+
+		opp@756000000 {
+			opp-hz = /bits/ 64 <756000000>;
+			opp-microvolt = <1040000 1040000 1200000>;
+		};
+	};
+
+};
+
+&gpu {
+	operating-points-v2 = <&gpu_opp_table>;
+};

-- 
b4 0.10.0-dev-1911d
