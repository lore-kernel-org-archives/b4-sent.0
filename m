From: David Heidelberg <david@ixit.cz>
Date: Sat, 06 Dec 2025 18:45:43 +0100
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-oneplus: Add framebuffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251206-sdm845-oneplus-fb-v1-2-19b666b27d6e@ixit.cz>
References: <20251206-sdm845-oneplus-fb-v1-0-19b666b27d6e@ixit.cz>
In-Reply-To: <20251206-sdm845-oneplus-fb-v1-0-19b666b27d6e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sam Day <me@samcday.com>, 
 David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2406; i=david@ixit.cz;
 h=from:subject:message-id; bh=rrT7ytPa8q04GSMrJJ0tu20H+CT5C22LiaLq8ch1oeg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNGvIwvrjxnybyV+5Ie6X+UsvEf6WoFairuFHb
 VtC3a2pgBWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTRryAAKCRBgAj/E00kg
 ci2PEACAD1rkoO5KlmC5H3oAo7+DcwNfouUEIby3XS91MK584M4HRNgFLxfjEaE9WDZRBhBqepy
 RJvgtV5jUDHR/1SD4FrsOKzbhnFRWtRMnfpAFhxD5vXHe8/03DBmnJKu0Bd6FQjJMQ9OwjOsQ90
 GCA7576aqfAXv48THr+MvhaAdpgUY7/+/dNr0CM+Fw7L0HU0/ReJZusi+Mrnjf7gqVGqIi8ocqA
 gfZnHeBTeFNbuZJkAR8gh+T2Y5kgLGRerq+Xp2Mov50Pik3GJ5kEpecUOLQ5QI4Rw32Sj3NPPRA
 rTeGaegCvrwGFPME2DGFRSHKFYWGhcS38Cbr9B0BKcxDyD5z6svy1jBJWRDgu5f0j2ydM+S03ng
 vZmnFca0wOuNHjh39LM63CC/BmMTNN2df146Os0NvIe8spiA/xWOrnavCxuyyhQ8w9g+7QABZHZ
 3HZ6rIQkl9kvB0z+TtQjPfYeiP2ZW4/rNqEhoQkn1ONt9xo+5RbgEkEvj0+ci4yzvN9YcfAqXy+
 tSzoYHwhZyRfJFeyiqmPLCvvvI4/w4ihWEvw/mebUYNKLZ1vsdkO+WwhISYbCgcYHn1owCHXZ5n
 UbZ3fqXAFM1GMapyIhA/xte1RPJbARFR8+1PRL43cfDnvB5fF+W0SN5SWel+fhQH3awCmBqg+Mw
 q/ftdoRsKqXij3A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sam Day <me@samcday.com>

Introduce the framebuffer node, mostly useful for the u-boot and early
boot stages.

Signed-off-by: Sam Day <me@samcday.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi   | 18 ++++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts |  4 ++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts    |  4 ++++
 3 files changed, 26 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index db6dd04c51bb5..f3884bbcfa9af 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -31,7 +31,20 @@ aliases {
 	};
 
 	chosen {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
 		stdout-path = "serial0:115200n8";
+
+		framebuffer: framebuffer@9d400000 {
+			compatible = "simple-framebuffer";
+			memory-region = <&cont_splash_mem>;
+
+			format = "a8r8g8b8";
+			stride = <(1080 * 4)>;
+			width = <1080>;
+		};
 	};
 
 	gpio-hall-sensor {
@@ -75,6 +88,11 @@ key-vol-up {
 	};
 
 	reserved-memory {
+		cont_splash_mem: splash@9d400000 {
+			reg = <0 0x9d400000 0 0x02400000>;
+			no-map;
+		};
+
 		/*
 		 * The rmtfs memory region in downstream is 'dynamically allocated'
 		 * but given the same address every time. Hard code it as this address is
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index c6b1edea2809d..ac91775f7a692 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -40,6 +40,10 @@ &display_panel {
 	status = "okay";
 };
 
+&framebuffer {
+	height = <2280>;
+};
+
 &i2c4 {
 	status = "okay";
 
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index d6cd873aef0de..0542333a83579 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -35,6 +35,10 @@ &display_panel {
 	compatible = "samsung,s6e3fc2x01-ams641rw", "samsung,s6e3fc2x01";
 };
 
+&framebuffer {
+	height = <2340>;
+};
+
 &i2c4 {
 	/* nxp,tfa9894 @ 0x34 */
 };

-- 
2.51.0

