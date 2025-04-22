From: Mahesh Rao <mahesh.rao@altera.com>
Subject: [PATCH 0/7] stratix10: Add framework for asynchronous
 communication with SDM
Date: Tue, 22 Apr 2025 12:07:07 +0800
Message-Id: <20250422-sip_svc_upstream-v1-0-088059190f31@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOsVB2gC/zXNwQ6CMAyA4VdZdraGMSbIyfcwhMzZYRMHcwViY
 nx3J8Zb/yb9+pKMiZBlK14y4UpM05hD7YR0NzsOCHTNLcuiNIXSCphiz6vrl8hzQhsA6+bauOO
 l0trIfBYTenpu5Ln7dcLHkuX5t5QBme0mt2Jzy6ICnpyPg+3/fiB2sGoo4HCsfe2V0c7bE40z3
 vduCt9XF8sIeQ40t2I97JWB5LTs3u8Pq2i+fdgAAAA=
X-Change-ID: 20250131-sip_svc_upstream-e78d8c9b4335
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745294834; l=2204;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=Pgy4tMCSKaFzxkix9tVlNrpCpOWuWpmWTI9nbJQ0qg8=;
 b=yOC01PESiFGCzXwwSXGAXGJGJ9f0uYkPRgxEKbCrDgMmlyqrc1bw1mkNh4rUMGWI1bN3Y2VAr
 adB+0TEbSEEAypCwtMnKhHWTL6DhyXZcjn2BJh/X2FTgfzIhhJj0RFm
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The patch set includes the following changes:

- Add protection for querying memory objects in
  multi-threaded flow.
- Add support to generate and maintain message id
  and client id for asynchronous communication with SDM.
- Add framework to communicate with Secure Device
  Manager(SDM) asynchronously by sending a request
  and polling for response.
- Add interrupt definition in Agilex devicetree
  for asynchronous communication.
- Add SDM interrupt support for Agilex platform
  supporting asynchronous communication.
- Add support to optionally notify the clients if
  response is available using interrupts from SDM.
- Add commands for querying temperature and voltage
  from SDM.

---
Mahesh Rao (7):
      firmware: stratix10-svc: Add mutex lock and unlock in stratix10 memory allocation/free
      firmware: stratix10-svc: Implement ID pool management for asynchronous operations
      firmware: stratix10-svc: Add initial support for asynchronous communication with Stratix 10 service channel
      dt-bindings: firmware: Add interrupt specification for Intel Stratix 10 Service Layer.
      dts: agilex: Add support for SDM mailbox interrupt for Intel Agilex SoC FPGA.
      firmware: stratix10-svc: Add for SDM mailbox doorbell interrupt
      firmware: stratix10-svc: Add support for HWMON temperature and voltage read command.

 .../bindings/firmware/intel,stratix10-svc.yaml     |  10 +
 arch/arm64/boot/dts/intel/socfpga_agilex.dtsi      |   2 +
 drivers/firmware/stratix10-svc.c                   | 981 ++++++++++++++++++++-
 include/linux/firmware/intel/stratix10-smc.h       |  84 ++
 .../linux/firmware/intel/stratix10-svc-client.h    |  99 +++
 5 files changed, 1165 insertions(+), 11 deletions(-)
---
base-commit: f34da179a4517854b2ffbe4bce8c3405bd9be04e
change-id: 20250131-sip_svc_upstream-e78d8c9b4335
prerequisite-message-id: 20250204-socfpga_sip_svc_misc-v3-0-697f7f153cfa@intel.com
prerequisite-patch-id: 6a4223bd2c01a0fd20925e597c906dc64e11ec2f
prerequisite-patch-id: 33ca4dbe8b8e18d3e51145c6bcaae55170878b22
prerequisite-patch-id: a02bca91874f4405191e60704574a0c99f37d184

Best regards,
-- 
Mahesh Rao <mahesh.rao@altera.com>

