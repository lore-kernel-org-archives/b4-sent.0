From: Joonho Lee <mynameisjune111@gmail.com>
Subject: [PATCH v32 00/20] ALSA: virtio: preserve PCM progress
Date: Fri, 13 Nov 2026 15:41:44 +0900
Message-Id: <20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/02NQQ7CMAwEv1L5jKUmaaHiK4hDkhpqhFJklwhU9
 e8kcOG4s/bsCkrCpHBsVhDKrDynEpzdNRAnn66EPBYAtrV7Y4zDC78wsyw8o6YRheKcSd6FJ3/
 HrjW+G0Lfu8MAxfEQKg/fgdP5l/UZbhSXKq0XwSthEJ/iVNGfOjuLtYVt+wCyd2NbqAAAAA==
X-Change-ID: 20261113-fix-virtio-snd-recovery-final-401a48b55378
To: linux-sound@vger.kernel.org
Cc: tiwai@suse.com, perex@perex.cz, mst@redhat.com, 
 virtualization@lists.linux.dev, linux-kernel@vger.kernel.org, 
 corbet@lwn.net, skhan@linuxfoundation.org, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, Joonho Lee <mynameisjune111@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794552109; l=5146;
 i=mynameisjune111@gmail.com; s=default; h=from:subject:message-id;
 bh=CSIvtBwKvaehws07KPUkWyj1WfIDDpl8ZWqHjrythjI=;
 b=J8jsPXNnjCqRqCBN1b0bIpfLqnKgJOlS++iHQ4OzgdVMfRTDwlZIyhd8DF+qqzU4fYeJwVONk
 P2JCRQTEfQSCD/mu/aR3oKGY1GnSjv2MAhqhiul+yGm7En0OdfgXCiu
X-Developer-Key: i=mynameisjune111@gmail.com; a=ed25519;
 pk=wqkZdvfcC8g8fDi6f0Y58LlaXIo+ubf6Y/9Lr9yhshc=
X-Endpoint-Received: by B4 Relay for mynameisjune111@gmail.com/default with auth_id=1508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series applies directly to sound.git commit
 a4311e9447bbb219044db38897f95be112f46a8a.

The last complete posting was v29:
https://lore.kernel.org/linux-sound/20261112053446.73504-1-mynameisjune111@gmail.com/T/

v30 and v31 were incomplete because of mail delivery failures. The
previous v32 SMTP attempt was rejected before any message was accepted.
This submission uses the b4 web endpoint.

Changes since v31:

Patches 1-17 retain the previous code and descriptions. Patch 18 lets
late PCM control replies settle the device state while preserving
control-command ordering. Sleepable operations wait a bounded time for
a late reply; trigger operations fail while the state is unknown.

Patch 19 makes PCM suspension available with CONFIG_PM disabled.
Patch 20 resets a device when its PCM state remains unknown or released
I/O is not returned. It suspends open streams first so applications can
recover through prepare. If reset itself fails, it disconnects the ALSA
card. Existing PCM handles report -ENODEV, and the sound devices are
removed. A driver rebind is required after this terminal failure.
Configuration waiters are woken before disconnect, which waits for
their ALSA power references.

Validation:

ARM64 QEMU tests reproduced both recovery failures in the prior local
candidate. Without CONFIG_PM, simultaneous playback exited with an I/O
error after reset. With the revised core it recovered and completed,
and three capture opens also succeeded. An injected virtqueue restart
allocation failure previously left repeated opens returning -ECANCELED;
the revised driver disconnected the card and recording succeeded after
rebinding. Fault injection is confined to test modules.

Nine production regressions and five focused baseline/candidate runs
completed without KASAN or lockdep diagnostics. Regression coverage
includes native and opt-in RW capture, native MMAP capture, RW/MMAP
RESET and DRAIN, playback PAUSE/DROP, and reopen. Native MMAP includes a
70-second capture phase after RESET. W=1 builds and sequential patch
application checks passed.

The new changes have not received physical VZ or fresh KCSAN testing.
Earlier physical and KCSAN results describe earlier code. These tests
do not qualify every transport failure or cross-device linked streams.
The one-period TX queue reduction remains unqualified for worst-case
scheduling tolerance. This revision does not claim to resolve every
outstanding review concern in the existing series.

---
Joonho Lee (20):
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
      ALSA: pcm: allow stream suspension without power management
      ALSA: virtio: reset the device when PCM state stays unknown

 Documentation/admin-guide/kernel-parameters.txt |   14 +
 Documentation/sound/alsa-configuration.rst      |   43 +
 include/sound/pcm-indirect.h                    |   24 +-
 include/sound/pcm.h                             |   47 +-
 sound/core/oss/pcm_oss.c                        |    2 +-
 sound/core/pcm.c                                |    3 +-
 sound/core/pcm_lib.c                            |   69 +-
 sound/core/pcm_native.c                         |  277 ++-
 sound/virtio/virtio_card.c                      |  373 +++-
 sound/virtio/virtio_card.h                      |   22 +
 sound/virtio/virtio_ctl_msg.c                   |  433 ++++-
 sound/virtio/virtio_ctl_msg.h                   |   40 +-
 sound/virtio/virtio_kctl.c                      |  109 +-
 sound/virtio/virtio_pcm.c                       |  105 +-
 sound/virtio/virtio_pcm.h                       |  194 +-
 sound/virtio/virtio_pcm_msg.c                   |  821 ++++++++-
 sound/virtio/virtio_pcm_ops.c                   | 2209 +++++++++++++++++++++--
 17 files changed, 4392 insertions(+), 393 deletions(-)
---
base-commit: a4311e9447bbb219044db38897f95be112f46a8a
change-id: 20261113-fix-virtio-snd-recovery-final-401a48b55378

Best regards,
--  
Joonho Lee <mynameisjune111@gmail.com>

