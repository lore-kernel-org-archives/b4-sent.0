From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Wed, 11 Nov 2026 06:00:12 +0000
Subject: [PATCH v2 6/8] arm64: dts: allwinner: orangepi-zero2: Enable GPU
 DVFS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-h616-zero2-dt-v2-6-88d8030fc975@gmail.com>
References: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
In-Reply-To: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Ryan Walklin <ryan@testtoast.com>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794376807; l=990;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=5MPJQC1S+CHiR8Bt9vkp2Zk5ZwEghmC4r8Nx+9ugUME=;
 b=87DXPy99NnGEeLVD0wtNkkEfGbzg7aHpEpdfOqHgzEVS3BS5k5Ps5iDC7Mr9PY0dpH9SFYz7H
 lWW2d9+2J7qDZ/kHX0wHgWiLG6xJ3+HHXqfdQmkVsCYT0/SFBjjg74X
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Mali-G31 on the Orange Pi Zero2 runs at a fixed clock. Include the
H616 GPU OPP table so that panfrost registers a devfreq device and
scales the GPU between 306 and 600 MHz with load. The voltage window
of every operating point overlaps the 900 to 990 mV range of the GPU
supply (AXP305 DCDCC, mali-supply).

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
index 719d6dadf7bf..ca78d094c431 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
@@ -7,6 +7,7 @@
 
 #include "sun50i-h616-orangepi-zero.dtsi"
 #include "sun50i-h616-cpu-opp.dtsi"
+#include "sun50i-h616-gpu-opp.dtsi"
 
 / {
 	model = "OrangePi Zero2";

-- 
2.55.0

