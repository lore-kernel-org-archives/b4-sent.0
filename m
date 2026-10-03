From: Henrik Enquist <henrik.enquist@gmail.com>
Subject: [PATCH 0/2] ALSA: aloop: Fix notify mode, add a selftest
Date: Sat, 03 Oct 2026 15:26:10 +0200
Message-Id: <20261003-aloop-notify-fix-v1-0-ba5dfb831bf5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWZukLkG8ili0TBmRVlqEiHdXL
 L+TnP8CT47JQx1d4Ghnz9YEJHEE3SjNQMh9MKQiLRIhMpSztQsau7I+UfOBuS4VqVxUUlUQbou
 jMH/Jpv3tNzVRt74duO8HFq/QPXQAAAA=
X-Change-ID: 20261003-aloop-notify-fix-4f7beb408ab8
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Mark Brown <broonie@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Pavel Hofman <pavel.hofman@ivitera.com>, 
 stable@vger.kernel.org, Henrik Enquist <henrik.enquist@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791033970; l=5151;
 i=henrik.enquist@gmail.com; s=20261003; h=from:subject:message-id;
 bh=IyoEAGVOUE0r9SwliBG7P++AThoIydv1Wyz4eq45eKg=;
 b=cazZ65v/3A4S8Ddu5O/WSA0Wdyj59d2n2BuobZoaTSJ96pBvUsdMwX1lEmNGPLmV6G09dvW6b
 4+0334zL5IbD/IcjzPYnIPbVAp+lvams0fx7Qaoo68rDEonIiRDRjpR
X-Developer-Key: i=henrik.enquist@gmail.com; a=ed25519;
 pk=ctrSXwtuuiWIZbc1qNzu+n+1PkhB/a+2nlRyXd5j2pg=
X-Endpoint-Received: by B4 Relay for henrik.enquist@gmail.com/20261003 with auth_id=1105
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

snd-aloop has a notify mode (the pcm_notify module parameter, or the
"PCM Notify" control per cable) where the playback side may switch
format, rate and channels while a capture is running. The driver then
stops the capture and updates the "PCM Slave" controls, so the capture
application can reopen with the new parameters. alsaloop enables it in
its slave mode, and I'd like to use it in CamillaDSP, which captures
from a loopback and needs to follow whatever the player outputs.

This hasn't worked since 2018. Commit 898dfe4687f4 ("ALSA: aloop: Fix
racy hw constraints adjustment") moved the hw rules over to the shared
cable->hw. That fixed a real race, but it also pins the playback side
to the capture's parameters in notify mode. Pavel reported it on
alsa-devel in 2020 [1], and Jaroslav reproduced it and pointed at the
same commit:

  It seems that 898dfe4687f4 from Takashi broke this functionality
  (tied the cable parameters more strictly, so the playback cannot set
  freely own parameters for the pcm_notify=1 case). We need to find
  another way to detach capture stream in this case.

The thread ended there, without a patch.

The breakage is quiet, which probably explains why it lasted. A player
that probes the playback device sees only the capture's rate and
format, and resamples to them. aplay prints a warning, most players
don't. There's no rate change, no stopped capture and no event.

Patch 1 skips the hw rules for the playback side when notify is on,
which gives it back the freedom loopback_open() still intends it to
have. That makes the capture stop in loopback_check_format() reachable
again. That path was hardened this year by 826af7fa62e3 ("ALSA: aloop:
Fix racy access at PCM trigger") and e5c33cdc6f40 ("ALSA: aloop: Fix
peer runtime UAF during format-change stop"), and with those in place
I'm comfortable turning it back on. They need to go first in any
stable backport.

The period bytes rule is skipped as well. It came later, for the sound
timer source, but without skipping it a playback that switches rate
keeps the old capture's period size. The stream then runs with a period
that doesn't match the timer, and every switch fills dmesg with "Period
size ... not corresponding to timer resolution".

Patch 2 adds a selftest, so this doesn't break silently again. It
doesn't need to go to stable, so it can go via for-next if that's
easier.

Testing: for-linus at b4e7fc36e31f, arm64 VM, kernel with KASAN,
lockdep, DEBUG_ATOMIC_SLEEP and DEBUG_LIST, comparing the patched
driver with the unpatched one built from the same tree. With the
jiffies, hrtimer and sound timer (via snd-dummy) sources:
- With notify on, rate, format and channel changes on the playback
  side now go through, stop the capture and update the controls. With
  notify off they're refused as before.
- A capture that reopens at "PCM Slave Rate" after each stop follows a
  player alternating between 44.1k and 96k files, 20 of 20 switches,
  with both RW and mmap access. Unpatched: 10 of 20, the playback stays
  pinned to the capture's rate.
- A capture opened second is still pinned to the playback.
- 2 minutes of random open/start/close on both ends per source gave no
  KASAN or lockdep reports. The sound timer source logs an occasional
  "snd_timer_stop ... failed with -16", at the same rate unpatched.
- The new selftest fails 2 of 4 tests unpatched, and passes 4 of 4
  patched, 50 runs in a row.
Not tested: real hardware, other architectures, pause/resume, more
than two substreams.

One question, following up on Takashi's point in that thread about
telling user space that a stream got invalidated. After the stop, the
capture drains and then reads return -EBADFD. alsa-lib now documents
-ENODATA as meaning the PCM must be completely restarted, which looks
like the right signal here. Would you want aloop to report that
instead? I left it out since it changes what user space sees, but I'm
happy to do it as a follow-up.

AI disclosure: I used Claude Code (Claude Opus 5.5) for this. Starting
from my description of the problem and the 2020 thread, it did the
root cause analysis from the driver source and git history, set up the
test kernels and VM, wrote the test scripts, ran the measurements, and
wrote both patches and their changelogs. I reviewed all of it, and both
patches carry an Assisted-by tag.

[1] https://lore.kernel.org/all/b4af9071-f8d7-5b47-4d7a-c5743bd67394@ivitera.com/

Henrik

---
Henrik Enquist (2):
      ALSA: aloop: Don't constrain playback params in notify mode
      selftests/alsa: Add a test for snd-aloop notify mode

 sound/drivers/aloop.c                     |  20 ++
 tools/testing/selftests/alsa/.gitignore   |   1 +
 tools/testing/selftests/alsa/Makefile     |   2 +-
 tools/testing/selftests/alsa/aloop-test.c | 345 ++++++++++++++++++++++++++++++
 4 files changed, 367 insertions(+), 1 deletion(-)
---
base-commit: 13dffca9043500ed6033d770b491a043fb952bc5
change-id: 20261003-aloop-notify-fix-4f7beb408ab8

Best regards,
--  
Henrik Enquist <henrik.enquist@gmail.com>

