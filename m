From: Jake Hillion <jake@hillion.co.uk>
Subject: [PATCH v2 0/2] x86/platform/amd: better handle scheduling delays
 in hsmp_send_message
Date: Thu, 05 Jun 2025 19:09:25 +0100
Message-Id: <20250605-amd-hsmp-v2-0-a811bc3dd74a@hillion.co.uk>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFXdQWgC/0XOTQ7CIBCG4as0s5aGTktEV97DdAEUZGL/Ako0D
 XcXGxOX75fJk9kg2kA2wrnaINhEkZa5BB4qMF7NN8toKA3IUXCBR6amgfk4rUyaVsiTFLpzGsr
 5Gqyj105d+9Ke4mMJ711OzXf9IS3/I6lhnLWIqJ1THefy4mkcyw+1WernHfqc8weQ7zaNpAAAA
 A==
X-Change-ID: 20250527-amd-hsmp-8c358985b4fb
To: Naveen Krishna Chatradhi <naveenkrishna.chatradhi@amd.com>, 
 Carlos Bilbao <carlos.bilbao@kernel.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 sched-ext@meta.com, Jake Hillion <jake@hillion.co.uk>, 
 Blaise Sanouillet <linux@blaise.sanouillet.com>, 
 Suma Hegde <suma.hegde@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749146981; l=1329;
 i=jake@hillion.co.uk; s=20250530; h=from:subject:message-id;
 bh=ubqHoAU1Db00pEWl3huh6IlImU4mT5yagwpEuTLPCPw=;
 b=htrNljWqypmTs++CldvPDLsMDVWtvPO9SWXx1w01s5UjqaPHNkrT35Va8KX93u2Zf+FbglKmo
 meAffuLUQy1CfksR0KQMxdzNKZDCsGvna9dQ6BzUldFUzGq7b/cmrV0
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
Changes in v2:
- Corrected -ETIMEDOUT to -ETIME in patch 2 as requested by reviewers.
- Link to v1: https://lore.kernel.org/r/20250530-amd-hsmp-v1-0-3222bffa4008@hillion.co.uk

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

