From: Mahesh Rao <mahesh.rao@altera.com>
Subject: [PATCH 0/4] stratix10: Add Interrupt support for asynchronous
 communication with SDM
Date: Tue, 22 Jul 2025 23:07:50 +0800
Message-Id: <20250722-sip_svc_irq-v1-0-c5b9e02c1ce6@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEepf2gC/0XMywqDMBCF4VcJs26K0XjLqxSRGMd2FmpMNBTEd
 2+q0C7/A+fbwaMj9KDYDg4DeZqnGOLGwLz09EROfWxIkzRPyqTmnmzrg2nJLbzqUMpBFrqvDcS
 HdTjQ+9QezdUOly2i6zX+TcVOUWTiJ27Wrw71yLGs+srUncyyXIX8K3faIzfzONKqWCjuouDOl
 NAcxwfOCLYxwgAAAA==
X-Change-ID: 20250709-sip_svc_irq-8be44f46ad9c
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dinh Nguyen <dinguyen@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mahesh Rao <mahesh.rao@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753196946; l=2078;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=rKPG+II+FZC1gD6MPdJE3Wtz5Pqku5GBbLlV76yOR/M=;
 b=I5x4qmb2dFuKnSxRRUlJRds/HZyQnRcPOdkY+KaEFl+nYE/juNyepr/ugRABHM1a3W9KgkVIA
 qZ3VhwJqtaeCVijmZ57OKIUk82Ik1jycRXlrxQyhS9xLazcfcdC5o3Y
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch-set adds support for interrupt from
Secure Device Manager(SDM) to Stratix10 SoC for
asynchronous communication.

Following things are added in this patch-set:
- Add support for interrupt from SDM to Stratix10 SoC.
- Add documentation for SDM interrupt in Stratix10 SoC.
- Enable SDM interrupt in Stratix10 SoC.
- Enable SDM interrupt in Agilex SoC.

These patches were originally submitted within a
different patch set, but were requested to be
separated into their own series.
Reference: https://lore.kernel.org/all/df8db66b-89a4-40d9-bd44-6705fdbb4517@kernel.org/

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
---
Mahesh Rao (4):
      dt-bindings: firmware: Add interrupt specification for Intel Stratix 10 Service Layer.
      dts: stratix10: Add support for SDM mailbox interrupt for Intel Stratix10 SoC FPGA.
      dts: agilex: Add support for SDM mailbox interrupt for Intel Agilex SoC FPGA.
      firmware: stratix10-svc: Add for SDM mailbox doorbell interrupt

 .../bindings/firmware/intel,stratix10-svc.yaml     |  10 ++
 arch/arm64/boot/dts/altera/socfpga_stratix10.dtsi  |   4 +
 arch/arm64/boot/dts/intel/socfpga_agilex.dtsi      |   2 +
 drivers/firmware/stratix10-svc.c                   | 117 +++++++++++++++++++--
 include/linux/firmware/intel/stratix10-smc.h       |  23 ++++
 5 files changed, 146 insertions(+), 10 deletions(-)
---
base-commit: 75083cd99c8261eec695596813cc261a523ab32b
change-id: 20250709-sip_svc_irq-8be44f46ad9c
prerequisite-change-id: 20250131-sip_svc_upstream-e78d8c9b4335:v5
prerequisite-patch-id: 6a4223bd2c01a0fd20925e597c906dc64e11ec2f
prerequisite-patch-id: 33ca4dbe8b8e18d3e51145c6bcaae55170878b22
prerequisite-patch-id: cc72b86440a07b6311c0ac8cf2212072d2a0c561
prerequisite-patch-id: 5c3dc9849364a5c6573b032b878459be252305e5
prerequisite-patch-id: 5db2eb9fe78188c2dbc453d0d2d6e45c8d8e1be7
prerequisite-patch-id: f7ffa416aef888c30d3fcf875e7b2f79e333dbfa
prerequisite-patch-id: b827c6490b3ebef5de4ad67e3150e318df79a08e

Best regards,
-- 
Mahesh Rao <mahesh.rao@altera.com>

