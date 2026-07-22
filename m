From: Nathan Lynch <nathan.lynch@amd.com>
Subject: [PATCH 0/4] dmatest: shared channel fixes and fatal errors option
Date: Wed, 22 Jul 2026 10:47:45 -0500
Message-Id: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QrCMAxA0V8ZeTYwW7Yxf0V8SNvMZWgnSRVh7
 N+t+njgcjcwVmGDU7OB8ktM1lxxPDQQZ8pXRknV4FrXt4NzmO5U2ApO8mZDygknKnRDVl3V0Af
 fdz51FMcAdfJQ/pX1cb78bc+wcCzfK+z7B05BKKyCAAAA
X-Change-ID: 20260722-dmatest-fixes-and-fatal-errors-3b3653d5ac9b
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Tycho Andersen <tycho@kernel.org>, Wei Huang <wei.huang2@amd.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784735280; l=1398;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=kyaaaakUpShPkZWfRPjFFPU45IrWTv47HGTaZf06lm8=;
 b=PR5pN2DYYDdVLf9wJmMeYjggJ89HQBjh4PJxNZurDXOt2MDpTN0p91cnDRN8nBP1GH+zNoHI9
 l/v1GDTin0UBxVtV8Jf8hzmn6ZsKVowli2JnkqvaOY57t2KpT5Vhxg8
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sending several fixes for issues in dmatest that arise when running
multiple threads per channel. I have encountered these issues while
testing the sdxi driver.

Patch 1 "Don't forcibly terminate channel in polled mode" is a resend of a
fix I sent a while back that didn't get picked up. [1]

Also included is a feature introducing a "fatal errors" parameter that
provides the option of panicking the kernel after a given number of errors
have occurred in a run.

Claude Code w/Opus 4.8 was used to investigate the problems fixed by
patches 2 and 3, and it assisted in writing the changes in patch 2-4.

[1] https://lore.kernel.org/dmaengine/20250408-dmaengine-dmatest-poll-mode-fix-v1-1-754a446a5363@amd.com/

Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
Nathan Lynch (4):
      dmaengine: dmatest: Don't forcibly terminate channel in polled mode
      dmaengine: dmatest: Suppress bogus failures when stopping a run
      dmaengine: dmatest: Terminate channel before freeing threads
      dmaengine: dmatest: Optionally make test errors fatal

 drivers/dma/dmatest.c | 67 ++++++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 56 insertions(+), 11 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260722-dmatest-fixes-and-fatal-errors-3b3653d5ac9b

Best regards,
--  
Nathan Lynch <nathan.lynch@amd.com>

