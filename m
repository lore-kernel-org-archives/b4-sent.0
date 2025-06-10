From: Mahesh Rao <mahesh.rao@altera.com>
Subject: [PATCH v4 0/5] stratix10: Add framework for asynchronous
 communication with SDM
Date: Tue, 10 Jun 2025 23:37:07 +0800
Message-Id: <20250610-sip_svc_upstream-v4-0-bcd9d6089071@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACNRSGgC/23PQW7DIBAF0KtYrEs0gHGwV71HVVkYxglSHbtAU
 KLIdy/BqtIqWf6R5v2ZGwnoHQbSVTfiMbng5lMO9VtFzFGfDkidzZlw4BKYYDS4pQ/J9OclRI9
 6orhXVpl2qIWQJK8tHkd3KeTH55Y9fp+zHLfhA+6qjYWWhtmMy0H3v/zkgqHDYOw47DUAV10Sd
 33QAamZp8nFrkrNjklyLzm6EGd/LW8kVloKXXP+fHFiFCgoBbJlLYyCveuviF7vslu0xB+CZK8
 EnoVRozS1NJmxT4L4I/DmhSCy0GhQupbALYp/wrquP8yoZ62aAQAA
X-Change-ID: 20250131-sip_svc_upstream-e78d8c9b4335
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>
Cc: Matthew Gerlach <matthew.gerlach@altera.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749569835; l=3196;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=BaMCopdFsyf97DgXqkRC4ITODJy4XrlKF7Fhset0d1w=;
 b=Dg/uJSgebPZk7zffIlpCTxoQsG5cXKLK/GheSOMKIUb21q96Avuu9QQCzZGYCgaLJm9h2nnhQ
 iyZFxStkiDaA2s/gNv2nN+6pR8tFZCR4s6g37iIB8VBfjf0NQy2vkX9
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
- Add commands for performing Remote System Update
  (RSU) operations asynchronously.
- Migrate RSU driver to use the asynchronous
  communication framework.

---
Changes in v4:
- Added description for svc_mem_lock mutex.
- Wrapped commit message and comments in source
  code to kernel coding style as per coding style.
- Added minor code fixes.
- Moved variables to the top of the function
- Removed HWMON support from in the patch-set, this
  will be sent in a separate patch-set.
- Added support for RSU commands to asynchronously
  communicate with SDM.
- Migrated RSU driver to use the supported 
  asynchronous commands.

- Link to v3: https://lore.kernel.org/r/20250526-sip_svc_upstream-v3-0-6a08a4502de3@altera.com

Changes in v3:
- Changed "Stratix 10" to "Stratix10" in the commit
  message and in source code.
- Simplified stratix10_svc_add_async_client() by removing
  redundant code for async common channel initialization.
- Fixed resource cleanup on negative path in
  stratix10_svc_remove_async_client() and stratix10_svc_async_init().
- Removed optional interrupt handler support, will send the patches
  in a separate patch-set.

- Link to v2: https://lore.kernel.org/r/20250512-sip_svc_upstream-v2-0-fae5c45c059d@altera.com

Changes in v2:
- Added Reviewed by tag from Rob Herring for dt-binding
  patch.
- Resending the patch-set as there is no response from
  the maintainers for the previous patch submission.

- Link to v1: https://lore.kernel.org/r/20250422-sip_svc_upstream-v1-0-088059190f31@altera.com

---
Mahesh Rao (5):
      firmware: stratix10-svc: Add mutex lock and unlock in stratix10 memory allocation/free
      firmware: stratix10-svc: Implement ID pool management for asynchronous operations
      firmware: stratix10-svc: Add initial support for asynchronous communication with Stratix10 service channel
      firmware: stratix10-svc: Add support for RSU commands in asynchronous framework
      firmware: stratix10-rsu: Migrate RSU driver to use stratix10 asynchronous framework.

 drivers/firmware/stratix10-rsu.c                   | 272 +++---
 drivers/firmware/stratix10-svc.c                   | 934 ++++++++++++++++++++-
 include/linux/firmware/intel/stratix10-smc.h       |  76 ++
 .../linux/firmware/intel/stratix10-svc-client.h    |  92 ++
 4 files changed, 1234 insertions(+), 140 deletions(-)
---
base-commit: 0a4b866d08c6adaea2f4592d31edac6deeb4dcbd
change-id: 20250131-sip_svc_upstream-e78d8c9b4335
prerequisite-change-id: 20250109-socfpga_sip_svc_misc-bbcdfb7a0028:v3
prerequisite-patch-id: 6a4223bd2c01a0fd20925e597c906dc64e11ec2f
prerequisite-patch-id: 33ca4dbe8b8e18d3e51145c6bcaae55170878b22
prerequisite-patch-id: a02bca91874f4405191e60704574a0c99f37d184

Best regards,
-- 
Mahesh Rao <mahesh.rao@altera.com>

