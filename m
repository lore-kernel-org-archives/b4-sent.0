From: Davey Hughes <davidralphhughes@gmail.com>
Subject: [PATCH 0/2] drm/amd/display: Keep FreeSync flip timing across
 plane resets
Date: Tue, 27 Oct 2026 06:25:41 -0700
Message-Id: <20261027-freesync-plane-reset-time-v1-0-bb43b501faf4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMSwqDQBAFryKzToMKKuQqIYv5PLVD7Ej3GAzi3
 aPJsh6vanMGZZi7FptTvNn4JQdUl8LF0csA4nSwq8u6rcq6o14B+0ik+ekFpDBkyjyBmhTapgN
 Cn+AOf1b0vP7at/ufbQkPxHwGz0fwBgrqJY7n5KdElv3AMlDSiQRrdvv+BdtdqgKkAAAA
X-Change-ID: 20261027-freesync-plane-reset-time-5db657eebfde
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Nicholas Kazlauskas <nicholas.kazlauskas@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Davey Hughes <davidralphhughes@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793107546; l=2402;
 i=davidralphhughes@gmail.com; s=20261027; h=from:subject:message-id;
 bh=M+DZ/4MREFoDeqfd5AyQ7NWyYn34LU0wEP8MyQ0a5GQ=;
 b=woN098BUqPny0RXZKqbrSrIFeSVa4OTgkH7fgZG3uzRKIV8zDOAzHV49KeHKIGUnRvNtUibD1
 IBDxJt/w+y3C2WkZEZc90k+5hae0yScGDGDF/J9Ond3OVnJ5Bq44Txk
X-Developer-Key: i=davidralphhughes@gmail.com; a=ed25519;
 pk=y45yWVxpjjxFE2cXy96fGlXLfDlt6UKHFHS5szhrFAs=
X-Endpoint-Received: by B4 Relay for davidralphhughes@gmail.com/20261027 with auth_id=1335
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a 48-165 Hz FreeSync panel, fullscreen clients under KWin with HDR
enabled and color accuracy set to "Prefer efficiency" run at about 51
fps instead of 60, with flips locked to the 13.45 ms BTR mid-point
grid. That grid drifts upward at the rate expected if FreeSync takes
the 32-bit microsecond timestamp itself as the last render time (3.46
us/s measured, 3.45 predicted).

KWin replaces the CRTC GAMMA_LUT blob on every commit in that mode, so
every flip resets the plane and the new DC plane starts with zeroed
flip timing. Patch 1 carries the timing over from the old DC plane, as
DM already does for flip_addr
(amdgpu_dm_plane_drm_plane_duplicate_state()) and for the BTR state
itself (dm_irq_params.vrr_params). Patch 2 adds KUnit tests, kept
separate so patch 1 backports to stable trees without the KUnit
infrastructure.

Tested with KUnit (UML, all AMD display suites pass; the new timing
tests fail without the fix) and on 7.2.11 with a Navi 31, an AW3423DWF
over DP, KWin 6.8.1 and Mesa 26.2.5: 60 fps content now flips at a
steady 16.65 ms instead of on the 13.45 ms grid, 30 fps content still
gets BTR (steady 33.2 ms), and debugfs shows color_mgmt_changed=1 on
the CRTC in every sampled commit. Not tested: DCE, overlay planes,
other compositors.

Open question: the copy happens in atomic check, so a blocking commit
that resets the plane while a flip is still in flight can copy timing
that is one flip old (at most one BTR frame). Copying in
amdgpu_dm_commit_planes() before the preflip would avoid that; I can
send it as v2 if you prefer.

I am not sure of the current AI disclosure policy, but I will freely
mention that I used Claude Opus 5.5 to help debug and write this patch +
tests. I have tried to do my best to match existing style/procedures.

---
Davey Hughes (2):
      drm/amd/display: Keep FreeSync flip timing across plane resets
      drm/amd/display: Test FreeSync flip timing across plane resets

 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |  17 ++
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h  |   3 +
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   | 190 +++++++++++++++++++++
 3 files changed, 210 insertions(+)
---
base-commit: 77f548b127c6de34ce271fa09ba270cb1ef9f2da
change-id: 20261027-freesync-plane-reset-time-5db657eebfde

Best regards,
--  
Davey Hughes <davidralphhughes@gmail.com>

