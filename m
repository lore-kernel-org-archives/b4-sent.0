From: David Heidelberg <david@ixit.cz>
Date: Sun, 06 Sep 2026 02:41:14 +0200
Subject: [PATCH RFC 3/4] arm64: dts: qcom: sdm845-google: Add modemsmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-modemsmem-v1-3-a3634b553841@ixit.cz>
References: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
In-Reply-To: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Acayan <mailingradian@gmail.com>, Petr Vorel <petr.vorel@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1069; i=david@ixit.cz;
 h=from:subject:message-id; bh=b+1IVxExDwgj47OWR0x+s35O/UGQ7JVi4BXYWVb7qSY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnLav0FwqvuyDjMDjQqc7bKbewTR3zwlTsGc7i
 7Yh1MVDvLGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapy2rwAKCRBgAj/E00kg
 csW/D/42fuQ/V1IPHNOfmJkuKvyDISFWUD+KCOWuWnMo6Fg8VcL3plpAoRM6qzReXDd8ZYtjoNK
 FNpDCVN0MxeUtdqNomShgpNCoe0f/dIkMflKBw6NYKjZNkrkIkjARsi5z9CMCWFS4QWrfQPhJyz
 mpnqkneOswda9DPw7iLi7X6grKWv2Py3wEmOnlB/4KPEsufF20/U06UX3vlVAKtcHRrwG7mklwL
 NlUV6qxWhg8YpiVHVpVomNrGBdb+CO3esTI4JoCiOgLyeS9JZUp5tsvzurOdI2O4VOqJ0Z7woSt
 s0tVrJOYIuSrFGl+jOFfrcXBFQHiy4iDEUpxQWw2trrogE6fVVKGFTgrQI8xYwI3n5jqPHFozij
 /G+SdfqVUU9V8P5RqeYsIQPMCy/DB2e/cvfTTDIyTqbTtbPFmni2qDAHU+JmF5So4lXCL4hgGgL
 hnwaaTt3yOs8rTEYWYRpTG1fbr0Zt7C+b05KnW5JC9Fy/pLYpZkJp8q986lkP0BItwnoWm2aarU
 G8ulGHxztD6NxFCRlPJkE4sC6MuNaX/56cch5wfvO16OGybyvCs0JZk7hRL8FfndM5ENsKMf1M/
 iScz3gwxWXQqWtS0kOcXw0AR+F2XEtahZviF5adqH2BWYTx+6m0isAUIu5mXqvUtscCPVXosw5X
 UJ4Mh/NG3bxjJCA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Pixel 3 / 3 XL modem needs the modemsmem client. Add it in the device
tree so the modem can properly boot.

Based on work of Casey Tunturi.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 9e952f9862f24..7e8f1a34a79f8 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -45,16 +45,21 @@ chosen {
 		framebuffer0: framebuffer-0 {
 			compatible = "simple-framebuffer";
 			memory-region = <&cont_splash_mem>;
 
 			format = "a8r8g8b8";
 		};
 	};
 
+	modemsmem {
+		compatible = "google,modemsmem";
+		qcom,smem-id = <134>;
+	};
+
 	reserved-memory {
 		cont_splash_mem: splash@9d400000 {
 			reg = <0 0x9d400000 0 0x02400000>;
 			no-map;
 		};
 
 		mpss_region: memory@8e000000 {
 			reg = <0 0x8e000000 0 0x9800000>;

-- 
2.55.0

