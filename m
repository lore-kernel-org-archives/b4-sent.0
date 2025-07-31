From: David Heidelberg <david@ixit.cz>
Date: Thu, 31 Jul 2025 23:02:44 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-oneplus: Deduplicate shared
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-sdm845-msmid-v1-2-98489ece786e@ixit.cz>
References: <20250731-sdm845-msmid-v1-0-98489ece786e@ixit.cz>
In-Reply-To: <20250731-sdm845-msmid-v1-0-98489ece786e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2034; i=david@ixit.cz;
 h=from:subject:message-id; bh=NRxsP8lcA3q9aPxidLKbwvCT8KoWYD5PD4bDKiX1k74=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi9nzluXWVab2ZF96AXlNNtZs5b0Jhd2wXvKAd
 9MWu505peqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIvZ8wAKCRBgAj/E00kg
 coPdD/sEWR/Cbr7jiVyx9KDyE1/WOlKTyNv5c9dPixgDitOIbcmdjJuoxREsBRIfqqihzFvg2lW
 jXoZx3x86ZTM+PMrJiHJ+xA0u1WPiQ4urat2JBnUS9QpRHpnF6b48Ir63S3ux+aF/iFQiVjMCA7
 +lgVux3KjxJdH1JvgUEU/J2zQNYj6UjUf66axJ5hLsVuJznxseZYHgOWRLYldhAD1TGFvWUCaSV
 A/cQ/ehiliUmHpzQYM9wNCnl2IYe9T1FByKD6vdFhksDhagtkarlh6c3N2s9iolhWfPsEf8wa5G
 Ej9umspUjNQu4unWec1Hq0EwY4g0qPDcjsV/9qdAR9F6asDF7GP3KxNXFA9Lgdc2fcLE95d4cUj
 hhDWGjyQ9ztVJZAAL0Q6+JxIizJcBPNhQHuZfEM1SdPOibMW4i58SgrXPBa8vTP4LGorEksG04n
 vZGcgNmryeMO+Kgt6T7Rzo3K0L6pPjMHB4oXtW1CScnGy7GIcJiUFPJvqHgIPMtCQPtlNhgB4JQ
 dfutXZthry8mzHc8HO5fpwcwhCq8XpBeUnaKTCrdllbz62uG9Z7BAf67Teq+mbQKvsNUz52wvgv
 Ww4MpXZGQjP/KvovXJNtKFnzek0mUm2oRZkFvR0F69K4h36fz2iif9n0UBiQE04CfoKWoyx6cTl
 TPL3QTK1Y/QdDrg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both phones share same values, put them into common dtsi.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi   | 3 +++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 2 --
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts    | 2 --
 3 files changed, 3 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index b118d666e535a433f44b66c71b36e55df2ce5c80..da0052ab99e1d7ffb8ef0173b1c97d11b459b212 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -21,6 +21,9 @@
 /delete-node/ &rmtfs_mem;
 
 / {
+	chassis-type = "handset";
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
+
 	aliases {
 		serial0 = &uart9;
 		serial1 = &uart6;
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index 474759ab61043005fcabadb5c061bbd2eccb2447..cd5546b69d13d8d7f29373aebab1cfda79666900 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -10,8 +10,6 @@
 / {
 	model = "OnePlus 6";
 	compatible = "oneplus,enchilada", "qcom,sdm845";
-	chassis-type = "handset";
-	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
 	qcom,board-id = <8 0 17819 22>;
 
 	battery: battery {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index a0affaa246fea5514a00b6c37edb30c6dceb2c59..b4212626b42954e10974ec087db2b42b07979f72 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -10,8 +10,6 @@
 / {
 	model = "OnePlus 6T";
 	compatible = "oneplus,fajita", "qcom,sdm845";
-	chassis-type = "handset";
-	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
 	qcom,board-id = <8 0 18801 41>;
 
 	battery: battery {

-- 
2.50.1

