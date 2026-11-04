From: David Heidelberg <david@ixit.cz>
Date: Wed, 04 Nov 2026 13:54:45 +0100
Subject: [PATCH RFC 3/3] arm64: dts: qcom: sdm845-shift-axolotl: Wake the
 system on a touchscreen double tap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ft5x06-double-tap-v1-3-5a1bd80449cc@ixit.cz>
References: <20261104-ft5x06-double-tap-v1-0-5a1bd80449cc@ixit.cz>
In-Reply-To: <20261104-ft5x06-double-tap-v1-0-5a1bd80449cc@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1038; i=david@ixit.cz;
 h=from:subject:message-id; bh=gVCDyYfuQzZ+YQquXafcJW7FFenl4GNi6oZKBwhfrWI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq6ytMe815RX1a0N0eshGYgGeLRlEwiMcSDon56
 mBRBAXxnT6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCausrTAAKCRBgAj/E00kg
 cqm4D/9hDSLf2LwEVC9LRzcuRML9wLXa9giF1R67yIzc+wlg0RuW6V+WNfwYs2VAWREjIsYemqx
 1RwzoA46JMZEhNgxSxM8hGauxekMiuuJ76lBpBg2hiRIo78V8sdjiR3S2VftxQUzry2IhDlDO5X
 q4yRTKnaknvOTBIy/dQsldPRWqusokHEf6Fif/HnE3MUxSDcApky/o+ZaEZvgr4k1ODn3DbQVZ/
 ygwhqwH0HmP382ABkLUfQ0LEV+Ml2W1mv//ftrj78qlcpMFAKbixuM6Ssz4vR+JssMW110XmgYZ
 Z6t/7zwotfdbfd61wLiGnLeyGlRhNEhMn6elfCiFXR0HEUW0YVyz9SCNv0h7tEnTP/fXV0sh+DD
 wIDpNF73S6xMNjZ1giIi+BFu2G1cI8HwUdHnDoZtImte4AtfDhoUi9ECq4a6DOmjf0U1KLiQ47h
 NBWSPPWMqbi7IFxlEK/B8AyqNhy4GTcvYBa3DJ6zDci72pmftDYF1adtMVT545gnXcxkP1BpQCD
 sGvCAU8c1xhr6TF6lWPBTEexm6axM/9Xr8Hc+1pLmNgwjTFURn3zXCowdiBL3+Fidi2263oKA3T
 GtgQOdnsDHJF0lMg7owte2up+yHxR6txVhA+Hit+o6UxTYeudJM+nH6qfSzsIcNS9E1uJXTqy8P
 xdTasBdQuiARQPg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The touch interrupt on GPIO 125 is routed to the PDC, so the panel can
wake the phone. Report the controller's double tap gesture as
KEY_WAKEUP.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 1b0eaeafbd517..e4eef60271c55 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -504,16 +504,22 @@ touchscreen@38 {
 		iovcc-supply = <&vreg_l14a_1p88>;
 
 		pinctrl-0 = <&ts_int_active &ts_reset_active>;
 		pinctrl-1 = <&ts_int_suspend &ts_reset_suspend>;
 		pinctrl-names = "default", "sleep";
 
 		touchscreen-size-x = <1080>;
 		touchscreen-size-y = <2160>;
+
+		wakeup-source;
+
+		event-tap-double {
+			linux,code = <KEY_WAKEUP>;
+		};
 	};
 };
 
 &i2c10 {
 	/* SMB1355@0x0C */
 };
 
 &i2c11 {

-- 
2.55.0

