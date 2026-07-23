From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v7 0/2] media: i2c: add support for ITE IT6625/IT6626 HDMI
 to MIPI CSI-2 bridge
Date: Thu, 23 Jul 2026 10:44:01 +0800
Message-Id: <20260723-upstream-it6625-it6626-v7-0-f8175bb0ea12@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPF/YWoC/43QS07DMBAG4KtUXuPKj3kkrLgHYuE6NvWiTWWbA
 Kpyd9zCoiiKlNXoH2m+0cxVlJBTKOJ5dxU5TKmk8dwCP+2EP7rze5BpaFkYZUixJvlxKTUHd5K
 pEhn8LSSpY3CHzqFVKNrwJYeYvu7w61vLx1TqmL/veyZ96/6RRq2Rk5ZKAmOvTWQA7F9SDXs/n
 vb1U9zMyTw6etUxzWEP0SKBd7ZbOPbRMauObU4PHFBFpZlg4cA2B5rjlbVkwgHRu4WD2xxsju0
 4MHYQjV/+h7Y51BzSmgcYekL+f9c8zz8hNZRjJQIAAA==
X-Change-ID: 20260716-upstream-it6625-it6626-6874ab8a5305
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784774643; l=7614;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=+oOd3mrWrdysA11L5N2My6LB6FqPVMrTkdPO0VDNjs0=;
 b=12s1KrJfa7i8T1858P1cZjbn5wQCOqLzqyntYZfFVmWJz32ULnr/Bw7y/OdjHiDFWnq9FZHhC
 vqmd6pLrG39Bn6NtCtxX0CUTirvPaxpvsVlXBK9PU9n2dmfzdgDs93p
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the ITE IT6625/IT6626 HDMI to MIPI CSI-2
bridge chips. IT6625 accepts an HDMI 2.0 input and IT6626 an HDMI 2.1
input, converting it to a D-PHY (or C/D-PHY on IT6626) MIPI CSI-2
output. The bridge is configured over I2C, exposes an HDMI CEC
adapter, and supports EDID read/write, DV timings detection and
configuration, and HPD control via the standard V4L2 subdevice pad
and video ops.

Patch 1 documents the devicetree binding for the bridge, including
its two selectable CSI-2 output graph ports.

Patch 2 adds the V4L2 subdevice driver itself.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v7:
- Patch 1 (dt-bindings): add back port@2 for the HDMI input port,
  reversing the v4 decision to drop it -- the v6 automated review
  re-raised the concern, and adi,adv7604.yaml (an actively-maintained
  binding for a comparable HDMI-receiver chip) confirms documenting an
  input port unused by the driver is the established convention, not
  a defect.
- Patch 2 (driver): fix three correctness issues found by automated
  review of v6 -- it6625_parse_endpoint() could read the mipi_csi2
  union under a bus_type the parser had silently fallen back to
  parallel/BT656 on; it6625_set_fmt()'s active-format path left
  format->format.colorspace stale for VIDIOC_SUBDEV_S_FMT callers; and
  it6625_s_edid() never rejected a non-zero start_block as the
  VIDIOC_S_EDID spec requires. See the patch's own changelog for the
  full list.
- Link to v6: https://lore.kernel.org/r/20260722-upstream-it6625-it6626-v6-0-6117d4d96574@ite.com.tw

Changes in v6:
- Patch 2 (driver): fix two correctness issues found by automated
  review of v5 -- an ignored v4l2_phys_addr_validate() return let a
  malformed CEC physical address reach cec_s_phys_addr() and get
  broadcast on the CEC bus, and it6625_parse_endpoint() pre-set the
  fwnode bus_type to D-PHY, which made the parser reject every IT6626
  C-PHY device tree outright. One other v5 review finding (a
  concurrent-ioctl-vs-remove() race) was checked and is not being
  acted on -- see the patch's own changelog for the reasoning.
- Patch 1 (dt-bindings): unchanged -- the v5 review concern was
  checked and dismissed; see the patch's own changelog for the
  reasoning.
- Link to v5: https://lore.kernel.org/r/20260722-upstream-it6625-it6626-v5-0-387e7584f2c9@ite.com.tw

