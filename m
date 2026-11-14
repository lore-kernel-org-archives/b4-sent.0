From: Hugo Sales <hugo@hsal.es>
Subject: [PATCH 0/8] drm/amd/display: Copy probed modes for atomic_check
Date: Sat, 14 Nov 2026 23:09:11 +0000
Message-Id: <20261114-amdgpu-modes-four-v1-0-f11e2a6cd407@hsal.es>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDtg/MerlC4mZtQRNJJppCDev
 Wldfov3TlAOwgp9dkLgQ1T8lmAeGQwzbROjuGQo8qIxJq+QVjftEVfvWHH0MWDdErGrSrKmg9T
 tgUf5/J/P122NduHh/RvBdX0BTEQDDnUAAAA=
X-Change-ID: 20261104-amdgpu-modes-four-57aaed43ab18
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ray Wu <ray.wu@amd.com>, Fangzhi Zuo <jerry.zuo@amd.com>, 
 Roman Li <roman.li@amd.com>, Alex Hung <alex.hung@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ville_Syrj=C3=A4l=C3=A4?= <ville.syrjala@linux.intel.com>, 
 Aurabindo Pillai <aurabindo.pillai@amd.com>, Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3829; i=hugo@hsal.es;
 h=from:subject:message-id; bh=+dDISwyisNdvJwt3B/p7Y642cJGXY2iQt7K7XzoHftQ=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68kmCebrPd1v+MlmhdJK9C9cNofplHL//ExW1I/
 Oh7f3sc++aOUhYGMS4GWTFFFt0bngwsEyfPzCl6vgRmDisTyBAGLk4BmIhFKcM/1ZeTGH7/71+9
 UH7ePY/pk3piq4KStp/9+FTJOH9BVeUXLkaGTb9/NDnrRh5j+r9X9UJEbqmhN7uCX/CJt12nD8V
 VK/1mBgBfp0ul
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mode_config.mutex protects connector->modes, but amdgpu_dm walks it from
atomic_check, in create_stream_for_sink() and
amdgpu_dm_get_highest_refresh_rate_mode(), without that mutex.
atomic_check can't take the mutex because of lock ordering. An earlier
patch I submitted moved the probe helper's sort under the modeset locks
so this walk couldn't race it, and Ville pointed out that the bug is in
the reader:
https://lore.kernel.org/r/auh8pUx_kXUYSdZ8@intel.com

atomic_check only needs the preferred mode and the highest refresh rate
mode. This series copies both at the end of each probe, under
mode_config.mutex and connection_mutex, and atomic_check reads the
copies under connection_mutex. The highest refresh rate copy is the mode
add_fs_modes() built the FreeSync video modes from, as upstream's cached
freesync_vid_base is. It's done this way because a search of
connector->modes at the end of the probe could pick a command line mode
with a higher refresh rate, and amdgpu_dm_is_freesync_video_mode() would
then reject the video modes

The copies also need work to stay current after a monitor swap. Until
the next probe they still describe the previous monitor, as
connector->modes could, and two paths read them before that probe.
mode_valid runs before the probe refreshes them, and after a swap the
HPD handlers commit before the next probe. Patch 3 has mode_valid
validate each mode with its own timing, so it no longer needs the
preferred mode. Patch 4 records the EDID of the sink the copies came
from, and patch 7 uses them only for a sink with that EDID. atomic_check
checks them against the sink of the stream it builds, since a hotplug
can swap dc_sink under it. With another sink, atomic_check uses the
requested mode's own timing until the next probe, as before the first
probe

Patch 1 drops a debug check that walked probed_modes and
connector->modes from atomic_check, and asks its author below the cut
whether to keep it behind mutex_trylock() instead. Patch 2 stops
add_fs_modes() matching against connector->modes, which dropped the
FreeSync video modes on every second probe. Patch 4 adds the copies,
patches 5 and 6 pass the sink of the stream being built to the code that
checks them, patch 7 switches the readers to them, and patch 8 adds
tests for the copies

Patch 6 also changes one behaviour, only with amdgpu.freesync_video=1,
which is off by default. A CRTC turned on straight into a FreeSync video
mode now gets its fixed refresh config, which it never got before

---
Hugo Sales (8):
      drm/amd/display: Drop the unadvertised mode check
      drm/amd/display: Don't match FreeSync video modes against the last probe
      drm/amd/display: Validate modes with their own timing
      drm/amd/display: Copy the preferred and highest refresh modes after probe
      drm/amd/display: Pass the sink to the FreeSync and stream timing helpers
      drm/amd/display: Pick the FreeSync video config for the new stream's sink
      drm/amd/display: Stop reading connector->modes from atomic_check
      drm/amd/display: Add KUnit tests for the mode copies

 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |   38 +-
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h  |   23 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    |  499 +++++---
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.h    |   13 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_mst_types.c    |    2 +-
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 1209 +++++++++++++++++---
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   |  153 +++
 7 files changed, 1644 insertions(+), 293 deletions(-)
---
base-commit: 47df73aa49d1988c8f684b7caf8be6570e966844
change-id: 20261104-amdgpu-modes-four-57aaed43ab18

Best regards,
--  
Hugo Sales <hugo@hsal.es>

