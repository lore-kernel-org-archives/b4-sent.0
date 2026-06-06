From: Herman van Hazendonk <github.com@herrie.org>
Subject: [PATCH v5 0/2] media: i2c: add Aptina MT9M113 image sensor driver
Date: Sat, 06 Jun 2026 14:35:26 +0200
Message-Id: <20260606-submit-media-mt9m113-v5-0-2088c7358e11@herrie.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA4UJGoC/4WOTQ6CMBCFr0Jm7ZhSK1pX3sOwoGWAWRTMtBIN6
 d2tXMC81feS97NBJGGKcKs2EFo58jIXOB8q8FM3j4TcFwatdKOKML5c4ISBeu4wJBvq+oTaaH9
 11FiyCkr0KTTwe699tIUnjmmRz76ymp/7p3A1qFCZxhnv/GWw5j6RlKPHRUZoc85fLQdF3rkAA
 AA=
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Herman van Hazendonk <github.com@herrie.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780749326; l=6552;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=Gzx9HxWa4AXbjKi3u14vusmbkNBTIyZW73WJQXjm9uY=;
 b=+O83h6yMB4py5DeUjH1W8QZVz1VIvg7EUlX4ZMlUNzeSDW+jxDBZWcJDuoGZb3kndwdHoD5eQ
 m/ambjDNr1WCofBJou4D2mAac4c3TtLC5HuHdyNm81tgiJ48WXEtMAa
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 subdev driver for the Aptina (now ON Semiconductor) MT9M113
1.3 megapixel SoC image sensor with embedded ISP, as used on the HP
TouchPad (apq8060) front camera. The sensor is programmed over I2C and
streams YUV / RGB / monochrome over a 1-lane MIPI CSI-2 D-PHY link.

v5 addresses 5 Sashiko findings on the v4 patchset plus a follow-up
regression caught by an on-HW unbind-during-stream-start race test
(see "Test results" below).

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
Changes in v5:

  - [Low]  Kconfig: select V4L2_FWNODE alongside V4L2_CCI_I2C. The
    driver calls v4l2_fwnode_endpoint_alloc_parse() / _free() and
    embeds struct v4l2_fwnode_endpoint, so it needs to select the
    helper rather than rely on transitive selection from the host
    bridge (qcom-camss).

  - [High] mt9m113_stream_context_a(): propagate the SEQ_CMD_RUN
    poll timeout instead of unconditionally returning 0. The
    bounded retry loop in mt9m113_start_streaming() can now
    actually retry the wedged MCU; previously the silent return 0
    let the pipeline stream from an unconfigured chip.

  - [High] mt9m113_start_streaming(): take a single PM reference
    for the whole retry loop and bypass runtime PM between
    attempts. V4L2 bridges hold a managed DL_FLAG_PM_RUNTIME
    device-link reference on this sensor for the duration of
    s_stream, so the prior pm_runtime_put_sync_suspend() /
    pm_runtime_resume_and_get() pair was rejected with -EBUSY and
    the MCU was never actually power-cycled between attempts.
    The retry body now calls mt9m113_power_off() /
    mt9m113_power_on() / mt9m113_sensor_init() directly; on
    terminal failure pm_runtime_set_suspended + put_noidle keeps
    the PM core coherent with the hardware state.

  - [Med]  V4L2_CID_TEST_PATTERN: only set test_pattern_active /
    test_pattern_value after mt9m113_apply_test_pattern() succeeds.
    Previously a failed apply left test_pattern_active = true
    forever, causing every subsequent s_ctrl refresh site to skip
    its refresh thinking the MCU was halted.

  - [High] mt9m113_remove(): defer per-subdev cleanup
    (v4l2_subdev_cleanup, v4l2_ctrl_handler_free,
    media_entity_cleanup) and the kfree of the surrounding sensor
    struct to per-subdev .release callbacks
    (mt9m113_ifp_release, mt9m113_pa_release).
    v4l2_async_unregister_subdev() does NOT block waiting for
    in-flight ioctls; freeing the ctrl handler (whose mutex an
    in-flight VIDIOC_S_CTRL may be holding) directly from remove()
    left the ioctl unlocking freed memory. Switched sensor
    allocation from devm_kzalloc to kzalloc and gated the kfree
    behind an atomic release_count so both PA and IFP devnodes
    must drain before the struct is reclaimed.

  - [High, found in HW test] mt9m113_start_streaming() failure
    path: the unconditional trailing mt9m113_power_off(sensor)
    after the retry loop double-disabled clk + regulator on every
    failure exit because each in-loop break already powered the
    chip down. The 3-WARN cluster
    (clk_core_disable / clk_core_unprepare / _regulator_disable
    underflow) reliably fired during the unbind-during-stream-start
    race test. Dropped the trailing power_off; rely on each break
    path to leave the chip off. Re-verified on HW: WARN cluster
    gone, retry mechanism still works end-to-end.

