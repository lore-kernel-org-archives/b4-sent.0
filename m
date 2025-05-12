From: Mahesh Rao <mahesh.rao@altera.com>
Subject: [PATCH v2 0/7] stratix10: Add framework for asynchronous
 communication with SDM
Date: Mon, 12 May 2025 19:39:50 +0800
Message-Id: <20250512-sip_svc_upstream-v2-0-fae5c45c059d@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAbeIWgC/2WP3YrCMBCFX6XkeiP5aWzrle+xSIlxogOm7WZiU
 KTvvmlkr/ZuzsD5Ps6bEUQEYofmzSJkJJynEtRXw9zNTlfgeCmZKaGMkFpywmWk7MbHQimCDRy
 6/tK74dxqbVipLRE8Pivy+/TJEX4ehZw+TxaAyFZyEW1cJVpOs/PL1Y5//IDkeNZc8P3Q+c5Lo
 523R5wS3HduDpvqbAl4uQOmQ5P3O2l4dC3brDekNMdX3ZVl1VZVq9T/CVkWjeh7YQY5CK/l0d4
 TRFs9p3VdfwEs7PruJwEAAA==
X-Change-ID: 20250131-sip_svc_upstream-e78d8c9b4335
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>
Cc: Matthew Gerlach <matthew.gerlach@altera.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747050016; l=2502;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=xrLqGr/A7KBzm6992uLWeERh4hVm6A4U+dV5uqSfpIQ=;
 b=ku0EdbMV76Oe+dVxInq5QTEgMFlwm/BkweImQTxhU9f8QuQqXAS3feO94whUR0VMLdUoPGpd5
 /2U5IhU7RMHAPtyftESsvyQ32G7bINQQCmpHC6EVhZJ1qj3MHqzCHyf
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
Changes in v2:
- Added Reviewed by tag from Rob Herring for dt-binding
  patch.
- Resending the patch-set as there is no response from
  the maintainers for the previous patch submission.

- Link to v1: https://lore.kernel.org/r/20250422-sip_svc_upstream-v1-0-088059190f31@altera.com

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
base-commit: 39d6783f6488786301f36b0e7c619f220c3e8d2c
change-id: 20250131-sip_svc_upstream-e78d8c9b4335
prerequisite-message-id: 20250204-socfpga_sip_svc_misc-v3-0-697f7f153cfa@intel.com
prerequisite-patch-id: 6a4223bd2c01a0fd20925e597c906dc64e11ec2f
prerequisite-patch-id: 33ca4dbe8b8e18d3e51145c6bcaae55170878b22
prerequisite-patch-id: a02bca91874f4405191e60704574a0c99f37d184

Best regards,
-- 
Mahesh Rao <mahesh.rao@altera.com>

