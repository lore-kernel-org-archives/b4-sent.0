From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Thu, 28 Aug 2025 22:25:50 +0200
Subject: [PATCH] arm64: dts: qcom: msm8976-longcheer-l9360: Add touch keys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250828-l9360_touch_keys-v1-1-1ce5a279c399@apitzsch.eu>
X-B4-Tracking: v=1; b=H4sIAE27sGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyML3RxLYzOD+JL80uSM+OzUymJdC7MUY8uk1KQ0czMjJaC2gqLUtMw
 KsJHRsbW1AHibYtBiAAAA
X-Change-ID: 20250828-l9360_touch_keys-86d39bebf762
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756412793; l=1031;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=vTTtjCb8Z411MNaWmMrf5RO0vPAzikIEIVbV7jqgHjA=;
 b=GQmcnVaxe4XlTIV3hXAuGd8f+NaEBGwQTFW/0HdMjpWDp5q3CDOIExKIPF8y1k3AhkRvvnfpM
 TqM3LRDbUVEA1GeM0Il7ypAMDopRVre7eGirUKhVpETU1iXjVDpEdn0
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The phone has three capacitive buttons on the screen bezel. Enable them
by adding the keycodes in the dt.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 arch/arm64/boot/dts/qcom/msm8976-longcheer-l9360.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/msm8976-longcheer-l9360.dts b/arch/arm64/boot/dts/qcom/msm8976-longcheer-l9360.dts
index e524d58cf0a4b7693741036e3988700559a507f0..18832a3b9a1c37d1c891bce64d1a9372e5be439e 100644
--- a/arch/arm64/boot/dts/qcom/msm8976-longcheer-l9360.dts
+++ b/arch/arm64/boot/dts/qcom/msm8976-longcheer-l9360.dts
@@ -190,6 +190,12 @@ rmi4-f12@12 {
 			reg = <0x12>;
 			syna,sensor-type = <1>;
 		};
+
+		rmi4-f1a@1a {
+			reg = <0x1a>;
+			/* Keys listed from right to left */
+			linux,keycodes = <KEY_APPSELECT KEY_HOMEPAGE KEY_BACK>;
+		};
 	};
 };
 

---
base-commit: 8cd53fb40a304576fa86ba985f3045d5c55b0ae3
change-id: 20250828-l9360_touch_keys-86d39bebf762

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