Test results (v5, HP TouchPad APQ8060, kernel 7.1.0-rc1):

  - test-camera.sh comprehensive: pix640 PASS (1.38 MB),
    pix1280 PASS (5.9 MB), video640 PASS. Context A (640x480) and
    Context B (1280x1024) stream-start both functional.

  - 10x rapid pix640 + 10x rapid pix1280 stream stress: 20/20
    streams started cleanly. No MCU wedge on this session; when
    a wedge does occur, dmesg now shows the
    "stream start failed (-110), power-cycle + retry N/M" trace
    instead of the pre-fix silent return 0.

  - 60s mt9m113_remove() / bind cycle racing concurrent
    VIDIOC_QUERYCTRL / S_CTRL spammers on both /dev/v4l-subdev*
    nodes: zero Oops, zero BUG, zero KASAN-style splat
    (this kernel has no KASAN; latent UAF could still go
    unobserved, but the macro-symptoms a UAF would produce are
    absent). Driver re-bound cleanly at the end.

  - 120s concurrent multi-subsystem load (camera stream loop +
    dd to eMMC + /dev/urandom + filesystem walk): clean,
    USB stayed up, MDP stayed active. Driver still bound at the
    end.

  - dmesg post-sweep: 0 WARN, 0 BUG, 0 Oops, 0 clk underflow,
    0 regulator underflow, 0 v4l2-subdev WARN.

  - Kernel build clean (ARCH=arm, CONFIG_VIDEO_MT9M113=y,
    arm-linux-gnueabihf-gcc).

Changes since v3 (already in v4):

  - Context B (1280x1024 capture) stream-start regression fix.
    The MT9M113_SEQ_STATE_PREVIEW constant was 0x04 (== datasheet's
    "Leave preview" transient state); the actual stable preview
    state is 0x03. The Context-B preview-first poll in
    stream_context_b() timed out on every 1280x1024 stream-start.

  - Forensic NOTE comment above MODE_TEST_MODE documenting the IFP
    test-pattern generator silicon-removal investigation
    (R0x321C bit 4 hardwired to 0, R0x3246..R0x3252 dead block).
    V4L2_CID_TEST_PATTERN plumbing retained on the chance a
    different silicon variant or vendor SROM patch enables the
    TPG block.

Changes since v2 (already in v3):

  - Address Krzysztof + Sakari binding feedback: maxItems on
    reset-gpios / powerdown-gpios; drop |- from descriptions; drop
    redundant link-frequencies / remote-endpoint / data-lanes;
    rename i2c0 -> i2c in example.

  - Add MAINTAINERS entry per patchwork checkpatch.

- Link to v4: https://lore.kernel.org/r/20260606-submit-media-mt9m113-v4-0-046b4cbc7f94@herrie.org

---
Herman van Hazendonk (2):
      dt-bindings: media: i2c: add aptina,mt9m113
      media: i2c: add Aptina MT9M113 1.3 Mpx SoC sensor driver

 .../bindings/media/i2c/aptina,mt9m113.yaml         |  122 +
 MAINTAINERS                                        |    8 +
 drivers/media/i2c/Kconfig                          |   13 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/mt9m113.c                        | 3252 ++++++++++++++++++++
 5 files changed, 3396 insertions(+)
---
base-commit: 944125b4c454b58d2fe6e35f1087a932b2050dff
change-id: 20260606-submit-media-mt9m113-242c8be69e90

Best regards,
-- 
Herman van Hazendonk <github.com@herrie.org>

