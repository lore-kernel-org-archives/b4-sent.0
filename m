From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Nov 2025 16:37:46 +0100
Subject: [PATCH 1/3] arm64: dts: qcom: sdm845-oneplus: add ath10k
 calibration variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-sdm845-calibration-variants-v1-1-2c536ada77c2@ixit.cz>
References: <20251110-sdm845-calibration-variants-v1-0-2c536ada77c2@ixit.cz>
In-Reply-To: <20251110-sdm845-calibration-variants-v1-0-2c536ada77c2@ixit.cz>
To: Dylan Van Assche <me@dylanvanassche.be>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1027; i=david@ixit.cz;
 h=from:subject:message-id; bh=zaFsh51wt+u9N18DrqLw/5F/kUzi/3Xr3TCrNN/kMWQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEgbJvmP1YVaTKsdEidnX7/yIL9D+Hfj2Lu66R
 oC7vgRiTzWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRIGyQAKCRBgAj/E00kg
 cgWiD/96tkJfm1foW5WPAqFk5sPMzn/ntr9xKrQJsQOEM/ajSQiuVfIzNhwlF5LAuEV/smgLE7j
 JDvq+Q0wDuX8SCtVk/j8Jk/omDiJYwanJNfQ/Gh3p26RWbEoz714UvmIg0lzuP1v78wz3SHwIHH
 wty+kdxs6djzqCZ5vowvUwmgt+nnHQTXaYI6N5TOYFVIXSw/U4XDXCSQDwjYxVwVoWm+t31Sioc
 0DzkKQPm9oTFID/Hrsvnlo0qM8syP9sjphPW0L57Ru+q2FUAIkqNlRxJWxlimuXEJD/pbCmeMwQ
 DEP2EVV50+sQnGeIQYCJH2nSL9TKT1kVL76U8mqCX1GQmaiygv0qLJNQrBcSoB3qwtS1lhdDjMi
 XQd6t05y+gE+4rKcUY19UzxUxuIrNnW42a5UISn+cmY5WUqhrIeR9lOi+qT8QhGdyKbr6JkAUbj
 8PrksdecnQ0aDF4rGrS5fmKm5xtaJs5k+VEAfQZFpBRL5JtkuHptxwCj29Wq1zVi43QKTjLKhVx
 yhvCWUf+38V4/us49h+HjYl41ZTR2uJ/O7g/MHeC7NCqBCgk3qmjfnbtTuviu+tskQqy+udJqi1
 Edb2tOtsOfPXA65wMmZyS0Fs8pUXvHPD6tJPWJ44TByG8fnI4+GpEd4Sb57viH4ZOgo9ZFE64J9
 kTVYBzRzlzGoiVg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Dylan Van Assche <me@dylanvanassche.be>

SDM845-based Oneplus 6 and 6T have their own calibration files
for the WCN3990 WiFi/Bluetooth radio with the ath10k driver.
Add the calibration variant name to the DTS to reflect this to
allow using the calibration files from linux-firmware.

[David] Adjust the compatible as ath10k-calibration-variant is deprecated
Signed-off-by: Dylan Van Assche <me@dylanvanassche.be>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index db6dd04c51bb5..a0c2f6efec59d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -929,5 +929,6 @@ &wifi {
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
+	qcom,calibration-variant = "oneplus_sdm845";
 	qcom,snoc-host-cap-8bit-quirk;
 };

-- 
2.51.0

