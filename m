From: Herman van Hazendonk <github.com@herrie.org>
Subject: [PATCH v7 0/2] media: i2c: add Aptina MT9M113 image sensor driver
Date: Sun, 07 Jun 2026 07:34:03 +0200
Message-Id: <20260607-submit-media-mt9m113-v7-0-5da397a3d2a5@herrie.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMwCJWoC/43OTQ6DIBAF4KsY1qVBRH666j2aLgQGZYE2YEkb4
 92L7pouamb1JnnfzIISRA8JXaoFRcg++WksQZwqZIZu7AF7WzKihHJSBqenDn7GAazvcJhVqOs
 GU0aN1MAVKIJK9RHB+dfO3u4lDz7NU3zvVzLbtn/AzDDBhHHNjDbCKXYdIJZHz1Ps0Sbm9ojSF
 oUSKY1oWgl1/aPwIwovinTcEieUY/ZbWdf1A4zgieZFAQAA
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Herman van Hazendonk <github.com@herrie.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780810444; l=7841;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=42fLcEQlvHtrRvBsmqhpJqSK16kzaWmVZEfXb41Pevg=;
 b=6kUCcTMc4ZSg/X69KIqlqA9tNmSQwrgie/CGHicweBRiI3mDtPtUifTYwZl52F5uIBTcx2G3T
 RHcIU1I83lMDdcef3ese6gEr5KFoJRO8snYgZK/bCm+yjM5o3Zcop1F
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 subdev driver for the Aptina (now ON Semiconductor) MT9M113
1.3 megapixel SoC image sensor with embedded ISP, as used on the HP
TouchPad (apq8060) front camera. The sensor is programmed over I2C and
streams YUV / RGB / monochrome over a 1-lane MIPI CSI-2 D-PHY link.

v7 self-review surfaced three additional Sashiko findings on the v6
patchset (Sashiko v6 preflight ran on claude-haiku-4-5 and missed them
- gemini-3.1 review on v7 catches them). The first two are real bugs;
the third is a refcount-init mismatch that would leak the sensor struct
in a no-bridge-attached unload. Folded together with two minor clang
static-analyzer findings.

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
Changes in v7:

  - [High] mt9m113_s_ctrl()/mt9m113_remove() race against the
    devm-managed @regmap. With a /dev/v4l-subdev* fd still open on
    sysfs unbind, the V4L2 ctrl handler outlives mt9m113_remove()
    (deferred-release model), but @regmap and @clk are devres-managed
    and get freed when remove() returns. An in-flight VIDIOC_S_CTRL
    that successfully called pm_runtime_get_if_in_use() before
    remove() called pm_runtime_disable() then dereferences the
    already-freed @regmap. The pm-gate change in v6 narrowed but did
    not close this TOCTOU.

    Fix: introduce a per-sensor `struct mutex lock` plus a `bool
    dying` flag. mt9m113_remove() takes the lock, sets ->dying, and
    drops the lock before any teardown; s_ctrl() takes the same lock
    after its pm-gate and bails on ->dying. Any in-flight s_ctrl()
    holds the lock past remove()'s lock-acquire, so remove() waits
    for it to finish before proceeding to pm_runtime_disable() +
    devres unwind. The mutex is destroyed in the sensor finalizer.

  - [High] mt9m113_start_streaming() exhaust-all-retries path leaves
    the PM state as RPM_ACTIVE while the chip is physically off
    (chip_off==true). Subsequent VIDIOC_S_CTRL calls would pass the
    pm_runtime_get_if_in_use() gate (PM still ACTIVE) and drive
    cci_writes into a dead I2C bus, timing out for 500 ms per write.

    Fix: in s_ctrl(), after acquiring the new sensor->lock, also
    bail on sensor->chip_off. Comment in struct mt9m113 expanded
    to document that chip_off is now both a runtime_suspend gate
    and an ioctl gate.

  - [Med] release_count was unconditionally initialised to 2,
    assuming both ifp.sd (async-registered) and pa.sd (only bound
    to a v4l2_device when a bridge driver attaches) would fire
    .release callbacks. If the module is unloaded before any
    bridge attaches, pa.sd's release never fires, release_count
    stays at 1, mt9m113_release_sensor() never reaches zero, and
    the sensor struct leaks.

    Fix: initialise release_count to 1 (for ifp.sd, always
    async-registered in probe), and atomic_inc() in
    mt9m113_ifp_registered() after pa.sd is bound to the bridge's
    v4l2_device. Comment on the field expanded to spell out the
    register/release accounting for every bind/unbind combination.

  - [Low] mt9m113_release_sensor(): call mutex_destroy(&sensor->lock)
    before kfree(sensor), so lockdep can flag any future attempt to
    take the lock through a stale pointer.

  - [Med] mt9m113_power_off() now ends with msleep(50) so back-to-
    back power_off -> power_on sequences (sysfs unbind/rebind loops
    and the start_streaming retry loop) see a real ramp-down before
    the next ramp-up. Without this delay the HP TouchPad's camera
    rails -- which have tens of microfarads of bulk capacitance --
    held VDD partly high across a fast cycle; the MT9M113 MCU then
    booted into an undefined state and SEQ_CMD wedged at 0x0001 or
    0x0006 forever (only a full off-time clears it -- soft reset
    via RESET_AND_MISC_CONTROL.RESET_SOC cannot recover the analog
    state). Discovered on-device during the v7 KFENCE race sweep:
    34 unbind/rebind cycles in 60 s produced "MCU var 0xa103
    timeout" / "REFRESH timeout" / -ETIMEDOUT on the subsequent
    stream-on attempts. 50 ms is conservative for the rail
    discharge time and invisible against PM autosuspend defaults
    (hundreds of ms).

