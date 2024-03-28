From: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
Subject: [PATCH 0/2] V2 arm64: dts: qcom: Add support for Samsung Galaxy Z
 Fold5
Date: Fri, 29 Mar 2024 00:08:33 +0100
Message-Id: <20240329-v2-dts-add-support-for-samsung-galaxy-zfold5-v1-0-9a91e635cacc@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHL4BWYC/x3NQQrDIBBA0auEWXfAqIW0VyldTOpohVTFSULSk
 LtXunyb/w8QrpEF7t0BldcoMaeG/tLB600pMEbXDFppq4wecNXoZkFyDmUpJdcZfa4o9JElBQw
 00bbj1+fJXdHa8aZ6M3gzMrRkqezj9t89nuf5AwZqQ2B+AAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711667317; l=1075;
 i=serdeliuk@yahoo.com; s=20240326; h=from:subject:message-id;
 bh=EO57HbOh5710XDfnxOWvIJpZVjwIG+J4+aFo0XfThjo=;
 b=VS5eDCzT2/mE6l3UAaVadUeWpsFPHwax2Lx88eeJ3m/j6FRGubnsDpHgOwlCHbElDC8h1EV6r
 cDlVSqnKE9nDkacFKgHdSO7IXRXfX9FB9pydI+ngKu8hiBO5nGCHESr
X-Developer-Key: i=serdeliuk@yahoo.com; a=ed25519;
 pk=aWyveUE11qfDOOlRIFayXukrNn39BvZ9k9uq94dAsgY=
X-Endpoint-Received: by B4 Relay for serdeliuk@yahoo.com/20240326 with auth_id=147
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Added the  binding file to  the  same patch that includes the  device tree.
Refactored the  decivetree
- removed bootargs
- removed unused nodes
- removed disabled nodes
- added missing identation
- removed all the comments at the end of the nodes
- moved node status at the end of the nodes
- ordered all the nodes alphabetically
- ran the recommended dtbs tests all returned success

Signed-off-by: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
---
Alexandru Marc Serdeliuc (2):
      V2 arm64: dts: qcom: Add support for Samsung Galaxy Z Fold5
      v2 arm64: dts: qcom: Add support for Samsung Galaxy Z Fold5

 Documentation/devicetree/bindings/arm/qcom.yaml |   1 +
 arch/arm64/boot/dts/qcom/Makefile               |   1 +
 arch/arm64/boot/dts/qcom/sm8550-samsung-q5q.dts | 584 ++++++++++++++++++++++++
 3 files changed, 586 insertions(+)
---
base-commit: 4cece764965020c22cff7665b18a012006359095
change-id: 20240328-v2-dts-add-support-for-samsung-galaxy-zfold5-44b90138f3be

Best regards,
-- 
Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>

