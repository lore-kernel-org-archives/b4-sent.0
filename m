From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Nov 2025 22:53:39 +0100
Subject: [PATCH RFC 6/8] arm64: dts: qcom: sdm845-shift-axolotl: Enable
 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-pmi8998_fuel_gauge-v1-6-dd3791f61478@ixit.cz>
References: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
In-Reply-To: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Casey Connolly <casey@connolly.tech>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Richard Acayan <mailingradian@gmail.com>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=839; i=david@ixit.cz;
 h=from:subject:message-id; bh=rWr9w6N0g0uoz/ni0a7604nlr6yXoa+VTp7KmyJxlrg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJNPgFlWsPm3iSNWe01qiE1zdx1ltKOFn190HJ
 Ko0UM3Acv2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSTT4AAKCRBgAj/E00kg
 clyfD/97XwPy2exVdqPOI880Z1tW0zR9atPBY9VnosC07OH1VVQcky95MsrBcCE/fBhCW8aX7nj
 RCOWtBkbF5zvq7wYDMQK36Y9VlXLgCdLDTGzWdF2rHsYgKNX38QqarS+H4ZsSF1Cm99ZDCoxbYd
 meBvz/QARBVI6tbe7kZlRoGw1koasx1e666/IrVD7LxmnmwttuMHw6DIUiFqwOXyhUMZ2eVMS+y
 mUjtlm52nsvAbIqjJKNAjjVDvZTsPOr5kFQeKEVnJSYkrZT363haXBlm4ej6j9KjoyO+iij5jOE
 i5pnBtu/RU9IHSyqmeYK+JkyPLJJEeybhgXpB0Y5lP/iVmJUm4ULWXo95vM3yJROdrbxyMX8IGi
 PXP1bfG7Q1Mu44WghOg9oE6c9Gx0GGhJKwF4h3Y8aHqrUwbbA2k+m9vj5+/a4WRLGAdhctrpBTm
 nrVZ67rqaVGJnpBpdsd0NUnon9j9deQo3beU7q6wXl84gavQ1Ab+Og9/89oya9TgSM4d0ObMHeq
 3k/D4Saa3SACtsZht6Pbs6XQnVeVc0OC8y7i55pQwBrwPR3CPmPkIQVcGPZvv4MLA3TOxxvgogM
 pPdAu59AadhcElCCa42nKLdlLJfJk8Z9F3VFjE02PAYMBIcp3zhbdvZOISrAKzlwa2uRO5jGbI4
 YAQe9Eatm5bGZbg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Enable the fuel gauge and configure the associated charger and battery.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index ddc2b3ca3bc57..f1fea39972e8c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -524,6 +524,13 @@ &pmi8998_charger {
 	status = "okay";
 };
 
+&pmi8998_fg {
+	power-supplies = <&pmi8998_charger>;
+	monitored-battery = <&battery>;
+
+	status = "okay";
+};
+
 &pm8998_resin {
 	linux,code = <KEY_VOLUMEDOWN>;
 	status = "okay";

-- 
2.51.0

