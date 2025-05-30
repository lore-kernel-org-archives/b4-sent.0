From: Jake Hillion <jake@hillion.co.uk>
Subject: [PATCH 0/2] x86/platform/amd: better handle scheduling delays in
 hsmp_send_message
Date: Fri, 30 May 2025 17:15:20 +0100
Message-Id: <20250530-amd-hsmp-v1-0-3222bffa4008@hillion.co.uk>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJjZOWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDUyNz3cTcFN2M4twCXYtkY1MLSwvTJJO0JCWg8oKi1LTMCrBR0bG1tQA
 AK3k/WgAAAA==
X-Change-ID: 20250527-amd-hsmp-8c358985b4fb
To: Naveen Krishna Chatradhi <naveenkrishna.chatradhi@amd.com>, 
 Carlos Bilbao <carlos.bilbao@kernel.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 sched-ext@meta.com, Jake Hillion <jake@hillion.co.uk>, 
 Blaise Sanouillet <linux@blaise.sanouillet.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748621741; l=1143;
 i=jake@hillion.co.uk; s=20250530; h=from:subject:message-id;
 bh=+zx2LErMA1VlXm7obx1Hcr0zfFCVBJMB+ReXoiYm/Nc=;
 b=CljWxK0kvVRuBtznVHySbDbiCBsgKlsGtlMlwrejhBwiYLDVv+EbEzJpL4ei7Nncq2ycXYeyf
 ysOP2OWzUlRDPHwNUYJ32UXdS65QeX8FFcZllYmEUVXZwxzSVxP/l6V
X-Developer-Key: i=jake@hillion.co.uk; a=ed25519;
 pk=8cznmqtMcMEcU8QH55k8DrySboD889OBB/BEUMJh3dw=
X-Endpoint-Received: by B4 Relay for jake@hillion.co.uk/20250530 with auth_id=419
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hsmp_send_message currently relies in 2 places on the assumption that
usleep_range will complete in well under 100ms. This is not guaranteed,
and is prevalent when running sched_ext schedulers or possible under
other high load conditions.

These patches alter the behaviour in two ways:
1. Checks the result of `mbox_status` a final time if the sleep took us
   past the timeout. This gives a useful result under test when there
   are significant scheduling delays, rather than -ETIMEDOUT.
2. Removes the 100ms limit on awaiting the semaphore. This allows a
   second thread to compete even when the other suffers large scheduling
   delays.

Signed-off-by: Jake Hillion <jake@hillion.co.uk>
---
Jake Hillion (2):
      x86/platform/amd: move final timeout check to after final sleep
      x86/platform/amd: replace down_timeout with down_interruptible

 drivers/platform/x86/amd/hsmp/hsmp.c | 14 ++++++--------
 1 file changed, 6 insertions(+), 8 deletions(-)
---
base-commit: 44ed0f35df343d00b8d38006854f96e333104a66
change-id: 20250527-amd-hsmp-8c358985b4fb

Best regards,
-- 
Jake Hillion <jake@hillion.co.uk>

