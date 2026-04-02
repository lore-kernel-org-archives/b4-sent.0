From: David Heidelberg <david@ixit.cz>
Date: Thu, 02 Apr 2026 11:54:08 +0200
Subject: [PATCH v3 3/3] arm64: dts: qcom: sdm845-shift-axolotl: Enable
 TFA9890 codec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-axolotl-misc-p1-v3-3-8934e9db6831@ixit.cz>
References: <20260402-axolotl-misc-p1-v3-0-8934e9db6831@ixit.cz>
In-Reply-To: <20260402-axolotl-misc-p1-v3-0-8934e9db6831@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1039; i=david@ixit.cz;
 h=from:subject:message-id; bh=/tLVCDMeEyd1l4XS4gK2AEpm3lRrSe36wHl8GBumRLY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzjy/UCJDjV9x3+R3aAu7WmjW1VThG7KIJDH8A
 XtyRUdHwPSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac48vwAKCRBgAj/E00kg
 cjiaD/9CRnzArTwe+BEjDI349N1KrFDtNd67osObrTnPgTU0xnzfkvFd2sZVXPX0LZ3F5X0uReG
 qBbsOS89FBJgpB8l2o5YVU6adBFufp7TwpMnqqw2IwqH1qWt7p/sZpYq4PtNmxQiVJM5eYaZ8od
 qudSOGeBycBJH4oDAJvavvaDMaVmQ6+ATP30EIHxRgTLrDU9lTUSgDrYjtjUousK28RfrEhnvDs
 GmnWrLT0sO5UslWy4cA4CwcO2lizcY0CJ+WlSbLPi1vVXrsAwRfIc7vX+Wfx5bJX4jWjEibxSol
 LKiLgxxSiDtltYVWJySy++p6IxgL9fUStbd/FaRFG60nToFy7GReYOqmQMuFdfDln7VdlNWgWPF
 ik17n2heKgE5KAlFmhZ0XNxWTzDH9ppl1bp/PgDC8J1bq158ckMob9H0xRJEskIDHVar0GNGpQ2
 GknWomPuDxWN2Rr6z2qrWKAOJK5Fvq6eFUyPxK+2b3nI3BEKhtDXAurGewde2Dyq+6HdK/U8nbr
 I0Ie4GXrL10pbIW4B1GxPw0D2ew4ulHc/DMe00xfgSkgtC6lf0u/iVjbkH0jr3jc+YvlGwsp4oj
 oXHz3CEx3BrRREzSOJDSBzEfmXzNiuEMvgl0NuFrciBonH2b/eUJ8UoxdcF+KsxI/tcl8G7lh/n
 nuZvOZHRjxJYjQw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alexander Martinz <amartinz@shiftphones.com>

Audio amplifier TFA9890 is present on the board.

Signed-off-by: Alexander Martinz <amartinz@shiftphones.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index f26079398e07b..7d81198bc499c 100644
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

