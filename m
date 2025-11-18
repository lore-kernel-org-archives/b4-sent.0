From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 15:52:25 +0100
Subject: [PATCH v2 1/3] arm64: dts: qcom: sdm845-oneplus: Don't mark ts
 supply boot-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-dts-oneplus-regulators-v2-1-3e67cea1e4e7@ixit.cz>
References: <20251118-dts-oneplus-regulators-v2-0-3e67cea1e4e7@ixit.cz>
In-Reply-To: <20251118-dts-oneplus-regulators-v2-0-3e67cea1e4e7@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=917; i=david@ixit.cz;
 h=from:subject:message-id; bh=5nZsCxOzB3he9zSNaWx8v74jKqawneAxQrXzh0tXKDk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHIgrjEg0fkQCIqBkfcdSiULSwWHumyZ3X+NeL
 V0pqrwy1OWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRyIKwAKCRBgAj/E00kg
 cpFQD/9FyhkhMowgn9e/ffxXz2s86xru0feIB0BULHfQk+mnbgeLADdl7zU+s/NAi/MS7rD6jbO
 /jQXwLEXI6F8JBidtMJxfDArLLZFQ7D0hZIDSPOR1fXdzpmxZAaLolh/ZWLhb6PFl5zGVfXfWGd
 vK3QizYky0X0gJv0R70+hYtkgi7pKnr+BSqXPhi23v4vUO91QuB70rW4zeMlNniNCC51AXFwWDV
 8wPsuBgslc7Rh3FZ46hXt/1kj3a7Jn1FnDFdMjQ13gDy+Blp4Ar67HSmo3ezxB7SRUfraoYf4cy
 2p02i4r9kVTshhvDX6izTmXXt7EPiO02vk3C10TnOn12yRGJ4G9wLseZEpOUTiP8gINl6iz3tnP
 9kd83iy7PJ0oI5rL4lQMOLaH6kF67DtaAK3KH/ZJ9YQwNxmJeCTa0l8ShbVs7k0zJPMjXWNennj
 667Gae4+/Hjay0oFXdzzpQtFo+vY+nkHSlMiIQvGh9ki3cULGdFX4yc5PgQ7aoFFmUsq4D8jsVE
 Psvr//Wxqp42JqB3Fg0w41z0bArLhwSYE5PGktl39kCLMb59dfZ5eFTC6g8p55PM3SSmxv6IGVq
 FxvIHp2BdwU6uZUI5bNOpkPF/i8BSY2NuD1TlqCpezolHoXrsugTp9sm65bDJn0MpOx6J6U9ePk
 mUcsrXVYZZC0dGw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The touchscreen isn't enabled by bootloader and doesn't need to be
enabled at boot, only when the driver probes, thus remove the
regulator-boot-on property.

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index db6dd04c51bb5..ee62adfa6af0b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -148,7 +148,6 @@ ts_1p8_supply: ts-1p8-regulator {
 
 		gpio = <&tlmm 88 0>;
 		enable-active-high;
-		regulator-boot-on;
 	};
 
 	panel_vci_3v3: panel-vci-3v3-regulator {

-- 
2.51.0

