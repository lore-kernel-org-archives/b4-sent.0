From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH 0/2] Add Altera timeout bridge driver
Date: Sat, 03 Oct 2026 20:19:18 +0000
Message-Id: <20261003-feature-timeout-ip-v1-0-8837c311d571@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEZjwWoC/x3MQQqAIBBG4avErBswhcKuEi2k/moWWahFEN49a
 fkt3nspIggi9dVLAbdEOXxBU1c0bc6vYJmLSSvdNkoZXuDSFcBJdhxXYjm5c9a0Rs3Q1lIJz4B
 Fnn86jDl/3retxWQAAAA=
X-Change-ID: 20261003-feature-timeout-ip-7a93630de299
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>, 
 Vyacheslav Yurkov <uvv.mail@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791058772; l=1295;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=iBNPw4+S7wqe2ur9r2+G9UXaM8s1MByYaTEofVO10i8=;
 b=8l2Csc7ezXuJVwxnNu8Y1LTcxSKxqxv38TBsQd9NhOdEMMLQDhfiNKOzCuCtyfGTj8G1wUSBR
 Czdud9AosceAdMGj5vn51ekQOTZXVXvEfSoZHCbXsDdfZHebRhDy/+G
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Altera timeout bridge IP. 

The timeout bridge connects an Avalon bus to the HPS and provides a
downstream address space for devices implemented in the FPGA. The
bridge also exposes status information and generates an interrupt when
a timeout occurs.

The driver registers the timeout bridge as a bus and allows child
devices behind the bridge to be described as the child nodes in the
device tree.

The latest bridge documentation (as of October 2026):
https://docs.altera.com/r/docs/683609/26.1/quartus-prime-pro-edition-user-guide/axi-timeout-bridge-ip

Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
Vyacheslav Yurkov (2):
      dt-bindings: bus: Add binding for Altera AXI Timeout Bridge
      bus: add Altera timeout bridge driver

 .../bindings/bus/altera-timeout-bridge.yaml        |  82 ++++++++
 drivers/bus/Kconfig                                |  10 +
 drivers/bus/Makefile                               |   1 +
 drivers/bus/altera-timeout-bridge.c                | 219 +++++++++++++++++++++
 4 files changed, 312 insertions(+)
---
base-commit: a74306e2e676f9775457366fc047a660fbf02f26
change-id: 20261003-feature-timeout-ip-7a93630de299

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

