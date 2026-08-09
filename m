From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Introduce support for Xiaomi Mi 8
Date: Sun, 09 Aug 2026 18:48:53 +0200
Message-Id: <20260809-dipper-v1-0-eb4d501e85df@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMD3ZTMgoLUIl2LtBTjNMNUE3PTpGQloOKCotS0zAqwQdGxtbUAUi7
 ux1gAAAA=
X-Change-ID: 20260720-dipper-8fd3f1e475bc
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1201; i=david@ixit.cz;
 h=from:subject:message-id; bh=IqBfubMqX9igKzB3Yyfy5WxzraIPUwUgP7EHhquo92M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqeK957nUnHJDfqfqIsmG3wBE+pXUx+Siukh4au
 YQ77eDeBhyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaniveQAKCRBgAj/E00kg
 cvqBD/9X9FsVRr8gq9xQXnyBSBTsKXp+iAtKnoDXBaaqF1nPgveeBpFrAuFVEtE41COE+QY7myT
 sPvnSL5cU0+WnZ/oGqOJiTMa5x1WhD7JKI9K6sM29C5XJNiU7HLfeu7A4eyPSOteHuIg1F3VpAl
 NitGVw0Umv+u8VFazdbijG5mXXHsgCaDMIoYdRVvuVmDHoxi4tmJ69lP7HT39BKLGlz/6/EgINB
 P5w6nSubGjIuX93xcDWL3qDzB24PGaoH5DAyU38J1hOoBADhdXmx+nFUTqYGi5tGFlv9imYrNSe
 ou/7wEseXSe+VIm0ydwS1Lox90DdVL1pF7EocK12Nkch1CgZFr5hbc4OCwzYeYRTxqWBZKadmWi
 b12eR0SM8V23ER5PBO+BQkU21MeYYR1HN0APmrERixDTDKlqA66BqK25Q4HUSO/1GUEAG1Mos2G
 iTTMAXYuRTWDX4dhAKdz7vxzIvTesJ1yRw3OpZu7pFea3vZTbET3YFl4IsUEtUI5qoPf60Kk+fG
 Qw7fqdm5avvTler2zCj2sI+7ImJzJ0N9UP9gyWJ7Y0wVXdhmR69nxyq3WqZYa5eNap8ODr6Mi+8
 LVH59/bHWqjY2AWi+Wv4SDh5yHf+30Ypt7NQs6tzHWIZumCOOTkDTX+LGclP1SNRp/4eE3Hdr+N
 c4Rkgg761z85d8A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently only Mi 8 itself is supported, but the
sdm845-xiaomi-dipper-common should ensure, that other family members
such as Mi 8 Pro, Mi 8 Explorer will be likely supported too without
much of additional work. These variants should differ only in the small
details (such as battery size, fingerprint sensor etc.).

Minimal viable support for xiaomi-dipper. Enough to get basic u-boot and
Linux functional. More improvements will follow.

The display and touchscreen support are work-in-progress, but waiting
for other bits to land.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      dt-bindings: arm: qcom: Add Xiaomi Mi 8 family compatibles
      arm64: dts: qcom: add Xiaomi Mi 8 (dipper)

 Documentation/devicetree/bindings/arm/qcom.yaml    |  10 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/sdm845-xiaomi-dipper-common.dtsi | 623 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-dipper.dts  |  30 +
 4 files changed, 664 insertions(+)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260720-dipper-8fd3f1e475bc

Best regards,
--  
David Heidelberg <david@ixit.cz>

