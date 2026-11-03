From: "David R. Hedges" <linuxdev844@thelittleman.net>
Subject: [PATCH 0/5] drm/nouveau: recover DP links the sink drops after
 waking
Date: Tue, 03 Nov 2026 14:02:46 -0600
Message-Id: <20261103-nouveau-dp-relink-v1-0-7ee88c7f1e8a@thelittleman.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OwY7CIBiEX6XhvJhCuxUaY3yPjYcfmK6slirQZ
 hPjuy9Wj3ucZOb75s4SokdifXVnEYtPfgoliI+K2ROFb3DvSmaylp0QdcPDNC+gmbsrj7j4cOZ
 KW+XU0LUtCVZ214jB/67Mr+Mrp9n8wOYn6N2IuM1Fll81NiIlWmV9tfvPtRL5InhdfHJojWs+t
 9Yd8qmcyPmCkcImIO+ffEMJ3E7j6HNfSRgDkNJuaB2ho61TJEkb6TpdjuvGwEjVsOPj8QdVJgi
 3DwEAAA==
X-Change-ID: 20261103-nouveau-dp-relink-89c8d8f644a1
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jani Nikula <jani.nikula@intel.com>, Ben Skeggs <bskeggs@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Danilo Krummrich <me@dakr.org>, 
 "David R. Hedges" <linuxdev844@thelittleman.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793736171; l=8102;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=AttjRiQCCx4bpMhmzGILXVMXjuqagQAEG+Vjxm085Xc=;
 b=MI+ovfuiqsNCr1T3j769FVJWqHyX23On65qjKwuWOtP5BmlmYz7SnUJn2//9Dv8Y4XzCrYFaJ
 OVteSd2StscC+QLmVoZCRBCwtLywvrmC2kgG0iVaiKttRAWkv9SKFqf
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With nouveau on a GA102 (GSP-RM 570.144) driving an IGM L28TN4K at
3840x2160@60 over DP, the monitor shows "No input signal" after DPMS
off/on, after S3 resume and after a cable replug, and stays dark until
the cable has been replugged, often several times [1].  The
proprietary driver doesn't have the problem.

drm.debug shows the same sequence every time:

 - the wake modeset trains the link at 4 x HBR2 without error;
 - about 2s later the monitor raises IRQ_HPD, with its link status
   reporting all lanes locked and aligned and the sink in sync;
 - about 2s after that it drops HPD for under a second and reasserts
   it;
 - nouveau reports a disconnect and a reconnect, mutter sees the same
   monitor and mode and doesn't modeset, and nothing trains the link
   again.

Whenever the IRQ_HPD arrived before link training instead, the picture
came up.  The monitor apparently needs the link trained after it has
finished waking, and drops HPD to ask for that.  NVIDIA's DisplayPort
library retrains the link on every long HPD pulse from a connected SST
sink (notifyLongPulseInternal() calls assessLink()), which would
explain why the proprietary driver copes.

Getting there takes several changes:

 - 4 makes the IRQ_HPD link check work on nv50+ again.  It has done
   nothing since v6.7: the DP encoder it relies on is cached before the
   encoder is attached to the connector, so the cached pointer is
   always NULL.
 - Retraining an active link in place, which that link check then
   does, isn't safe on GSP-RM.  NVIDIA's library wraps it in SOR flush
   mode, which nouveau doesn't implement, and an in-place retrain here
   left artefacts and hung the display engine at the next modeset.  3
   makes GSP-RM restart a lost link with a full modeset instead, using
   drm_atomic_helper_reset_crtc(), as i915 does.  Without GSP-RM, links
   are still retrained in place.
 - 5 restarts the link the same way when a DP sink reasserts HPD while
   its CRTC is still active, since userspace won't modeset if nothing
   about the display has changed.  This is what brings the monitor
   back.  In case a sink drops HPD every time its link is trained,
   restarts stop after five in quick succession.
 - 1 and 2 deal with a sink whose capabilities have dropped below what
   the mode needs, or are unknown because it stopped answering AUX.
   Switched on with its power button, this monitor first advertises
   DPCD 1.1 and HBR only, and while switched off it keeps HPD asserted
   without answering AUX.  Enabling the output in either state hung the
   display engine.  1 rejects modesets the link can't carry.  2 handles
   a plain DPMS on, which mustn't fail atomic check, by leaving the SOR
   detached, setting link-status to BAD and sending a hotplug event.

1-3 have to go in no later than 4.  Nothing here is tagged for stable.
4 has Fixes: tags, as it fixes a regression, but it switches on code
that hasn't run since v6.7 (and, for the MST atomic check, ever), so
I'd rather it wasn't backported until it has been in a release.

This is based on drm-misc-next plus "drm/nouveau: GSP DP control call
fixes and two KMS fixes" [2], which is meant for drm-misc-fixes.  5
builds on the last patch there.

