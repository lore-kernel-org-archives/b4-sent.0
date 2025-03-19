From: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
Subject: [PATCH 0/2] arm64: dts: qcom: x1e80100-dell-xps13-9345: Enable
 fingerprint sensor
Date: Tue, 18 Mar 2025 22:22:55 -0500
Message-Id: <20250318-xps13-fingerprint-v1-0-fbb02d5a34a7@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI842mcC/x2MywqAIBAAfyX2nJBr0eNXooPZWnsxWSOE6N+Tj
 sMw80AiYUowVQ8I3Zz4DAV0XYE7bNhJ8VYYsMGuMXpQOSZtlOeiJAqHS9ner4T9iA5bKF0U8pz
 /57y87wdfDSP4YwAAAA==
X-Change-ID: 20250318-xps13-fingerprint-a7fbe2792c24
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742354576; l=770;
 i=bjorn.andersson@oss.qualcomm.com; s=20250318; h=from:subject:message-id;
 bh=OIzJIfkOFGoCE9pBG/Lr5IOf9VKdk7vbd7YcXAXXAEo=;
 b=xPdarBZ6Wboru3bGIBrX//UgIq+TafbLcKFRcVMI2nbSEI5CvAFcun9STrbiGIKfJIMr0AlgF
 8qRciq7cCFgBd/GMkcO9od9WJ6yd77Y9k8jHNNoIYd04EkVb84UcJFE
X-Developer-Key: i=bjorn.andersson@oss.qualcomm.com; a=ed25519;
 pk=rD3O9C9Erg+mUPBRBNw91AGaIaDVqquHZbnn6N6xh6s=
X-Endpoint-Received: by B4 Relay for bjorn.andersson@oss.qualcomm.com/20250318 with auth_id=362
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make the repeater optional in the SNSP eUSB2 PHY driver and describe the
involved components for enabling the fingerprint reader in the Dell
XPS13.

Signed-off-by: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
---
Bjorn Andersson (2):
      phy: qcom: phy-qcom-snps-eusb2: Make repeater optional
      arm64: dts: qcom: x1e80100-dell-xps13-9345: Enable fingerprint sensor

 .../boot/dts/qcom/x1e80100-dell-xps13-9345.dts     | 59 +++++++++++++++++++++-
 drivers/phy/qualcomm/phy-qcom-snps-eusb2.c         | 10 ++--
 2 files changed, 64 insertions(+), 5 deletions(-)
---
base-commit: c4d4884b67802c41fd67399747165d65c770621a
change-id: 20250318-xps13-fingerprint-a7fbe2792c24

Best regards,
-- 
Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>

