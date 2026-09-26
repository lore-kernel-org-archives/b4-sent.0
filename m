From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:21 +0200
Subject: [PATCH RFC 02/12] dt-bindings: usb: qcom,pmic-typec: Update
 example with vbus-supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-2-31adc19f32c6@ixit.cz>
References: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
In-Reply-To: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Lee Jones <lee@kernel.org>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, mfd@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1765; i=david@ixit.cz;
 h=from:subject:message-id; bh=7QxiOjoeKoKXk9E1eYNDmLj4wCbThDkI+aQOFIPL5J4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt70+CmH8mks/No9E70DNtIUe2Oyb2BRrsAJrO
 zIOZWkLvYuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PgAKCRBgAj/E00kg
 cj9oD/45Iu4qrkMFD6bJMFFFI+9sFnJQItwzRXrXXjDhtFmPmkTbBGk2laRKDf8SoADb+9svKar
 tkwt14EQTr/yQ8WW8J+yj7BRma48NuFHbq9B3qnRMHgP+ajfzkmkOTRhsH6G/k1w3epSzf/w280
 OgATA0T5SKEeaYDBsSWppMR5nFHdtjfcLBEaXRTOCTiUFsQvIevKrc+5GE7565G3OgbKqVVo25F
 VN/PdYZCpYyC4PzYIKRvuEyl2kNJBIs88pAsGlfVJ/UgFa/YFhdheGSBvDZ/AReYW5ey9Cke0Yy
 UZtQr1sM/OYF8O1WyOzH78xvUGPQrwqkuTT2/sviRXR2uaIMnRUn6hHY5XZYSFdUzEhUhNKc1kS
 XX4703ejTpsvJjc283T/nfQxb+/iTlFrPqts4vLjsHyfIccc4F1UPsGUMFEc9ruBAwxzUbqJbDx
 xZw803J/P7SHHE8JeMgGA8LTdPVmRNmc3uMeQ2Jv7mSbdem2krrO2ggxQYtS4DWIEqJ2+mHWQEl
 +L/C3JMilG96SXWNB6WRWyA5J6rm3XPmf7X1PLlYBx1fN6LytJusruQ3DczH3VotFQANZnPmDk0
 Ev9Ih0rc8Mix+txBeZTEyxS+oYcfDh2JVWhjpRnUa0nN7dCPDi8gfrbphIAktfAyl/Uhc06Ln4e
 YfmTlKkhb70RslQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vdd-vbus-supply is deprecated, thus don't suggest deprecated usage in
example.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/usb/qcom,pmic-typec.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/usb/qcom,pmic-typec.yaml b/Documentation/devicetree/bindings/usb/qcom,pmic-typec.yaml
index ba790c4488b76..2c8b11e92fb28 100644
--- a/Documentation/devicetree/bindings/usb/qcom,pmic-typec.yaml
+++ b/Documentation/devicetree/bindings/usb/qcom,pmic-typec.yaml
@@ -163,29 +163,30 @@ examples:
                               "sig-rx",
                               "msg-tx",
                               "msg-rx",
                               "msg-tx-failed",
                               "msg-tx-discarded",
                               "msg-rx-discarded",
                               "fr-swap";
 
-            vdd-vbus-supply = <&pm8150b_vbus>;
             vdd-pdphy-supply = <&vreg_l2a_3p1>;
 
             connector {
                 compatible = "usb-c-connector";
 
                 power-role = "source";
                 data-role = "dual";
                 self-powered;
 
                 source-pdos = <PDO_FIXED(5000, 3000, PDO_FIXED_DUAL_ROLE |
                                PDO_FIXED_USB_COMM | PDO_FIXED_DATA_SWAP)>;
 
+                vbus-supply = <&pm8150b_vbus>;
+
                 ports {
                     #address-cells = <1>;
                     #size-cells = <0>;
 
                     port@0 {
                         reg = <0>;
                         pmic_typec_hs_in: endpoint {
                             remote-endpoint = <&usb_hs_out>;

-- 
2.55.0

