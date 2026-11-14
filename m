From: Joshua Horne <hornejd@etsu.edu>
Subject: [PATCH 0/5] drm/amd/pm: overdrive support for smu8
 (Carrizo/Stoney)
Date: Fri, 13 Nov 2026 22:03:20 -0500
Message-Id: <20261113-smu8-overdrive-v1-0-763f07bdfca9@etsu.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBBA0V+RWWui9YxfEQt0MBKPzNBIxL8rl
 mdx7wWCTChQBhcwOhJaFw8dBtCNzTKgIusNJjKZ1jpWMh+FWh2yZXKoEhMVTZynmU1z8NHG2NP
 5Dav6txzthN3+XuC+H+jsCk5yAAAA
X-Change-ID: 20261113-smu8-overdrive-4208a3756d57
To: Alex Deucher <alexander.deucher@amd.com>, 
 Kenneth Feng <kenneth.feng@amd.com>
Cc: =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 =?utf-8?q?Timur_Krist=C3=B3f?= <timur.kristof@gmail.com>, 
 Lijo Lazar <lijo.lazar@amd.com>, amd-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Joshua Horne <hornejd@etsu.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794625442; l=5296;
 i=hornejd@etsu.edu; s=20261109; h=from:subject:message-id;
 bh=UmzgubFBLP6539vRVkzEZqGVqJryr/hyW7Lruy4yeJw=;
 b=25jx8jTt8TZh94C7d7nTQp+P8nwK9RKBuh+tnFbae1ksCnYRA3EbatHIKIhNOvNw5o76tHNF+
 9Js24YNygOCDVxC5hxD3N60tx5rFhhALMBKCFIP3NfvYq5ynxM4/6MF
X-Developer-Key: i=hornejd@etsu.edu; a=ed25519;
 pk=HNOtiwerBbrJhfhzLHLxj3GDsUH9udRXflqnaI8sQmQ=
X-Endpoint-Received: by B4 Relay for hornejd@etsu.edu/20261109 with auth_id=1469
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series implements pp_od_clk_voltage for the smu8 backend, so the
graphics DPM levels of Carrizo and Stoney can be underclocked and
undervolted, or overclocked where the VBIOS declares an overdrive
limit. It uses the smu7 format and stays behind PP_OVERDRIVE_MASK.

Patch 1 fixes a stock bug I ran into along the way and does not depend
on the rest: the boot clock is below the lowest graphics level on this
VBIOS, so SetSclkSoftMax is sent 0xffffffff each time DPM is started,
which includes every driver load. It can be applied on its own.

A few things the diff does not show:

- The voltage is GfxVid, which drives the separate VDDGFX rail (SVI1 in
  the BKDGs for family 15h models 60h-6Fh and 70h-7Fh). GnbVid is not
  touched, so the NB rail and the memory controller are unaffected. The
  allowed range is the GfxVid range the VBIOS uses for the enabled
  levels, so nothing can go above the highest stock graphics voltage,
  and the hardware MinVid/MaxVid filter still applies.

- The new table is sent with ClkTableXferToSmu while DPM is running.
  The SMU firmware accepts it, but the level it is in keeps its old
  values until the SMU next enters that level. With the level forced,
  the VDDGFX sensor still read the old voltage a second after the
  commit, and the new one after a switch to another level and back
  (the clock itself cannot be read back). In auto mode the switch
  comes with the next level change; the driver does not force one.
  smu7 sends SCLKDPM_FreezeLevel/UnfreezeLevel around its upload, but
  those only keep the SMC from changing level while the driver
  rewrites the table in SMC RAM. smu8 has no such messages, and its
  table is transferred from a DRAM copy by a single message. Patch 5
  documents this in the pp_od_clk_voltage kernel-doc section in
  amdgpu_pm.c.

Known limitations:

- DCE 11 reads the sclk levels only once, in
  bw_calcs_data_update_from_pplib() when the resource pool is created,
  so after a large underclock its bandwidth calculations still assume
  the VBIOS clocks. smu7 and vega10 overdrive behave the same way on
  DCE 11.2 and DCE 12. A fix belongs in DC rather than in the
  powerplay backends, so it is not part of this series.

- Stoney is untested. It shares the code path and, per its BKDG, the
  rail layout, but whether the clock table is accepted at runtime is up
  to the SMU firmware, which ships with the system BIOS. Tested-by from
  Stoney owners would be welcome.

Testing was done on an A10-8700P (ASUS X555DA, VBIOS 113-C75100-028,
SMU firmware 18.60.00), on 7.3.1 with amdgpu built from that tree plus
these patches and "drm/amd/pm: send smu8 sclk level indices, not the
level mask" (already applied). The series was then rebased onto
amd-staging-drm-next without changes to the code and was not run again
there. This VBIOS has no overdrive limit, so only underclocking and
undervolting could be tested.

- Voltage changes were checked with the VDDGFX current-VID sensor:
  level 0 raised from 787 to 800 mV and level 7 lowered from 1187 mV
  (1163 mV requested, rounded up to the next VID, 1168 mV), each
  committed while the SMU sat on that level. The new value appeared on
  the next entry into the level and not before.

- A clock above the range, a voltage above the range and a table with
  non-increasing clocks were rejected with -EINVAL, and "r" restored
  the VBIOS levels.

- S3 with level 0 committed at 300 MHz / 800 mV: right after resume,
  before any level change, OD_SCLK still showed 800 mV and the VDDGFX
  sensor read 800 mV.

- On amd-staging-drm-next, each patch builds with clang W=1 without
  new warnings, and the series adds no sparse or smatch warnings.
  checkpatch --strict only reports the uint32_t and CamelCase
  checks that follow the existing powerplay code.

Two choices are left to whoever applies this:

- Earlier APU overdrive support (Raven, Renoir, VanGogh) is
  clock-only. The voltage control here stays within the GfxVid range
  of the VBIOS levels; a clock-only version can be sent instead if
  that is preferred.

- Stoney is enabled without having been tested. Limiting the series to
  CHIP_CARRIZO until someone tests it is a one-line change.

I used an AI coding assistant (Claude Code) for this series. It wrote
the code, the changelogs and a draft of this letter, and wrote and ran
the build checks and test scripts. I reviewed the series, ran the tests
on my hardware, and I am responsible for it.

---
Joshua Horne (5):
      drm/amd/pm: keep smu8 sclk level lookups within the table
      drm/amd/pm: move smu8_populate_umdpstate_clocks() up
      drm/amd/pm: show the smu8 overdrive sclk table
      drm/amd/pm: allow editing the smu8 overdrive sclk table
      drm/amd/pm: stop disabling overdrive on Carrizo and Stoney

 drivers/gpu/drm/amd/pm/amdgpu_pm.c                 |   6 +
 drivers/gpu/drm/amd/pm/powerplay/hwmgr/hwmgr.c     |   1 -
 .../gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c    | 319 ++++++++++++++++++++-
 .../gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.h    |   8 +
 4 files changed, 319 insertions(+), 15 deletions(-)
---
base-commit: 47df73aa49d1988c8f684b7caf8be6570e966844
change-id: 20261113-smu8-overdrive-4208a3756d57

