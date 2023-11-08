From: Steev Klimaszewski <steev@kali.org>
Date: Tue, 07 Nov 2023 23:17:10 -0600
Subject: [PATCH v2] arm64: dts: qcom: sdm850-lenovo-yoga: Add
 wakeup-sources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231107-wakeup-source-v2-1-bf1562ef9367@kali.org>
X-B4-Tracking: v=1; b=H4sIANUZS2UC/3XMQQ6CMBCF4auQWVvDtKEGV96DsKgwhQmGkqmgh
 vTuVvYu/5e8b4dIwhThWuwgtHHkMOfQpwK60c0DKe5zgy61QSytermJ1kXFsEpHCivnra+cNbq
 G/FmEPL8Pr2lzjxyfQT4Hv+Fv/SdtqFAZe0dvarIX398m9+BzkAHalNIXbIqAvKkAAAA=
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Steev Klimaszewski <steev@kali.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699420633; l=1476;
 i=steev@kali.org; s=20231106; h=from:subject:message-id;
 bh=hOaVryeA8/dNuUZsiO2uJEGRMT7i9AIrp/ZBfau6X9Q=;
 b=9wHrEPFbaFJvva63VF0vjULs/N1mDpxpdj//WykGfE7qJhoLJUxnfDOBEn+bimJ4kXb7tR9r9
 OdBPKQsTZf/AKD5HmITT0TL70Hu8woeoWyRusNCeGIaFlJE5lXUfQwJ
X-Developer-Key: i=steev@kali.org; a=ed25519;
 pk=KY+JnLRNy7Hdf04yfpE5ubOsDBIIfXAWnBijkySXbb4=
X-Endpoint-Received: by B4 Relay for steev@kali.org/20231106 with auth_id=97
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The keyboard and touchpad can be used to wake the machine
up from sleep, so mark them as such in the dts file.

Signed-off-by: Steev Klimaszewski <steev@kali.org>
---
It would be nice to wake up the Lenovo Yoga C630 from suspend by hitting
the keyboard or touchpad, so this patch enables that
ability.
---
Changes in v2:
- Drop touchscreen from being a wakeup-source.
- Link to v1: https://lore.kernel.org/r/20231106-wakeup-source-v1-1-36b1f39e67fd@kali.org
---
 arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts b/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts
index 92a812b5f423..8f68c99965cd 100644
--- a/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts
+++ b/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts
@@ -392,6 +392,8 @@ tsc2: hid@2c {
 		hid-descr-addr = <0x20>;
 
 		interrupts-extended = <&tlmm 37 IRQ_TYPE_LEVEL_HIGH>;
+
+		wakeup-source;
 	};
 };
 
@@ -408,6 +410,8 @@ tsc1: hid@10 {
 
 		pinctrl-names = "default";
 		pinctrl-0 = <&i2c5_hid_active>;
+
+		wakeup-source;
 	};
 };
 
@@ -482,6 +486,8 @@ ecsh: hid@5c {
 
 		pinctrl-names = "default";
 		pinctrl-0 = <&i2c11_hid_active>;
+
+		wakeup-source;
 	};
 };
 

---
base-commit: 5cd631a52568a18b12fd2563418985c8cb63e4b0
change-id: 20231106-wakeup-source-15af6f5a6329

Best regards,
-- 
Steev Klimaszewski <steev@kali.org>

