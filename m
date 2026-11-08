From: DelaySystem <DelaySystem@tubot.lat>
Subject: [PATCH RFC 0/2] Uninterruptible host1x syncpoint wait for Tegra
 video capture
Date: Sat, 07 Nov 2026 21:21:45 -0800
Message-Id: <20261107-batch1-b1-host1x-wait-v1-0-8c8198adf600@tubot.lat>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBAAv1L27EI3BSVeBR/gtfSQjatZD61ko
 y2U/t2oxxmYWcEkqxgcmxWyvNV0GivQroGYwngX1GtlcK3bE7UH5FBiImTCNFmhBeegBbvIHXs
 nnryH2j6z3HT5fXu4nE8w/KW9+CGxfI+wbR+zXgVRfgAAAA==
X-Change-ID: 20261107-batch1-b1-host1x-wait-3cb3b92e9199
To: mperttunen@nvidia.com, thierry.reding@kernel.org
Cc: DelaySystem <DelaySystem@tubot.lat>, dri-devel@lists.freedesktop.org, 
 luca.ceresoli@bootlin.com, gregkh@linuxfoundation.org, mchehab@kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 clamor95@gmail.com, jonathanh@nvidia.com, linux-tegra@vger.kernel.org, 
 skomatineni@nvidia.com, linux-media@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2521; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=DLUckEgyR5Ni9ibN8qkK+UlCenVeIET585HOCl21B1Q=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkf2F7NNQoS2/EpUWuyo8xRho7U69tnTPt5MWzywW1CP
 I3nOx56d5SyMIhxMMiKKbKIyfC8r7+vE2dtNecEzBxWJpAhDFycAjCReB5Ghiff5mdefPm1PF32
 XOykyKOvPQ1mTncoVv3YpfrKSG7Tmi2MDDMUnRZG5FvaXOP9E22qyOG+WF/mlVzW1YWTv8rHXVd
 15gIA
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
The Tegra20 video capture path runs in a kernel thread and waits on
host1x syncpoints with host1x_syncpt_wait(), which is unconditionally
interruptible: any signal aborts the wait with -ERESTARTSYS. At high
resolutions and framerates these spurious failures are common, so the
driver wraps both waits in do/while retry loops, with a TODO asking
for an uninterruptible variant of the wait.

This series proposes one: patch 1 refactors host1x_syncpt_wait() so
the interruptible behavior is preserved exactly for existing callers
(including two DRM ioctls that are userspace ABI and must stay
interruptible) and adds host1x_syncpt_wait_uninterruptible() for
in-kernel users. Patch 2 converts the Tegra20 capture waits and drops
the retry loops and the TODO.

This is sent as an RFC because the API shape and the scope need
agreement before a final series:

1. Is a separate _uninterruptible() variant the shape host1x wants,
   or would the maintainers prefer something else (for example an
   internal helper with a flag, or a different name)?
2. Tegra210's two waits (tegra210.c) have no retry loop: a spurious
   -ERESTARTSYS currently fails the buffer. Should they convert to
   the uninterruptible wait as well, or is failing on signal
   intentional there?
3. drivers/crypto/tegra/tegra-se-main.c also waits with
   MAX_SCHEDULE_TIMEOUT; left out of scope here, but flagging in
   case its maintainer wants the same treatment.

drivers/staging/media/tegra-video with VIDEO_TEGRA=m, zero warnings).
The tegra20.c change itself has no compile coverage here: that object
builds only for 32-bit ARM (ARCH_TEGRA_2x_SOC/_3x_SOC) and no ARM
toolchain is available, and there is no Tegra hardware for runtime
testing. Hardware testing help is needed before any final series.

Testing: compile-tested only (arm64: drivers/gpu/host1x and
---
DelaySystem (2):
      gpu: host1x: add uninterruptible syncpoint wait variant
      staging: media: tegra-video: uninterruptible syncpt wait for tegra20

 drivers/gpu/host1x/syncpt.c                 | 46 ++++++++++++++++++++++-------
 drivers/staging/media/tegra-video/tegra20.c | 37 +++++++----------------
 include/linux/host1x.h                      |  2 ++
 3 files changed, 48 insertions(+), 37 deletions(-)
---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-b1-host1x-wait-3cb3b92e9199

Best regards,
--  
DelaySystem <DelaySystem@tubot.lat>