I'd welcome opinions on:

 - 5 restarts the link on every long HPD pulse while the CRTC is
   active, without consulting the link status, because here the link
   status looks fine throughout.  Is that acceptable for all sinks, or
   would you rather have it behind a quirk?
 - 2 leaves the head running with no SOR attached when there is
   nothing to train.  That avoided the hang here, with and without
   GSP-RM, but the head produces no vblanks in that state, so every
   commit waits out the 2s window timeout ("wndw-0: timeout") until
   the sink is back.  Is there a better way to park the head, and is
   this safe on every display generation?
 - mutter doesn't read link-status.  It recovers here because the probe
   drops the modes the link can't carry and it gets a hotplug event;
   with a sink whose mode list doesn't change, it would stay dark until
   the next hotplug.

Testing, on the GA102 above with Ubuntu's 7.3.0-9-generic kernel and
nouveau built from v7.3 plus this series and [2], with
drm.debug=0x106:

 - DPMS off/on, cable unplug/replug, and suspend/resume (S3): the
   monitor goes through the IRQ_HPD and HPD sequence above, and the
   picture comes back four to five seconds after the wake, replug or
   resume, once the link has been restarted;
 - power button off/on: the restart is rejected, as the monitor first
   advertises 4 x HBR only; link-status goes BAD, mutter switches to a
   lower mode, and about two seconds later it's back at 3840x2160@60;
 - monitor switched off with its power button, screen blanked and then
   woken while it was still off: the DPMS on succeeds with the output
   left detached and link-status BAD, nothing hangs, and the picture
   comes back as above once the monitor is switched on;
 - resolution and refresh rate changes before and after a recovery
   work;
 - none of this logged a warning, a display engine hang or a failed
   link restart, and the restart limit was never reached.

With GSP-RM disabled (nouveau.config=NvGspRm=0), which runs the GA102's
display through nvkm's own code, everything above apart from suspend
behaves the same.  Suspend hangs that way on this machine whether or
not this series is applied (screen off, the system still running but
unresponsive; tried with the series on 7.3.0-9 and with Ubuntu's
nouveau on 7.3.0-10), so it wasn't tested without GSP-RM.

Both series build with W=1 on drm-misc-next, with no new W=1 or sparse
warnings in the touched files.  checkpatch --strict is clean.

Not tested: GPUs that predate GSP-RM, although running the GA102
without GSP-RM covers the same display code, except for the in-place
retrain on link loss, which this monitor never triggered; MST hubs (4
enables drm_dp_mst_root_conn_atomic_check() for MST-capable ports);
and eDP.

This series was developed with the help of Claude Code (Claude Opus
5.5).  It analysed the kernel logs, read the nouveau, DRM and NVIDIA
open-gpu-kernel-modules sources, drafted the patches and changelogs,
and ran the build and checkpatch checks.  I provided evidence and
direction, reviewed changes, and ran the hardware tests described
here.

[1] https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
[2] https://lore.kernel.org/nouveau/20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net/T/

Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
David R. Hedges (5):
      drm/nouveau/kms/nv50-: reject DP modesets the link can't carry
      drm/nouveau/kms/nv50-: don't enable a DP output with no trained link
      drm/nouveau/dp: restart lost links with a modeset on GSP-RM
      drm/nouveau/kms: cache the DP encoder after it has been attached
      drm/nouveau/dp: restart an active link when the sink reasserts HPD

 drivers/gpu/drm/nouveau/dispnv50/disp.c     |  34 +++++++--
 drivers/gpu/drm/nouveau/nouveau_connector.c |  20 +++++-
 drivers/gpu/drm/nouveau/nouveau_connector.h |   6 ++
 drivers/gpu/drm/nouveau/nouveau_display.c   | 108 +++++++++++++++++++++++++++-
 drivers/gpu/drm/nouveau/nouveau_dp.c        |  34 +++++++--
 drivers/gpu/drm/nouveau/nouveau_encoder.h   |   4 +-
 6 files changed, 188 insertions(+), 18 deletions(-)
---
base-commit: 2ebbeea89df4dae6a7d8a2a9b2d698d893beb283
change-id: 20261103-nouveau-dp-relink-89c8d8f644a1
prerequisite-message-id: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
prerequisite-patch-id: 2979d80699fb4b68d7465019ec928fd7bd47dac9
prerequisite-patch-id: 1389b4709a500702ced0d91bec6f9ec74d42f0c7
prerequisite-patch-id: 4b7b0a68f43fec590886ef8bc4588a8cd472cdf9
prerequisite-patch-id: 97b5695d71e8732b28be69331687ab21691173c0
prerequisite-patch-id: ca7799aa8843800d1d9d1649ca75cc04e6c3266a

Best regards,
--  
David R. Hedges <linuxdev844@thelittleman.net>

