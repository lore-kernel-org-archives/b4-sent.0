From: Joonho Lee <mynameisjune111@gmail.com>
Subject: [PATCH v33 00/18] ALSA: virtio: preserve PCM progress
Date: Fri, 13 Nov 2026 18:21:24 +0900
Message-Id: <20261113-fix-virtio-snd-recovery-final-v33-0-13a934ad5ece@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/42OQQ6CMBBFr2K6dgxtQcCV9zAsShlhDLSmxUZCu
 Lstbly6nDd/3vyVeXSEnl0OK3MYyJM1cZDyeGB6UKZHoC4CJjJx5pxLuNMbArmZLHjTgUNtA7o
 lcqNGyDOu8qotCllWLDqeDuPB/uDWfGf/ah+o5yRNiVZ5hNYpo4eEftRBCkjblBrIz9Yte8/Ik
 +7fSkmTQY51UZc1Si70tZ8UjSdtJ9Zs2/YB97F5UAUBAAA=
X-Change-ID: 20261113-fix-virtio-snd-recovery-final-401a48b55378
To: linux-sound@vger.kernel.org, 
 Anton Yakovlev <anton.yakovlev@opensynergy.com>, 
 Matias Ezequiel Vara Larsen <mvaralar@redhat.com>
Cc: tiwai@suse.com, perex@perex.cz, mst@redhat.com, 
 virtualization@lists.linux.dev, linux-kernel@vger.kernel.org, 
 corbet@lwn.net, skhan@linuxfoundation.org, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, Takashi Iwai <tiwai@suse.de>, 
 Joonho Lee <mynameisjune111@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794561687; l=5601;
 i=mynameisjune111@gmail.com; s=default; h=from:subject:message-id;
 bh=3Yz1bL+Yu6b0fA+6aIZz/ij5aRqckyw6VeikfHQlsmA=;
 b=j0q9v5520UUrkCTZdfpVIQAAGKvo06DaXnN6cY3/ikoGPkQFTVv6ZnzFaqbuesJtt7XEemG5X
 rIyRATdQrSEBEW6dRFKNizcEnu9YA0dfoDwjF9QZPA6xCVTKil7hqOQ
X-Developer-Key: i=mynameisjune111@gmail.com; a=ed25519;
 pk=wqkZdvfcC8g8fDi6f0Y58LlaXIo+ubf6Y/9Lr9yhshc=
X-Endpoint-Received: by B4 Relay for mynameisjune111@gmail.com/default with auth_id=1508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is based on sound.git commit
 a4311e9447bbb219044db38897f95be112f46a8a.

Previous revision:
https://lore.kernel.org/linux-sound/20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com/T/

Changes since v32:

- Keep a replacement capture stream in DRAINING intact when an older
  sync_stop callback arrives. The active-state check now covers capture
  and playback, with the teardown marker retained for later cleanup.
- Check the settled device state while holding the queue and stream locks
  before rolling back a failed PAUSE. A late successful STOP keeps the
  queue closed and does not restore the old capture quiet sequence.
- Give each uncertain control incident one additional window of four
  msg_timeout_ms intervals. Sleepable callbacks share the remaining time.
- Close transfer admission and quiesce period work before waiting for a
  late control reply. Preserve the stop marker on failure and resample
  teardown state after the reply settles.

These changes are folded into patches 12 and 18. The other sixteen
retained patches have unchanged diffs.

Automatic device reset from v32 patch 20 is deferred. Its review exposed
an ALSA link/open lock cycle and unresolved ordering with transport reset
and power management. The supporting CONFIG_PM-independent suspension
change from v32 patch 19 is also omitted. Their review findings remain
open for a separate recovery design.

A permanently unanswered PCM control request still requires an explicit
driver rebind. Late control replies remain supported by patch 18.

Validation:

- ARM64 virtio-snd module build with W=1: no warnings. The review-fix diff
  passes checkpatch without errors or warnings.
