From: David Wales <daviewales@disroot.org>
Subject: [PATCH 0/2] Add initial device tree for Motorola Moto G (2014)
Date: Thu, 23 Apr 2026 23:24:49 +1000
Message-Id: <20260423-device-motorola-titan-mainline-v1-0-e1813a028cc8@disroot.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQrCMBCF4auUWTsQYxvEq4iLmM60U9qJJFEKp
 Xdv1OUHj/9tkCkJZbg1GyT6SJaoFedTA2H0OhBKXw3WWGda02JfR4FwiSWmOHssUrzi4kVnUUJ
 m5658sZ2zDDXySsSy/g7uj7/z+zlRKN8q7PsBoSfGe4IAAAA=
X-Change-ID: 20260404-device-motorola-titan-mainline-ff668f32562f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Wales <daviewales@disroot.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=953; i=daviewales@disroot.org;
 h=from:subject:message-id; bh=hek54JpptwLJ3gA+UJA9MmgBD5QEgs6jDnBqWr+sU0Y=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBp6h2uKtbvjnotgEJEIl6vq44CE9KyZjUby642R
 0ZVxL0I9taJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCaeodrgAKCRBtY1eBRvSh
 ZlQeCACSUJRRu6tFX7pQ/aeqftVA5qoiHh5/muMOtQMILRWeE1u/icTKmLxjcA2myd7WMCxR7vu
 7QBuhOq2rk1QjnGysenHKdraSve0V1nEK+fwFY1zIwkiJr0lETH/QdKWOz1Hgj5+V9E6yUmBz5O
 THM06MHlz8vqN/6OmVS67x9toIjhF19m7Y3ZmQw+n9aOY25WBYW9/D8pEszIBxGxOq5XzHQ496H
 f2tbTO/ePsWOKqmgXMBBrHC/QAc6WDj4zRwErFIqoHZObWoI9mzKJ3NO88RB2nBNXMcpiTPRGhD
 TVLkvLrp2Zvs0AW2mmezCryYa8xO1xgSSS9adtrhGZPIX16w
X-Developer-Key: i=daviewales@disroot.org; a=openpgp;
 fpr=8F5BAFB15444A769DC3B61684022B817D275D037
X-Endpoint-Received: by B4 Relay for daviewales@disroot.org/default with auth_id=737
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Motorola Moto G (2014) is the second device in the Moto G series,
with codename motorola-titan.

This series documents the motorola-titan, and adds an initial device
tree.

These patches have been previously discussed and merged into the
downstream msm8226-mainline fork:
https://github.com/msm8226-mainline/linux/pull/18

Signed-off-by: David Wales <daviewales@disroot.org>
---
David Wales (2):
      dt-bindings: arm: qcom: Add Motorola Moto G2 (2014)
      ARM: dts: qcom: Support Motorola Moto G2 (2014)

 Documentation/devicetree/bindings/arm/qcom.yaml   |   1 +
 arch/arm/boot/dts/qcom/Makefile                   |   1 +
 arch/arm/boot/dts/qcom/msm8226-motorola-titan.dts | 351 ++++++++++++++++++++++
 3 files changed, 353 insertions(+)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260404-device-motorola-titan-mainline-ff668f32562f

Best regards,
--  
David Wales <daviewales@disroot.org>