Changes in v5:
- Patch 2 (driver): fix further correctness issues found by automated
  review of v4 -- two debugfs read handlers could leak uninitialized
  kernel stack memory to userspace on an I2C read failure, TRY-format
  state could go stale or leak active hardware state into what should
  be an isolated buffer, a concurrent S_FMT ioctl could interleave
  with hardware programming because the lock was released too early,
  S_EDID's blocks==0 case didn't actually disable the EDID per spec
  and a failed EDID write left HPD disabled permanently, the mipi_reg
  debugfs write was unlocked, and the HDMI info control returned a
  hardcoded string instead of real telemetry; also wire up the
  previously-unused reset-gpios line during probe. See the patch's
  own changelog for the full list, including three other v4 review
  findings that were checked (one against the hardware author's own
  knowledge of the chip) and are not being acted on -- see the
  patch's own changelog for the reasoning.
- Patch 1 (dt-bindings): unchanged -- both v4 review concerns for this
  patch were self-dismissed by the automated review itself with sound
  reasoning (the endpoint/patternProperties gap matches an established
  single-endpoint convention already used elsewhere in-tree, and
  dropping port@2 doesn't weaken validation since graph.yaml's own
  generic port pattern still covers it).
- Link to v4: https://lore.kernel.org/r/20260722-upstream-it6625-it6626-v4-0-c03362eb55ca@ite.com.tw

Changes in v4:
- Patch 2 (driver): fix further correctness issues found by automated
  review of v3 -- a CEC RX interrupt left unacknowledged on an invalid
  message length could storm the IRQ line, set_fmt returned -EINVAL
  for an unrecognized format code instead of falling back to a
  default, get_fmt's active-path reads of the format state were
  unlocked against a concurrent set_fmt, g_edid/s_edid didn't follow
  the VIDIOC_G/S_EDID spec for over-capacity requests, and the two
  mipi_reg debugfs handlers were missing locking/offset handling; also
  mark the HDMI info control volatile so it is actually refreshed. See
  the patch's own changelog for the full list. Separately (not a
  review finding), drop a redundant FW-start register trigger from
  probe -- the firmware starts automatically on power-on.
- Patch 1 (dt-bindings): drop the unused port@2 (HDMI input) graph
  port entirely rather than the review's suggested fix of adding it to
  required, and require bus-type on port@0/port@1 endpoints for
  "ite,it6626" specifically, since only that variant's D-PHY default
  can silently mismatch actual board wiring. Both found by the
  automated review of v3, which also flagged one other dt-bindings
  issue that was checked and is not being acted on -- see the patch's
  own changelog for the reasoning.
- Link to v3: https://lore.kernel.org/r/20260722-upstream-it6625-it6626-v3-0-947e50f01764@ite.com.tw

Changes in v3:
- Patch 2 (driver): fix further correctness issues found by automated
  review of v2 -- two banked-register reads still missing a lock, a
  CEC RX length TOCTOU and a dropped CEC TX interrupt on invalid RX
  length, it6625_s_edid() treating a successful write as a failure,
  missing V4L2_SUBDEV_FORMAT_TRY support, an unlocked active-format
  commit, and detected timings lumping the whole blanking interval
  into hsync/vsync instead of reading the real porch registers. See
  the patch's own changelog for the full list, including four other
  v2 review findings that were checked and are not being acted on
  (with reasoning).
- Patch 1 (dt-bindings): unchanged.
- Link to v2: https://lore.kernel.org/r/20260721-upstream-it6625-it6626-v2-0-7c4f3564ca38@ite.com.tw

Changes in v2:
- Patch 2 (driver): fix several correctness issues found by automated
  review of v1 -- premature V4L2 async subdev registration/teardown
  ordering, a missing-lock race on banked register reads, a
  status-poll interval bug, a dropped CEC interrupt, an unacked CEC
  transmit, set_fmt mutating active state on TRY, EDID blocks=0
  handling, and a couple of uninitialized-stack hardening fixes. See
  the patch's own changelog for the full list.
- Patch 1 (dt-bindings): restrict port@0/port@1 bus-type to D-PHY (4)
  only for "ite,it6625", since that chip doesn't support C-PHY (also
  found by the automated review of v1).
- Link to v1: https://lore.kernel.org/r/20260720-upstream-it6625-it6626-v1-0-475912f74459@ite.com.tw

---
Hermes Wu (2):
      dt-bindings: media: add ITE IT6625/IT6626 HDMI bridge binding
      media: i2c: add driver for ITE IT6625/IT6626

 .../devicetree/bindings/media/i2c/ite,it6625.yaml  |  174 ++
 MAINTAINERS                                        |    7 +
 drivers/media/i2c/Kconfig                          |   18 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/it6625.c                         | 2231 ++++++++++++++++++++
 5 files changed, 2431 insertions(+)
---
base-commit: 8dac27bfa2f994ecb11f01a63641527d17d48fc1
change-id: 20260716-upstream-it6625-it6626-6874ab8a5305

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

