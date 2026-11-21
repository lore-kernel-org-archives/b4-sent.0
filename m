From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:38:05 +0100
Subject: [PATCH v3 11/12] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-11-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=972; i=david@ixit.cz;
 h=from:subject:message-id; bh=o04iq89VavkM6zZ1sRS5syuscytR/eIqNM1KHm+uQPE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1bVQe0BIJ83CUaUBg/d1rWQ1DypQbW3xYBM
 Mr7hbwg2LWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWwAKCRBgAj/E00kg
 ctNPD/9FC5dcqjq80O+PKcJnHQwHspYIKbvSsScd+T7SoTyRMty8bXQXrCFhFEGDq6jAmDRnw7e
 6mXcr0Ph3Drj8uHrhleCrNsfMqAqsrFFX7scZhv2kzfZfIK/XiwYsv6dMEUP1Smuwsr50wo5qbn
 1g6irwbiT9uyeNT0a7NmUSRMbyooZ3llkO9dYuRA6CObW++rWbSgCpvkcyXOlf0edDmKTAkLEv3
 TIfVzVXTEfkphCjTkpQafQZnNz8Zi2k25koad2jBG/qR3+WGXjGI7E6MRqKWSq93s1QUYNunSPv
 PLSPe6dldctvZHQPfR2a1o38opwfh5G6xpu3pVzsIENipvHMojpMLWJf5MO8RotLsGbD/0MEn7a
 vbfT/ac+g6Dw72P3VDWfHmpZARLwzZTtxEj6Wmd4yvEiI7qTdQW7KG4XAfKfyIGiJ9baOM03L+U
 T1wfPH2QPcWEfVC/7oYV2vP0YeFPcd2QpxRj/ZKUzTwKS3JindWw5ZCX3Aeo9vggz2b2vKaByBZ
 h40fY1lSizv4j+f3eqRSB+kp06PD9cewkcepkmEsFRmr77bDhvnD7AdxvcaLR3pL5IBVFyLIcYN
 rW6zXis1Ee0rkDwY3SJwBzYvh3On+M5CtGvVGe3BFcyYKVBmaQ9H0/W7dbI3xmfm/HlgXG291fX
 fsUW7I446JKNX4w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 VBUS regulator on Xiaomi Poco F1.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index d57851b0b9419..98763608d5310 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -418,16 +418,23 @@ led-1 {
 	};
 };
 
 &pm8998_resin {
 	linux,code = <KEY_VOLUMEDOWN>;
 	status = "okay";
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 /* QUAT I2S Uses 1 I2S SD Line for audio on TAS2559/60 amplifiers */
 &q6afedai {
 	dai@22 {
 		reg = <QUATERNARY_MI2S_RX>;
 		qcom,sd-lines = <0>;
 	};
 };
 

-- 
2.55.0

