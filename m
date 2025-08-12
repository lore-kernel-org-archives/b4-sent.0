From: Mahesh Rao <mahesh.rao@altera.com>
Subject: [PATCH RESEND v2 0/4] stratix10: Add Interrupt support for
 asynchronous communication with SDM
Date: Tue, 12 Aug 2025 20:59:23 +0800
Message-Id: <20250812-sip_svc_irq-v2-0-53098e11705a@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKw6m2gC/1WPu27DMAxFf8XgXAWS/PbUoVk7tGMRBDLNNATq2
 KEUoUXgf6/iFAE6XhI85/IKnoTJQ5ddQSiy5+mUgn3KAI/u9EmKh5TBalvqWrfK87z3EfcsZ9X
 0VBSHonJDi5AuZqEDf6+0D3jbvm9fX2B3nwudLwke/pYPdlLdyCY3D/Jl9kHIjYrqZmiw7Ys8L
 7tY3gy986RwGkcOXRarjamVoFklR/Zhkp/1k2hWy720tf9KR6O0wrJvSVs0SNWz+wokbpOwsFu
 W5ResF7K1FAEAAA==
X-Change-ID: 20250709-sip_svc_irq-8be44f46ad9c
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dinh Nguyen <dinguyen@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mahesh Rao <mahesh.rao@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755003637; l=2301;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=5G24HMkqs3027iS5fMHxKSUZFfk1VsRyGb1T/hVbmro=;
 b=7M4WyEejYtnAdmZ44FFcu5Kbr5ci8cHlfQbPYOGgFHFxZeBTSSRecoJcbmUPKrTQmu4s1jV+G
 OB0oaYnS3ptAHI+xEE8TF5Bmp7CPv0m+HpTFN5OgZXZmmWJyFxvv46K
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
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://lore.kernel.org/r/20250722-sip_svc_irq-v1-0-c5b9e02c1ce6@altera.com

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
base-commit: 062b3e4a1f880f104a8d4b90b767788786aa7b78
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

