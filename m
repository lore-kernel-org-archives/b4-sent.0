From: Herman van Hazendonk <github.com@herrie.org>
Subject: [PATCH v6 0/2] media: i2c: add Aptina MT9M113 image sensor driver
Date: Sat, 06 Jun 2026 21:01:00 +0200
Message-Id: <20260606-submit-media-mt9m113-v6-0-8f6d0f79f4d1@herrie.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAG1uJGoC/43OsQ6DIBAG4FcxzKUBRIROfY+mg+CpN6ANUNLG+
 O5Ft05tbvov+b+7lUQICJFcqpUEyBhxmUtQp4q4qZtHoNiXTAQTipWh8Wk9Juqhx476ZDznNRV
 SOG1BGTCMlOojwICvg73dS54wpiW8jytZ7tsfYJaUUSaVlc66djDyOkEoj56XMJJdzM0/SlMUw
 bR2bd1o4PxL2bbtA2ly6DT/AAAA
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Herman van Hazendonk <github.com@herrie.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780772461; l=8920;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=DSa14s7IlKy5l6imkMxGi9Jlaiiz6kT2d/sCqrs7tVw=;
 b=XWe0ZqloDRCUU7Tg/etvfPFjnEwjPH3cP4ZjYi0/LLFCA0M7e+zw3fe3ZzOnZ78UUsMpFfnZC
 8IGYA1uqRvFDKjZpv2QBUy9VToFbfFuCPPmhi0s/gf3muERjNbltMtL
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 subdev driver for the Aptina (now ON Semiconductor) MT9M113
1.3 megapixel SoC image sensor with embedded ISP, as used on the HP
TouchPad (apq8060) front camera. The sensor is programmed over I2C and
streams YUV / RGB / monochrome over a 1-lane MIPI CSI-2 D-PHY link.

v6 addresses six Sashiko Gemini 3.1 findings raised on the v5 patchset,
all of which are real bugs introduced (or exposed) by the v3-r2 release-
callback restructure. One of them — the use-after-free in mt9m113_remove()
during sysfs unbind — was reproduced on hardware as a NULL-pointer
dereference in regulator_bulk_disable() and is fixed by the v6 reorder.

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
Changes in v6:

  - [High] mt9m113_start_streaming() failure path: drop the
    pm_runtime_set_suspended() call. It fails with -EAGAIN while
    runtime PM is still enabled, leaving the PM core in RPM_ACTIVE
    while the chip is in fact off; the next autosuspend would then
    fire mt9m113_runtime_suspend() and call mt9m113_power_off() a
    second time, underflowing both the clk prepare/enable refcount
    and the regulator enable count. Track the chip-off state via a
    new 'bool chip_off' on the sensor; mt9m113_runtime_suspend()
    consumes it to skip its own power_off when start_streaming has
    already collapsed the rail, and mt9m113_runtime_resume() clears
    it after a successful power_on().

  - [High] mt9m113_s_ctrl(): pm_runtime_get_if_in_use() return-code
    check changed from "pm_ret == 0" to "pm_ret <= 0". The old test
    misses any negative return -- in particular -EINVAL after
    pm_runtime_disable() has been called from mt9m113_remove(). With
    a still-open /dev/v4l-subdev* file descriptor, a control set
    issued after unbind would slip past the gate and dereference the
    devm-managed regmap that the driver core has already freed.

  - [High] mt9m113_probe(): early-error paths after kzalloc(sensor)
    but before error_ep_free now goto error_kfree so the sensor
    struct is freed on devm_cci_regmap_init_i2c() or mt9m113_parse_dt()
    failure. Without it those returns leaked the kzalloc.

  - [High] mt9m113_remove(): reorder so PM disable +
    mt9m113_power_off() + pm_runtime_set_suspended() all run BEFORE
    v4l2_async_unregister_subdev(). When no userspace fd is open on
    /dev/v4l-subdev*, async_unregister synchronously fires the per-
    subdev .release callbacks, the last of which runs kfree(sensor);
    every subsequent use of @sensor or @dev (v4l2_fwnode_endpoint_free,
    mt9m113_power_off) was a use-after-free.

    Reproduced on hardware (HP TouchPad / APQ8060): a plain
       echo 3-003c > /sys/bus/i2c/drivers/mt9m113/unbind
    produces a kernel panic with
       Unable to handle kernel NULL pointer dereference at 0x00000058
       PC is at regulator_bulk_disable+0x4c/0x108
       LR is at mt9m113_power_off+0x78/0x7c
    on the v5 kernel. v6 reorders cleanly survives the same unbind
    plus a 60 s concurrent VIDIOC_QUERYCTRL / S_CTRL spammer.

  - [High] v4l2_fwnode_endpoint_free(&sensor->bus_cfg) moved from
    mt9m113_remove() into mt9m113_release_sensor() (the
    release_count == 0 finalizer). bus_cfg.link_frequencies is
    referenced by the IFP control handler's qmenu_int (stored by
    v4l2_ctrl_new_int_menu(V4L2_CID_LINK_FREQ) in probe). The
    control handler outlives remove() under the deferred-release
    model; freeing the endpoint in remove() would leave qmenu_int
    dangling and turn a later VIDIOC_QUERYMENU into a UAF.

  - [Med] mt9m113_ifp_set_fmt(): "if (sensor->streaming) return
    -EBUSY" narrowed to fire only when fmt->which ==
    V4L2_SUBDEV_FORMAT_ACTIVE. V4L2_SUBDEV_FORMAT_TRY queries are
    scratchpad probes by definition and must always be allowed,
    including while the pipeline is live.

  - [Low] dt-bindings: endpoint properties gain
    data-lanes: { maxItems: 1 } so DT entries that try to assign
    more than one lane fail dt_binding_check at validation time
    rather than only at probe time when the driver enforces
    num_data_lanes == 1.

  - [Prep] mt9m113_start_streaming(): add __must_hold(state->lock)
    annotation so sparse -Wcontext can verify the caller of
    s_stream(1) really did acquire the V4L2 subdev-state lock
    via v4l2_subdev_lock_and_get_active_state() before getting
    here. Today sparse cannot fully prove this (the v4l2-subdev
    framework helpers are not yet __acquires/__releases-tagged
    in include/media/v4l2-subdev.h), but the annotation is
    correct on our side and Just Works once core picks them up.

