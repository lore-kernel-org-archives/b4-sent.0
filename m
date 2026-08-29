From: Matt Eaton <linux@divinehawk.com>
Subject: [PATCH 0/2] ARM: dts: qcom: ipq4019: migrate USB to qcom,snps-dwc3
Date: Sat, 29 Aug 2026 21:31:24 +0200
Message-Id: <20260829-ipq4019-dwc3-migration-v1-0-cc66b54ce21c@divinehawk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIwzk2oC/yXMTQ6DIBBA4auQWTsJ0JZIr2K6oDDqmIgU7E9iv
 HtpXX6L9zYolJkKXMUGmV5ceIkVqhHgRxcHQg7VoKU2stUWOT3OUlkMb3/CmYfs1pqgv5C0pjX
 OugA1Tpl6/vzH3e1wed4n8uvvBvv+BUx4EEd6AAAA
X-Change-ID: 20260829-ipq4019-dwc3-migration-c5e09686a9ad
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788031913; l=1536;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=zWA0e3paKnXOqIGFnWjHF3VMRHadOpn9Ntl94B44z5U=;
 b=9f+XEHPhEA/ioFMP3AAehqUvv8yDsQJIYgEi19TaElsbHSKfxoyM2+smbqfM7oCi4jkRWAKDt
 xsyDRGt8OgyBpEdTEvhpkRiExp3s0xGBkaO5l3G8gU7Es9CB9Pf6SS8
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ipq4019 USB nodes still use the legacy qcom,dwc3 glue, which
describes the DWC3 core as a child node. qcom,snps-dwc3 embeds it in the
glue device instead, so the two nodes collapse into one.

Patch 1 relaxes the interrupt requirements for qcom,ipq4019-dwc3. The
binding groups it with platforms supplying five or six named interrupts,
but neither mainline nor Qualcomm's own vendor devicetree specifies wakeup
interrupts for this SoC, so the migrated devicetree fails dtbs_check
without it.

Patch 2 does the migration, and moves the ap120c-ac SS phy override up to
the parent node since the child's label goes away with it.

Patch 1 is for the USB tree, patch 2 for the qcom tree.

This is a prerequisite for setting per-SoC properties from the qcom glue,
which the legacy path has no mechanism for.

Tested on a Ubiquiti UniFi Travel Router.

Signed-off-by: Matt Eaton <linux@divinehawk.com>
---
Matt Eaton (2):
      dt-bindings: usb: qcom,snps-dwc3: relax interrupt requirements for ipq4019
      ARM: dts: qcom: ipq4019: migrate USB to the qcom,snps-dwc3 glue

 .../devicetree/bindings/usb/qcom,snps-dwc3.yaml    | 23 ++++++++++-
 arch/arm/boot/dts/qcom/qcom-ipq4018-ap120c-ac.dtsi |  4 --
 arch/arm/boot/dts/qcom/qcom-ipq4019.dtsi           | 46 ++++++++--------------
 3 files changed, 37 insertions(+), 36 deletions(-)
---
base-commit: 18f7fcd5e69a04df57b563360b88be72471d6b62
change-id: 20260829-ipq4019-dwc3-migration-c5e09686a9ad

Best regards,
--  
Matt Eaton <linux@divinehawk.com>

