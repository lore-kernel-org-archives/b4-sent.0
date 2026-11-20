From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH v3 0/2] Add Altera timeout bridge driver
Date: Fri, 20 Nov 2026 09:24:02 +0000
Message-Id: <20261120-feature-timeout-ip-v3-0-affcc644af5e@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALIRAGsC/33NTQrCMBCG4auUrI1kEtokrryHuEjb0Q7SH5I0K
 KV3N+1KQVy+H8wzCwvoCQM7FQvzmCjQOORQh4I1nRvuyKnNzaSQFQih+A1dnD3ySD2Oc+Q0ce2
 sqpRoUVrL8uHk8UbPHb1cc3cU4uhf+48E2/qXS8AFN0bpRgG0pYZz7ecH+mMz9mzzkvwwJPw0Z
 DacULpGYWwJ5stY1/UNE6lLbPkAAAA=
X-Change-ID: 20261003-feature-timeout-ip-7a93630de299
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795166651; l=1799;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=kYSfZpE9Q+XmwjPs5z2U1miPr1VgSlYB6FBVbeLyHgc=;
 b=tlzWrqVpZgqD8x7PyspcJbSCH8wS6Ge0GP9idKN5hKUMvT96Lu2MfUkCwHwEr442kKMjnWp4w
 O1c7/HWedHWACtb2NAo/411xv8pC/Y9Ah4Y1EAxknqRXuLIqfu56Rod
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

The latest bridge documentation (as of November 2026):
https://docs.altera.com/r/docs/683609/26.1/quartus-prime-pro-edition-user-guide-platform-designer/axi-timeout-bridge-ip

Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
Changes in v3:
- Addressed sashiko findings.
- Link to v2: https://lore.kernel.org/r/20261021-feature-timeout-ip-v2-0-a037be089518@bruker.com

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
 .../bindings/bus/altr,axi-timeout-bridge-1.0.yaml  |  86 ++++++++++
 MAINTAINERS                                        |   7 +
 drivers/bus/Kconfig                                |  13 ++
 drivers/bus/Makefile                               |   1 +
 drivers/bus/altera-timeout-bridge.c                | 184 +++++++++++++++++++++
 6 files changed, 312 insertions(+)
---
base-commit: 65e4fd942f72a9dba0e4e257290c4fa1aa756854
change-id: 20261003-feature-timeout-ip-7a93630de299

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

