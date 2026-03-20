From: David Heidelberg <david@ixit.cz>
Date: Fri, 20 Mar 2026 17:29:07 +0100
Subject: [PATCH 3/3] arm64: dts: qcom: sdm845-shift-axolotl: Enable TFA9890
 codec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-axolotl-misc-p1-v1-3-89c9b5ecb26e@ixit.cz>
References: <20260320-axolotl-misc-p1-v1-0-89c9b5ecb26e@ixit.cz>
In-Reply-To: <20260320-axolotl-misc-p1-v1-0-89c9b5ecb26e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Alexander Martinz <amartinz@shiftphones.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=911; i=david@ixit.cz;
 h=from:subject:message-id; bh=Ov8oJIG4M8hmwoQmv1DzA7EPUBix4liphXxxKjQuoNU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvXXSAMpVqP+hZkPnDy0Q5QUS9B9CUdop9254Q
 y1WAMFu00WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab110gAKCRBgAj/E00kg
 cpiYD/0UGwtF9lcrdulCQ5uWch/L17jw1zYjmBUP6VCrwbb7elp6o5RhCPwVh7oZVMD90ivShkt
 7jyGd8iR/DCwsGUgXVRRWUrJlXypfsyVVvSYmJph033ldNwR5bexhXNcEe7Sn/ibLWkqJ3v4HEF
 An7oyoPI73pPacOlfdixDe15B8goJAc2wpKnY9JcKJDcz0PT4ZqB4Po3CwldAGK6aR+Os3THy1j
 Esgy+COP2bAMiLXkY/X7fhjmGfd39wYvow4SxeYTBS5DP1ttpFqyK0dCY1ZxsfaHH/ztfGfQiup
 VIEeSBWbxaHLnufWN6sxcHuUVLqhFEszxVt4bR0cNFuRDW+L+jNY7oOW9sJ8tq2ke7DpPcfeKy+
 yREvtOAwBgUCa1+4qMxrhoXFTlW5KK+nd9j1LU/z0rzoWeuJMxxSOP5gQrfIDfD+STpL1CsjSKS
 pmlZ8oKiJu3I7MQ5Jn4DIxHNGJCgzIuNMkpVLEoMgO/+oTRdiVyBBgQp1tGbJY2RSv8jJgJ8K33
 DLMEchJey5IkgbrdtAQN5iOVihLOSkgNVOZnYiG6k++nx4D5Ea4yOBb3Jo2wJFRGyfYJDDc7bSn
 Ir/XqX+KlXL1U3ENtDfjdimJvK7P/bgCNLGZ4pXxa2tD7IiW520BGq44j7ET8YaEdwS8V16qqXs
 mRxG8tE0ckikqow==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alexander Martinz <amartinz@shiftphones.com>

Audio amplifier TFA9890 is present on the board.

Signed-off-by: Alexander Martinz <amartinz@shiftphones.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 8d4bf858b238b..80148ff9c3788 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -459,6 +459,19 @@ &i2c10 {
 	/* SMB1355@0x0C */
 };
 
+&i2c11 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	audio-codec@34 {
+		compatible = "nxp,tfa9890";
+		reg = <0x34>;
+		vddd-supply = <&vreg_s4a_1p8>;
+		#sound-dai-cells = <0>;
+	};
+};
+
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;

-- 
2.53.0

