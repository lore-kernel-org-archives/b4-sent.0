From: David Heidelberg <david@ixit.cz>
Date: Wed, 11 Mar 2026 19:44:29 +0100
Subject: [PATCH 1/2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Introduce
 framebuffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-beryllium-fb-v1-1-408a580d125e@ixit.cz>
References: <20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz>
In-Reply-To: <20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1053; i=david@ixit.cz;
 h=from:subject:message-id; bh=i+PpcsXJJ53DrxBp3ADnJsJTSeGIaZ45KNoGbwtVT7c=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpsbgO+vyDUcHpIKz/T39SZ3iI42Y1qchdCybkd
 Sby9saxZLSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabG4DgAKCRBgAj/E00kg
 coi6D/9E4h6y/4CrOKrqkUzpAtAdVD47dHUZ3BnJEqDl2xqoJx0vCQlX97QkiNSKsJ64e/S2lUg
 naF0xH+f5hxXYfYYp7r6ZTxPNf6mdM8RPHAIlGhK3KFWNJz57joD1cRA7loPBLx4Aj7ZJxcmKG2
 uWsxos0zIkAE8tLRdLYhimr4QcJ+nLO0KQ0w23KVVWSg97uUdsD29Gp2FolsomQdlOUh9jL5xOZ
 +Cz4VfZKMQCqo9DELgoj+NRWUlA2VyR+7TYXNXj8Ec4EzBxI058/NMOYTN/W07KduTUcQesNaY+
 B0vXbR6qXSR0YwACGvTF0ogjwFQMLVA3lo5BXUmkYDgCgq26Krnnnh+5/m14allMiPs8KXqMNp9
 0OEFHlizKEe30Wb2EKl0LtgAZnW3H3k1G+6/86UYwhEblpCf1hYWffMSgeXAbEMFGZJcx+Pp5kq
 kq66KJchdxnoKu7NbefvqHa45UKFLhKnKEmLmWampYTuKefo+BQMOU0yT6meofeI9lHySARUYVt
 ichOBjeYYqjFbHXO/hFP/SKyGhSb3OhtQJl8m2jFyN9Snz0v/5yivMqFpHgkoApmtq8bl1IVCTe
 QzxYq4bm0letvP9zvOL3AwrpdQfawZWA/GDGWc5GktYK2INjQ0sUlgzQoFSm1J7ymjU3hYfmsp6
 z8s3lxaHQIU2YCQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Add framebuffer for early console and u-boot support.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi    | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 01b570d0880d6..bd6d7a3cfc0ac 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -39,6 +39,22 @@ aliases {
 		serial1 = &uart6;
 	};
 
+	chosen {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		framebuffer: framebuffer@9d400000 {
+			compatible = "simple-framebuffer";
+			memory-region = <&cont_splash_mem>;
+
+			format = "a8r8g8b8";
+			stride = <(1080 * 4)>;
+			height = <2246>;
+			width = <1080>;
+		};
+	};
+
 	gpio-keys {
 		compatible = "gpio-keys";
 		autorepeat;

-- 
2.53.0

