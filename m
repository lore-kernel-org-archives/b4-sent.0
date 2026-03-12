From: Mayank Rungta <mrungta@google.com>
Subject: [PATCH v2 0/5] watchdog/hardlockup: Improvements to hardlockup
 detection and documentation
Date: Thu, 12 Mar 2026 16:22:01 -0700
Message-Id: <20260312-hardlockup-watchdog-fixes-v2-0-45bd8a0cc7ed@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJlKs2kC/32NwQ6CMBBEf4Xs2TVtAVFP/ofh0GyXthEpaRE1h
 H+3knj1+GbyZhZIHD0nOBcLRJ598mHIoHYFkNODZfQmMyihDkJJiU5H0we6PUZ86omcCRY7/+K
 EB1HKpj4dNSkB2R8jb0XWr21m59MU4nu7muU3/a2qP6uzRIFNVXfSEIuKyosNwfa8p3CHdl3XD
 4zqUOPDAAAA
X-Change-ID: 20260211-hardlockup-watchdog-fixes-60317598ac20
To: Petr Mladek <pmladek@suse.com>, Jinchao Wang <wangjinchao600@gmail.com>, 
 Yunhui Cui <cuiyunhui@bytedance.com>, Stephane Eranian <eranian@google.com>, 
 Ian Rogers <irogers@google.com>, Li Huafei <lihuafei1@huawei.com>, 
 Feng Tang <feng.tang@linux.alibaba.com>, 
 Max Kellermann <max.kellermann@ionos.com>, Jonathan Corbet <corbet@lwn.net>, 
 Douglas Anderson <dianders@chromium.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Florian Delizy <fdelizy@google.com>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773357752; l=3297;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=0C9RlHTOFqbcqCjBROliem/Yw7tye+blJRKLXZ3MYr0=;
 b=mU9EhSv8+WaxR4YXyppJ5Px717BoBUtPBdZrV4UizcqmDTcZKcc7EVPMeIdfs3w7U8t+DV4Ku
 dE9CN1UZKmdCcOoISLGFzs4cDN4EOhn2EKmZJ3Rua6kiTANuiExQpaO
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series addresses limitations in the hardlockup detector implementations
and updates the documentation to reflect actual behavior and recent changes.

The changes are structured as follows:

Refactoring (Patch 1)
=====================
Patch 1 refactors watchdog_hardlockup_check() to return early if no
lockup is detected. This reduces the indentation level of the main
logic block, serving as a clean base for the subsequent changes.

Hardlockup Detection Improvements (Patches 2 & 4)
=================================================
The hardlockup detector logic relies on updating saved interrupt counts to
determine if the CPU is making progress.

Patch 1 ensures that the saved interrupt count is updated unconditionally
before checking the "touched" flag. This prevents stale comparisons which
can delay detection. This is a logic fix that ensures the detector remains
accurate even when the watchdog is frequently touched.

Patch 3 improves the Buddy detector's timeliness. The current checking
interval (every 3rd sample) causes high variability in detection time (up
to 24s). This patch changes the Buddy detector to check at every hrtimer
interval (4s) with a missed-interrupt threshold of 3, narrowing the
detection window to a consistent 8-12 second range.

Documentation Updates (Patches 3 & 5)
=====================================
The current documentation does not fully capture the variable nature of
detection latency or the details of the Buddy system.

Patch 3 removes the strict "10 seconds" definition of a hardlockup, which
was misleading given the periodic nature of the detector. It adds a
"Detection Overhead" section to the admin guide, using "Best Case" and
"Worst Case" scenarios to illustrate that detection time can vary
significantly (e.g., ~6s to ~20s).

Patch 5 adds a dedicated section for the Buddy detector, which was previously
undocumented. It details the mechanism, the new timing logic, and known
limitations.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
Changes in v2:
- Added Patch 1 to refactor watchdog_hardlockup_check() by returning
  early (Suggested by Douglas Anderson)
- Introduced the `watchdog_hardlockup_update_reset()` API (Suggested by
  Petr Mladek)
- Shifted original v1 patches to Patches 2-5 and rebased them on top of
  the new refactoring.
- Link to v1: https://lore.kernel.org/r/20260212-hardlockup-watchdog-fixes-v1-0-745f1dce04c3@google.com

---
Mayank Rungta (5):
      watchdog: Return early in watchdog_hardlockup_check()
      watchdog: Update saved interrupts during check
      doc: watchdog: Clarify hardlockup detection timing
      watchdog/hardlockup: improve buddy system detection timeliness
      doc: watchdog: Document buddy detector

 Documentation/admin-guide/lockup-watchdogs.rst | 132 ++++++++++++++++++----
 include/linux/nmi.h                            |   1 +
 kernel/watchdog.c                              | 148 ++++++++++++++-----------
 kernel/watchdog_buddy.c                        |   9 +-
 4 files changed, 199 insertions(+), 91 deletions(-)
---
base-commit: b4f0dd314b39ea154f62f3bd3115ed0470f9f71e
change-id: 20260211-hardlockup-watchdog-fixes-60317598ac20

Best regards,
-- 
Mayank Rungta <mrungta@google.com>