- Eight QEMU KASAN/lockdep cases cover RW/MMAP capture, RESET/DRAIN,
  reopen, and playback. All passed with the loaded module hash checked.
- A test-only sync_stop gate forced an old DROP to resume after a new
  capture reached DRAINING. The original first-eighteen-patch baseline lost
  the readable tail with -EBADFD; the candidate preserved it and returned
  32 frames. Both used the same fixture.
- A 1500 ms delayed STOP reply smoke test passed on v32 and this candidate.
- Scarlett 2i2 input 1, macOS VZ, 48 kHz: v32 and the candidate each
  passed twelve captures totalling 170 seconds, including 70-second RW
  and MMAP captures and repeated reopen. The candidate passed four more
  short captures after a fresh VM boot. All three VMs shut down normally.

The physical tests used the existing ABI-matched 7.3.0-rc7 KASAN kernel
with rebuilt driver modules, capture_packed_status=1 and
capture_pause_restart=0. Other host recorder processes remained running.
Expected frame counts and nonzero signal windows were checked; no known
waveform oracle was available to prove exact sample continuity.

The delayed STOP smoke test does not force the exact late-reply/PAUSE
rollback interleaving. No fresh KCSAN run or full-kernel rebuild is claimed
for this revision. Automatic transport reset and PM recovery are outside
this reduced series.

Assisted-by: LLM

---
Joonho Lee (18):
      ALSA: pcm: mark stop-threshold accesses for capture policy sampling
      ALSA: pcm: report partial progress under the stream lock
      ALSA: pcm: add an optional reset operation under the stream lock
      ALSA: pcm: notify drivers after linked prepare completes
      ALSA: pcm: serialize linked buffer actions
      ALSA: virtio: propagate playback send failures through ACK
      ALSA: virtio: Recover PCM state after a failed start
      ALSA: virtio: Retain queued messages through device reset
      ALSA: virtio: bound PCM transfers and retain DMA buffers
      ALSA: virtio: Keep control payloads alive through DMA completion
      ALSA: virtio: wait through signals for PCM teardown
      ALSA: virtio: use request-owned capture and serialize recovery
      ALSA: virtio: prioritize capture period work
      docs: describe virtio-sound capture options
      ALSA: virtio: reject invalid playback completions
      ALSA: pcm: add an explicit application pointer to indirect playback transfer
      ALSA: virtio: preserve playback progress across pause and buffer access
      ALSA: virtio: settle PCM control state from late replies

 Documentation/admin-guide/kernel-parameters.txt |   14 +
 Documentation/sound/alsa-configuration.rst      |   36 +
 include/sound/pcm-indirect.h                    |   24 +-
 include/sound/pcm.h                             |   40 +
 sound/core/oss/pcm_oss.c                        |    2 +-
 sound/core/pcm.c                                |    3 +-
 sound/core/pcm_lib.c                            |   69 +-
 sound/core/pcm_native.c                         |  275 ++-
 sound/virtio/virtio_card.c                      |  159 +-
 sound/virtio/virtio_card.h                      |    6 +
 sound/virtio/virtio_ctl_msg.c                   |  433 ++++-
 sound/virtio/virtio_ctl_msg.h                   |   40 +-
 sound/virtio/virtio_kctl.c                      |  109 +-
 sound/virtio/virtio_pcm.c                       |  105 +-
 sound/virtio/virtio_pcm.h                       |  195 +-
 sound/virtio/virtio_pcm_msg.c                   |  821 ++++++++-
 sound/virtio/virtio_pcm_ops.c                   | 2227 +++++++++++++++++++++--
 17 files changed, 4182 insertions(+), 376 deletions(-)
---
base-commit: a4311e9447bbb219044db38897f95be112f46a8a
change-id: 20261113-fix-virtio-snd-recovery-final-401a48b55378

Best regards,
--  
Joonho Lee <mynameisjune111@gmail.com>