Changes since v4 (already in v5):

  - 5 findings from Sashiko's review of v4: Kconfig select V4L2_FWNODE;
    stream_context_a propagates SEQ_CMD_RUN poll timeout; start_streaming
    retry loop bypasses runtime-PM (bridge device-link blocks normal
    suspend) by toggling power directly; V4L2_CID_TEST_PATTERN rolls
    back test_pattern_active on apply failure; per-subdev .release
    callbacks defer ctrl handler / entity / sensor-struct teardown past
    v4l2_async_unregister_subdev so in-flight VIDIOC_S_CTRL ioctls do
    not unlock freed memory.

  - 1 regression caught during HW unbind/rebind race testing of the
    above: trailing mt9m113_power_off() in the retry loop double-called
    power_off (each break path already powered the chip down), which
    underflowed clk + regulator refcounts. Dropped the redundant
    trailing call; every break path is now responsible for its own
    final-state.

Changes since v3 (already in v4):

  - Context B (1280x1024 capture) stream-start regression fix: the
    MT9M113_SEQ_STATE_PREVIEW constant was 0x04 (datasheet's "Leave
    preview" transient state); the actual stable preview state is 0x03.

  - Forensic NOTE comment above MODE_TEST_MODE documenting the IFP
    test-pattern generator silicon-removal investigation.
    V4L2_CID_TEST_PATTERN plumbing is retained on the chance a different
    silicon variant or vendor SROM patch enables the TPG block.

Changes since v2 (already in v3):

  - Krzysztof + Sakari binding feedback: maxItems on reset-gpios /
    powerdown-gpios; drop |- from descriptions; drop redundant
    link-frequencies / remote-endpoint / data-lanes; rename i2c0 -> i2c.

  - MAINTAINERS entry per patchwork checkpatch.

Pre-send verification (v6, HP TouchPad APQ8060, kernel
7.1.0-rc1-luneos-geba82cc2ec7a):

  - pre-send-check.sh 8/8 PASS, including:
      * sparse on drivers/media/i2c/mt9m113.c -- clean
      * coccinelle scans for the three regression patterns we just
        fixed (pm_runtime_get_if_in_use() == 0; v4l2_fwnode_endpoint_free
        in remove(); sensor deref after v4l2_async_unregister_subdev)
        -- no matches.

  - Sashiko AI preflight (claude-haiku-4-5): 0 actionable findings;
    16 of 16 prior-stage concerns self-dismissed.

  - HP TouchPad on-HW sweep:
      * test-camera.sh PIX 640x480 + 1280x1024 capture -- PASS
      * 10x rapid pix640 stream-start stress -- 10/10 ok
      * 10x rapid pix1280 stream-start stress (Context B path) -- 10/10 ok
      * 60s mt9m113 sysfs unbind/rebind cycle racing concurrent
        VIDIOC_QUERYCTRL / S_CTRL spammers on /dev/v4l-subdev10 +
        /dev/v4l-subdev11 -- driver survives, re-binds cleanly,
        zero Oops / BUG / null-pointer-deref. This is the exact
        scenario that produced the regulator_bulk_disable NULL deref
        on the v5 kernel; v6 is silent.
      * 120s concurrent multi-subsystem load (camera stream loop +
        dd to eMMC + /dev/urandom + filesystem walk) -- clean.
      * dmesg post-sweep totals: 0 WARN, 0 BUG, 0 Oops, 0 clk-refcount
        underflow, 0 regulator-refcount underflow.

  - Kernel build clean (ARCH=arm cross-compile, CONFIG_VIDEO_MT9M113=y).
  - dt_binding_check clean (0 warnings) after the data-lanes maxItems
    constraint was added.

- Link to v4: https://lore.kernel.org/r/20260606-submit-media-mt9m113-v4-0-046b4cbc7f94@herrie.org
- Link to v5: https://lore.kernel.org/r/20260606-submit-media-mt9m113-v5-0-2088c7358e11@herrie.org

---
Herman van Hazendonk (2):
      dt-bindings: media: i2c: add aptina,mt9m113
      media: i2c: add Aptina MT9M113 1.3 Mpx SoC sensor driver

 .../bindings/media/i2c/aptina,mt9m113.yaml         |  130 +
 MAINTAINERS                                        |    8 +
 drivers/media/i2c/Kconfig                          |   13 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/mt9m113.c                        | 3306 ++++++++++++++++++++
 5 files changed, 3458 insertions(+)
---
base-commit: 944125b4c454b58d2fe6e35f1087a932b2050dff
change-id: 20260606-submit-media-mt9m113-242c8be69e90

Best regards,
-- 
Herman van Hazendonk <github.com@herrie.org>

