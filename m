From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH v2 0/2] Add Altera timeout bridge driver
Date: Wed, 21 Oct 2026 19:56:22 +0000
Message-Id: <20261021-feature-timeout-ip-v2-0-a037be089518@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOYY2WoC/32NSw6CQBAFr0J6bZv5RD6uvIdhMTKNdAwM6RmIh
 nB3Rw7gsip59TaIJEwRrsUGQitHDlMGcyqgG9z0JGSfGYwypVbKYk8uLUKYeKSwJOQZK9fY0ip
 PpmkgD2ehnt9H9N5mHjimIJ/jY9U/+ze3alRY17bqrNb+UunbQ5YXybkLI7T7vn8BQBCvHrUAA
 AA=
X-Change-ID: 20261003-feature-timeout-ip-7a93630de299
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612593; l=1633;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=lJpE9cg9IeF8aoZNz2dghC01UkZXyo/mx2Fv4BVXTmM=;
 b=mvdsBBK4Y0BRMscdKiQHNacZqHp2e2B7AQX5fNUTRjVNztMVx8qxWyem8xDTUhj9mCAP49FEy
 fxWXBrBEl9EASbdoZfK7TYEvdASSYTiSUHrVwT9TJ9PlQCzGkFqxWAI
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Altera's AXI Timeout Bridge IP. 

The timeout bridge connects an Axi bus to the HPS and provides a
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
Changes in v2:
- Address review notes
- Simplify error handling
- Provide better description for DT Schema
- Link to v1: https://lore.kernel.org/r/20261003-feature-timeout-ip-v1-0-8837c311d571@bruker.com

---
Vyacheslav Yurkov (2):
      dt-bindings: bus: Add Altera AXI Timeout Bridge
      bus: Add Altera AXI Timeout Bridge driver

 .../ABI/testing/sysfs-driver-altera-timeout-bridge |  21 +++
 .../bindings/bus/altr,axi-timeout-bridge-1.0.yaml  |  80 ++++++++++
 MAINTAINERS                                        |   7 +
 drivers/bus/Kconfig                                |   9 ++
 drivers/bus/Makefile                               |   1 +
 drivers/bus/altera-timeout-bridge.c                | 173 +++++++++++++++++++++
 6 files changed, 291 insertions(+)
---
base-commit: a804c5742bff224d4cb4d25dd383554d598be32b
change-id: 20261003-feature-timeout-ip-7a93630de299

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

