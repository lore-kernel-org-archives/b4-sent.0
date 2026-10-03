From: Amit Sunil Dhamne <amitsd@google.com>
Date: Sat, 03 Oct 2026 06:48:30 +0000
Subject: [PATCH] arm64: dts: exynos: gs101-pixel-common: add USB-C PD timer
 and revision properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-gs101-typec-pd-timers-v1-1-4b6f3235133d@google.com>
X-B4-Tracking: v=1; b=H4sIAD2lwGoC/x3MQQ5AMBBA0avIrE3SjiBcRSxoB7NA0xEh4u4ay
 7f4/wHlKKzQZg9EPkVl3xJsnoFbhm1mFJ8MZKgyDZU4qzUWjzuww+DxkJWjYj2YorBE3pUjpDZ
 EnuT6v13/vh8/8mLRZwAAAA==
X-Change-ID: 20260925-gs101-typec-pd-timers-7a033122dc5b
To: Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Amit Sunil Dhamne <amitsd@google.com>, 
 Badhri Jagan Sridharan <badhri@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791010111; l=1515;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=9xbB2ye8jl4WfnS5MlyteCNYJFr2A78JZIik10iTwCg=;
 b=hC9phi1LOSKX4eNRfH9g7m3NLpQtUFZflP+uQCU1uXXZYQSY8mqXKPNsFEnvcD4Aa/LZ/ruPX
 +NjF2Io45P4D+hTVkQwCOo58CLimjLoqxAPNChOX78PDL5VUNQeL9rW
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Specify the tSinkWaitCap, tPSSourceOff and tCCDebounce timer values
for the USB-C connector via the sink-wait-cap-time-ms,
ps-source-off-time-ms and cc-debounce-time-ms properties, so that TCPM
uses the values tuned for gs101 platform instead of the defaults.

Also add the pd-revision property to advertise support for USB Power
Delivery Specification Revision 3.1 Version 1.8.

Assisted-by: LLM
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
index a12f2b88d72d..8d2616832777 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
+++ b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
@@ -662,6 +662,10 @@ connector {
 			try-power-role = "sink";
 			op-sink-microwatt = <2600000>;
 			slow-charger-loop;
+			pd-revision = /bits/ 8 <0x03 0x01 0x01 0x08>;
+			cc-debounce-time-ms = <170>;
+			ps-source-off-time-ms = <870>;
+			sink-wait-cap-time-ms = <450>;
 			/*
 			 * max77759 operating in reverse boost mode (0xA) can
 			 * source up to 1.5A while extboost can only do ~1A.

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260925-gs101-typec-pd-timers-7a033122dc5b

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