Pre-send verification (v7, HP TouchPad APQ8060, kernel
7.1.0-rc1-luneos-g035108a0151b):

  - pre-send-check.sh 9/9 PASS, including:
      * sparse strict (-D__CHECK_ENDIAN__ -Wcontext) -- clean.
      * smatch (intra-function only; kernel-wide DB still building
        from build_kernel_data.sh) -- clean.
      * clang --analyze -- 2 dead-store warnings on `dev` locals
        in mt9m113_configure_sensor_context() and
        mt9m113_configure_ae_mode(); both false positives because
        `dev` is used inside dev_dbg() which expands to a no-op
        when CONFIG_DYNAMIC_DEBUG=n (the build config used by
        scan-build). On DYNAMIC_DEBUG=y kernels (where the dev_dbg
        machinery is wired up) `dev` is genuinely used. Source
        unchanged; documented here so the warnings do not appear
        novel on the next review pass.
      * coccinelle: 3 custom v4l2-lifetime cocci scripts + 72
        kernel cocci scripts -- no pattern matches.

  - HP TouchPad on-HW sweep against v7 driver kernel (commit
    fdb856651ae2, KFENCE-enabled tenderloin_debug_defconfig):
      * KFENCE alive: kfence: initialized - using 4194304 bytes
        for 511 objects at boot.
      * The C-finding scenario reproduced verbatim: held an open
        fd on /dev/v4l-subdev11 (mt9m113 ifp), spammed
        VIDIOC_S_CTRL horizontal_flip 32 calls/sec for 60 s while
        looping sysfs unbind -> bind on /sys/bus/i2c/drivers/
        mt9m113/. Result: 34 unbind/rebind cycles, 1920 concurrent
        S_CTRL calls, ZERO KFENCE reports, ZERO BUG / Oops / WARN /
        use-after-free / NULL-deref. Final state BOUND.
      * Same test on the pre-v7 driver (the v6 driver this series
        ships against) crashes regulator_bulk_disable+NULL on the
        first unbind cycle.
      * Streaming sweep after the brown-out fix above: 10/10
        pix640 + 10/10 pix1280 stream-start cycles succeed (vs
        3/10 + 0/10 pre-fix, which had 17 hard failures). 8 of
        the 20 cycles still hit a transient MCU SEQ_CMD wedge on
        the first attempt and recover via the existing v5
        retry-loop (power_off + power_on + sensor_init). These
        residual wedges trace to a Context A <-> Context B
        switching firmware quirk (logged as "Context B switch
        failed (SEQ_STATE=0x3)"), not to the rail-discharge
        issue this commit fixes; they are pre-existing sensor
        behaviour the retry loop was designed to mask.
      * dmesg post-sweep totals: 0 BUG, 0 Oops, 0 WARN, 0 UAF,
        0 NULL deref, 0 KFENCE reports.

- Link to v4: https://lore.kernel.org/r/20260606-submit-media-mt9m113-v4-0-046b4cbc7f94@herrie.org
- Link to v5: https://lore.kernel.org/r/20260606-submit-media-mt9m113-v5-0-2088c7358e11@herrie.org
- Link to v6: https://lore.kernel.org/r/20260606-submit-media-mt9m113-v6-0-8f6d0f79f4d1@herrie.org

---
Herman van Hazendonk (2):
      dt-bindings: media: i2c: add aptina,mt9m113
      media: i2c: add Aptina MT9M113 1.3 Mpx SoC sensor driver

 .../bindings/media/i2c/aptina,mt9m113.yaml         |  130 +
 MAINTAINERS                                        |    8 +
 drivers/media/i2c/Kconfig                          |   13 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/mt9m113.c                        | 3394 ++++++++++++++++++++
 5 files changed, 3546 insertions(+)
---
base-commit: 944125b4c454b58d2fe6e35f1087a932b2050dff
change-id: 20260606-submit-media-mt9m113-242c8be69e90

Best regards,
-- 
Herman van Hazendonk <github.com@herrie.org>

