From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/2] PM / devfreq: Do not change the frequency of a
 suspended device
Date: Thu, 19 Nov 2026 21:16:21 +0000
Message-Id: <20261119-devfreq-suspend-sync-v3-0-ef19fbf94d83@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XOTQ6CMBAF4KuQrq3p9AeNK+9hXNQyhRoFbKGRE
 O5uQRPZGJdv8uabGUlA7zCQQzYSj9EF19QpiE1GTKXrEqkrUiac8RwAOC0wWo8PGvrQYl3QMNS
 G7ozeW6NAKaZJWm09Wvdc2NP5nUN/uaLpZuvTSEqf7nXfWuVC1/hheSbCPP1zNwIFqm0ucybQS
 oHH8q7dbWuaO5nByNeI/IHwhACzzAgEyaVaI9M0vQD5X3nYJAEAAA==
X-Change-ID: 20261112-devfreq-suspend-sync-7ca8fc51550a
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Dong Aisheng <aisheng.dong@nxp.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795122981; l=3640;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=zRcwh0X/csqSTO8PFOHLtSayo1tqobLNJE+EuERfHnA=;
 b=YXff/cIq2Din9p4fBQzh0CpqPVb7vE5xGDQdUvXRBxcZ3UauImYZPboIUexA6YYOxvnY3MEmI
 9vJv6PKqb2iAWkKjWTebIAoPDr7I60UIUiKMPffb/Op9d8fno7CLAvO
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From the review of a panthor patch [1]: Boris Brezillon pointed out that
the devfreq core, not the driver, should stop calling ->target() between
devfreq_suspend_device() and devfreq_resume_device().

1/2 is v2 of [2], which 2/2 builds on. The panthor side is [3].

Tested on an Orange Pi 5 (RK3588S), v7.3-based kernel with [3],
GPU clock on SCMI_CLK_GPU with a 200 MHz opp-suspend (Jonas Karlman's
RFC, not in mainline).
min_freq, max_freq, the userspace governor's set_freq and the cooling
state written while the GPU was runtime suspended take effect on resume,
with no SError; min_freq also after s2idle and deep suspend. 200 runtime
suspend/resume cycles with changing limits. A KUnit test (not posted)
covers the passive governor, the single transition on resume, failing
suspend and resume, and a resume without a suspend.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261110-panthor-suspend-clk-v1-1-53457050e51e@gmail.com
[2] https://lore.kernel.org/r/20261110-devfreq-resume-freq-v1-1-90de450ccbd0@gmail.com
[3] https://lore.kernel.org/r/20261112-panthor-suspend-clk-v2-1-62e1b168052d@gmail.com

---
Changes in v3:
- Run the pending update instead of restoring first, so resume makes
  one transition; the userspace governor without set_freq keeps the
  frequency from before suspend (Sashiko)
- Keep the passive governor out of the pending update, which evaluated
  it with freq 0 (Sashiko)
- Leave devfreq suspended when suspend or resume fails, instead of the
  v2 undo: callers may power the device down regardless. A caller that
  ignores a failed resume recovers on its next suspend and resume (Sashiko)
- Add [2] as 1/2: commit message corrected (lima on RK3528 is the
  mainline case, not panthor), comment shortened
- Rebase on devfreq-next
- Link to v2: https://patch.msgid.link/20261114-devfreq-suspend-sync-v2-1-10f0c3e14245@gmail.com

Changes in v2:
- Keep only the suspend count, now a plain int changed under
  devfreq->lock, instead of a separate suspended flag that could
  disagree with it when suspend and resume race (Sashiko)
- Resume at the resume frequency clamped to the current limits, then
  run the deferred update: the userspace governor without set_freq
  stayed at the suspend frequency (Sashiko)
- Don't defer the passive governor's parent updates: exynos-bus
  children must follow their parent to its suspend frequency, also at
  shutdown (Sashiko)
- Drop pending_freq: the deferred update runs like any update_devfreq()
  call. If it fails, resume logs the error and still sends
  DEVFREQ_GOV_RESUME (Sashiko)
- Undo a failed devfreq_suspend_device(), as rk3399_dmc and lima abort
  without resuming; an unbalanced devfreq_resume_device() is a no-op
  (Sashiko)
- Leave polling governors to their next poll after resume; the driver
  has just reset their load data (Sashiko)
- Link to v1: https://patch.msgid.link/20261112-devfreq-suspend-sync-v1-1-af64603ef43e@gmail.com

---
Arun Iyengar (2):
      PM / devfreq: Resume at the frequency from before suspend
      PM / devfreq: Do not change the frequency of a suspended device

 drivers/devfreq/devfreq.c            | 86 +++++++++++++++++++++++++++++-------
 drivers/devfreq/governor_userspace.c |  3 +-
 include/linux/devfreq.h              | 10 ++++-
 3 files changed, 79 insertions(+), 20 deletions(-)
---
base-commit: f9316c13d6f621af4f6f4a6089d3c989ffe899e6
change-id: 20261112-devfreq-suspend-sync-7ca8fc51550a

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

