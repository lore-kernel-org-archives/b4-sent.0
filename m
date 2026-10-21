From: Henrik Enquist <henrik.enquist@gmail.com>
Subject: [PATCH 0/2] ALSA: aloop: Update the PCM Slave controls for a
 matching playback
Date: Wed, 21 Oct 2026 09:46:44 +0200
Message-Id: <20261021-aloop-slave-controls-v1-0-62297727177f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtYehD1VcRDl2YaKc1o5hDG3
 n2dHr/D/6/gUlUcbt0KVRZ1tdJApw74FctTUFMzhD6cqQ+EMZtN6DkugmxlrpYdrwMz0SWlMUR
 o6VRl1O9ve3/87Z/hLTwfL9i2Hbo/dvJ4AAAA
X-Change-ID: 20261021-aloop-slave-controls-9bcc118ddf2a
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Mark Brown <broonie@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, stable@vger.kernel.org, 
 Henrik Enquist <henrik.enquist@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792568804; l=2541;
 i=henrik.enquist@gmail.com; s=20261003; h=from:subject:message-id;
 bh=fYqwJhgziyigD6vhqDk4JUf6KAY1bq/UX5B5MmVYzUM=;
 b=1OFud9GDKIaNLquSWN+TQVtfX4rw1oiGbtrcC6NGzh+UNzu2hnMOAM+pHrZVDigf/OWBxxkGF
 uP1G65QXb8vCN2dQN+swkUhTq8jyrZ8QoBsq2uAE/FiomClRGHCpAXZ
X-Developer-Key: i=henrik.enquist@gmail.com; a=ed25519;
 pk=ctrSXwtuuiWIZbc1qNzu+n+1PkhB/a+2nlRyXd5j2pg=
X-Endpoint-Received: by B4 Relay for henrik.enquist@gmail.com/20261003 with auth_id=1105
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

One more aloop fix, after the notify mode one (ded1060369 "ALSA:
aloop: Don't constrain playback params in notify mode"). I ran into
this while working on a new CamillaDSP feature that uses notify mode.
The "PCM Slave" controls are meant to report the playback's
parameters, but often they don't. loopback_check_format() returns
early when a capture is open and the parameters match, before it
updates the controls. They then keep the module defaults, or the
values of an earlier stream.

This isn't specific to notify mode. Without notify, a playback that
joins a running capture always has matching parameters, so the controls
are never updated in that case. The early return has been there since
the driver was added, hence the Fixes tag on the 2010 commit.

Patch 1 skips only the capture stop when the parameters match, and
always updates the controls. A value event is still sent only for a
control whose value changes, so nothing new shows up except where a
stale value gets corrected.

Patch 2 adds a test for it to the aloop selftest. It doesn't need to go
to stable, so it can wait for the next merge window if that's easier.

Testing: for-linus at 443ed4edc2, arm64 VM, kernel with KASAN,
lockdep, DEBUG_ATOMIC_SLEEP and DEBUG_LIST, comparing the patched
driver with the unpatched one built from the same tree.
- The selftest passes 5 of 5 patched. Unpatched, only the new test
  fails: the controls keep the earlier stream's values (96000 Hz,
  S32_LE, 4 channels, non-interleaved) and no value events arrive.
- The reproducer in patch 1 reports 48000 unpatched and 44100 patched.
- No KASAN, lockdep or other warnings in dmesg.
Not tested: real hardware, other architectures.

AI disclosure: as with the notify series, I used Claude Code (Claude
Opus 5.5). It traced the bug through the driver and its history, wrote
both patches and their changelogs, built the test kernels and ran the
tests. I reviewed all of it.

Henrik

---
Henrik Enquist (2):
      ALSA: aloop: Update the PCM Slave controls for a matching playback
      selftests/alsa: Check the aloop PCM Slave controls for a matching playback

 sound/drivers/aloop.c                     | 11 +++++----
 tools/testing/selftests/alsa/aloop-test.c | 40 +++++++++++++++++++++++++++++++
 2 files changed, 47 insertions(+), 4 deletions(-)
---
base-commit: 443ed4edc2678cc51c5a01e7dffc4c890be40051
change-id: 20261021-aloop-slave-controls-9bcc118ddf2a

Best regards,
--  
Henrik Enquist <henrik.enquist@gmail.com>

