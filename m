From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 11 Aug 2026 18:31:26 +0800
Subject: [PATCH v10 2/2] media: i2c: add driver for ITE IT6625/IT6626
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-upstream-it6625-it6626-v10-2-9b6bb75262c9@ite.com.tw>
References: <20260811-upstream-it6625-it6626-v10-0-9b6bb75262c9@ite.com.tw>
In-Reply-To: <20260811-upstream-it6625-it6626-v10-0-9b6bb75262c9@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786444285; l=94363;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=77SnYg5mQIIv/P8x2gFWKEnaRy4Le1PwfzblE6aYl58=;
 b=Kiw49c3tn7jWKqOSiUHKELEpXtyvrf3zLqUu90e4RXknXzQxl/J26S6ZE5VDMczcP5BXOitp4
 /E5VMB281b9A59BDVax+YUWbI6NnnCIDPhU36GNEl4AOPKSH3SqFM4y
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 subdevice driver for the ITE IT6625/IT6626 HDMI-to-MIPI
CSI-2 bridge chips. IT6625 accepts an HDMI 2.0 input and IT6626 an
HDMI 2.1 input, converting it to a D-PHY (or C/D-PHY on IT6626)
MIPI CSI-2 output. The bridge is configured over I2C, exposes an
HDMI CEC adapter, and supports EDID read/write, DV timings
detection/configuration, and HPD control via the standard V4L2
subdevice pad and video ops.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v10:
- Advertise the true single-logical-address CEC capability instead of
  CEC_MAX_LOG_ADDRS (4): confirmed against the hardware that
  CMD_SET_CEC_LA overwrites rather than adds an address, so claiming 4
  simultaneous addresses let the CEC core silently evict an
  already-configured one from hardware every time it claimed another.
  Also fix it6625_cec_adap_log_addr() to actually release the address
  in hardware on CEC_LOG_ADDR_INVALID (previously a no-op) by toggling
  CMD_SET_CEC_ENABLE off then on -- confirmed this fully resets both
  the logical address and monitor-all mode -- conditioned on
  adap->is_enabled so a call landing while the adapter should stay
  disabled doesn't silently re-enable it.
- Add .init_state so a freshly-opened subdev's V4L2_SUBDEV_FORMAT_TRY
  pad format isn't left zero-initialized, matching the pattern used by
  lt6911uxe.c, the closest comparable upstream HDMI-to-MIPI-CSI2
  bridge driver.
- Stop hardcoding IRQF_TRIGGER_LOW in the IRQ request: it unconditionally
  overrode whatever polarity the board's devicetree "interrupts"
  property configured. The reference DTS already specifies
  IRQ_TYPE_LEVEL_LOW so behavior there is unchanged.
- Add a dedicated edid_lock spanning the complete it6625_s_edid()
  sequence: previously each sub-step (disable_hpd/write_edid/
  cec_s_phys_addr/enable_hpd) was individually locked but the whole
  sequence wasn't, so two concurrent VIDIOC_SUBDEV_S_EDID calls could
  leave hardware programmed with one call's EDID while CEC recorded
  the other's physical address. Also fix a related probe() unwind bug
  found while adding this lock: an IRQ request failure returned
  directly instead of going through the existing cleanup path, leaking
  it6625_lock (pre-existing) and now edid_lock too.

All four found by the sashiko.dev automated review of v9. One other v9
review finding was checked and confirmed real, but is not being acted
on this round: a UAF where it6625_remove() can free devm-allocated
state while an ioctl on /dev/v4l-subdevX is still executing, since
subdev devnodes have no supported pre-registration lock/lifetime hook
a driver can use to close it -- doing so properly needs a
v4l2_subdev_release() core reorder (drivers/media/v4l2-core/
v4l2-device.c) plus a kref'd/gated driver restructuring, both out of
scope for this series.

- Fix it6625_cec_reset_la() to actually write CMD_SET_CEC_LA with
  CEC_LOG_ADDR_UNREGISTERED (0xf) when the adapter should stay
  enabled, instead of toggling CEC enable off and back on, which
  never cleared the logical address at all on that path.
- Drop the redundant CEC message dump (the CEC core already logs the
  full message hex on both TX/RX), replace two hardcoded message-size
  bounds with CEC_MAX_MSG_SIZE, and use dev_info instead of dev_err
  for an unrecognized CEC TX status byte, since it isn't necessarily
  an error.
- Use HZ/7 instead of msecs_to_jiffies(100) for the HPD delay -- more
  reliable across sources with inaccurate HPD-low timing.
- Raise V4L2_EVENT_SOURCE_CHANGE on signal loss too, not just on
  resolution change.
- Stop calling it6625_enable_stream(false) from it6625_s_dv_timings():
  video output should only be controlled by s_stream, not by
  S_DV_TIMINGS.
- Inline the three pad-ops DV-timings wrappers
  (s/g/query_dv_timings) directly into their bodies and drop the
  separate non-pad functions, which existed only to do a pad check
  before calling straight through.
- Track the actual number of loaded EDID blocks (new edid_blocks
  field, defaulting to 2 since firmware ships with a verified
  2-block default EDID already in EDID RAM at power-on) instead of
  always assuming a fixed EDID_NUM_BLOCKS_MAX, and rewrite
  it6625_g_edid()/it6625_s_edid() to match tc358743_g_edid()'s
  capacity-query/-ENODATA/-EINVAL semantics (using a subtraction-based
  clamp rather than tc358743's addition-based one, which can integer-
  overflow on attacker-controlled __u32 block counts).
  it6625_s_edid() now validates the CEC physical address with
  v4l2_get_edid_phys_addr()/v4l2_phys_addr_validate() before taking
  edid_lock or touching any hardware/CEC state, so a validation
  failure leaves everything untouched; a hardware write failure
  returns immediately, before the HPD-reenable block, leaving HPD
  disabled and edid_blocks at 0 rather than assuming the previous
  EDID is still valid.
- Drop the two custom IT6625_CID_HDMI_INFO/IT6625_CID_MIPI_CONFIG
  controls entirely. HDMI_INFO's format/fps string moves to
  it6625_log_status() instead (using a single locked snapshot of
  csi_format and the configured timings so the reported pair was
  actually configured together); MIPI_CONFIG exposed a raw settable
  MIPI data-type register with no real use case and is simply
  removed. it6625_g_volatile_ctrl()/it6625_s_ctrl()/it6625_ctrl_ops
  and two now-dead helpers (hdl_to_6625(), the unlocked
  it6625_set_mipi_config() wrapper) go with them.
- Add the required InfoFrame debugfs export (AVI/Audio/SPD/HDMI via
  v4l2_debugfs_if_alloc(); DRM is not wired up this round, not yet
  confirmed by hardware testing) and drop the edid_ram debugfs dump
  it replaces, which was redundant with G_EDID. Synchronizing the
  export against the interrupt path uses two new locks
  (if_read_lock/if_state_lock) and a driver-private
  if_active/if_snapshot/if_snapshot_done request-tracking state
  instead of pausing every interrupt producer; the interrupt-path
  drain is factored into it6625_drain_interrupts()/
  it6625_drain_rx_int_status() so both the interrupt handler and the
  debugfs callback share the same error-aware drain logic.
  it6625_remove() now frees the InfoFrame export before stopping the
  IRQ/timer/polling-work producers and before unregistering the
  subdevice, so no in-flight read or ordinary interrupt can be
  dispatched against already-torn-down state. Two hardware-side
  timing properties (whether disarming REG_IF_LATCH_HB synchronously
  prevents an already-latched packet from surfacing, and whether the
  one-shot capture is guaranteed to see the first triggering frame
  rather than a later one) can't be verified from source and are
  accepted as documented residual risk pending hardware confirmation.
- Reserve a proper V4L2_CID_USER_IT6625_BASE in v4l2-controls.h and
  move the two remaining audio controls
  (AUDIO_SAMPLING_RATE/AUDIO_PRESENT) into a new public
  include/uapi/linux/it6625.h, renamed to the public
  V4L2_CID_IT6625_* form -- the old locally-defined base collided
  with V4L2_CID_USER_NPCM_BASE. While touching this control's
  definition: raise the sampling-rate control's .max from 768000 to
  1536000 to match what get_audio_sampling_rate()'s s_fsid_map can
  actually report, check the REG_HDMI_AUDIO_INFO1 read for I2C
  failure instead of letting a negative error code truncate into the
  u8 FSID comparison, and store exact Hz values in s_fsid_map instead
  of a lossy *1000 shorthand that rounded five 44.1kHz-family rates
  (including the previously-missing AUD1411K entry) away from their
  real CEA/IEC values, and title-case both controls' .name strings
  ("Audio Sampling Rate"/"Audio Present") to match what Hans's
  review quoted them as -- missed in the reservation fix above,
  applied now.

All of the above found by Hans Verkuil's on-list review of v9.

- Raise the DV-timings cap and correct V4L2_CID_LINK_FREQ reporting
  for IT6626's three-trio C-PHY link (it6626_cphy_3trio_timings_cap/
  it6625_get_timings_cap(), and a new C-PHY entry in
  it6625_link_freq[]). The previous shared 300 MHz DV-timings cap
  and single fixed 445.5 MHz link-frequency value meant this driver
  could never accept or correctly describe a 4K60 4:4:4/RGB timing
  on this topology, even though the chip supports it there. This
  was deferred pending two things, both now confirmed:
  2.5 Gsym/s confirmed as the hardware's max C-PHY capability for
  the tested single-port, three-trio configuration, and 4K60 RGB444
  capture on that configuration confirmed working -- tested on an
  MTK G720 platform, which supports C-PHY but is a different SoC
  than this driver's existing Qualcomm CAMSS reference deployment
  documented in Testing below. Scoped to csi_lanes == 3 regardless
  of port_num, since the CSI-2 pixel-rate formula this cap is
  checked against has no port_num term; one- and two-trio C-PHY
  stay on the original cap/link frequency -- unvalidated at the
  higher rate, not proven incapable of it.

Changes in v9:
- Change it6625_interrupt_handler() to return bool and
  it6625_irq_handler() to translate that into IRQ_HANDLED/IRQ_NONE:
  the handler returned early without clearing REG_MCU_INTERRUPT
  whenever the read was spurious (val == 0) or failed (val < 0), yet
  the IRQ handler unconditionally returned IRQ_HANDLED. On that path
  no IT6625 interrupt source was observed for this invocation, so
  always reporting IRQ_HANDLED regardless defeats the kernel's
  spurious-IRQ storm protection, which relies on IRQ_NONE to identify
  and disable misbehaving lines. Matches the pattern already used by
  tc358743.c and adv7604.c. Found by the sashiko.dev automated review
  of v8.
- Take it6625_lock in it6625_initial_setup(): it wrote
  B_CONFIG_UPDATE to REG_HOST_CTRL_INT and polled for it to clear
  without holding the lock, but it runs from probe() after
  cec_register_adapter() has already exposed /dev/cecX to userspace,
  and it6625_cec_adap_transmit() (reachable immediately via a CEC
  ioctl) sets B_CEC_SEND_DATA in the same register under the lock.
  Every other accessor of REG_HOST_CTRL_INT already took the lock;
  this was the sole exception. Single call site, lock already
  initialized before it, so no deadlock is introduced. Found by the
  sashiko.dev automated review of v8.

One other v8 review finding was checked and is not being acted on:
- fps_from_bt_timings() computing
  V4L2_DV_BT_FRAME_HEIGHT(t) * V4L2_DV_BT_FRAME_WIDTH(t) as a 32-bit
  product, which the review claims can overflow to 0 given
  V4L2_DV_BT_CAP_CUSTOM's relaxed matching. Checked: it6625->timings,
  the only value this function is ever called on, is populated only
  by it6625_update_timings_if_changed(), which rejects anything
  failing v4l2_valid_dv_timings() against it6625_timings_cap (width
  640-3840, height 480-2160), or by a static default.
  v4l2_valid_dv_timings() additionally bounds every porch field
  (hfrontporch/hsync/hbackporch <= 3x width;
  vfrontporch/vsync/vbackporch/il_* <= 10240). Given those caps the
  maximum possible FRAME_WIDTH * FRAME_HEIGHT is
  38400 x 63600 ~= 2.44x10^9, safely under 2^32 ~= 4.29x10^9 -- the
  claimed overflow input is mathematically unreachable through this
  driver's validated timings path.

Changes in v8:
- Drop of_match_ptr() around it6625_of_match in the i2c_driver: the
  table is unconditionally compiled in, so wrapping it is unnecessary
  and risks an unused-variable warning on configs without CONFIG_OF.
  Found by Krzysztof Kozlowski's on-list review of v7.
- Stop halving bt->pixelclock for interlaced signals in
  it6625_get_detected_timings(). Checked against the IT6625 spec: for
  an interlaced source (e.g. 1080i) the chip's built-in MCU already
  reports REG_VID_PCLK as the correct, real pixel clock (74.25 MHz for
  1080i, not a half-rate/field clock), while the height it reports is
  the per-field active height (540), which the existing
  "bt->height *= 2" correctly turns into the true full-frame height.
  Dividing the already-correct pixel clock by 2 on top of that mangled
  it to 37.125 MHz, understating the reported frame rate by half.
  Found by the sashiko.dev automated review of v7. il_vfrontporch/
  il_vbackporch are still left unset for interlaced signals -- the
  IT6625 MCU has no separate second-field porch registers, so there's
  nothing to read for them; not fixed, since there's nothing to fix in
  software.

One other v7 review finding was checked and is not being acted on:
- it6625_get_fmt() unconditionally writes the live detected timings
  into format->format.width/height/field regardless of TRY vs ACTIVE,
  and it6625_set_fmt()'s TRY branch only persists code/colorspace into
  sd_state. This exactly matches tc358743_get_fmt()/tc358743_set_fmt()
  in tc358743.c, which never consult sd_state for width/height/field
  in either TRY or ACTIVE either. For this class of HDMI-receiver
  bridge, frame dimensions are dictated by the detected external
  signal, not independently negotiable via TRY -- only the pixel
  format (code/colorspace) is meaningfully TRY-isolatable, and that's
  exactly what both drivers isolate. Found by the sashiko.dev
  automated review of v7.

Also, per Krzysztof Kozlowski's on-list review: the it6625/it6626
of_device_id entries do encode a real behavioral difference --
it6625_parse_endpoint() rejects C-PHY endpoints unless
chip_type == IT6626_CHIP, so "ite,it6625" boards are correctly
restricted to D-PHY. Replying on-list to point this out, not a code
change.

Changes in v7:
- Fix three correctness issues found by the automated review of v6:
  it6625_parse_endpoint() left the fwnode endpoint's bus_type as
  V4L2_MBUS_UNKNOWN so v4l2_fwnode_endpoint_alloc_parse() could
  autodetect C-PHY vs D-PHY, but if the endpoint node has none of the
  CSI-2-specific properties, the parser silently falls back to
  V4L2_MBUS_PARALLEL/BT656 instead -- the driver then read
  endpoint.bus.mipi_csi2.num_data_lanes unconditionally, treating
  memory populated as a different union member as a lane count.
  it6625_set_fmt()'s V4L2_SUBDEV_FORMAT_ACTIVE branch applied the new
  format to hardware but never updated format->format.colorspace like
  the TRY branch does, so VIDIOC_SUBDEV_S_FMT callers got back the
  stale colorspace from before the call. it6625_s_edid() never
  checked edid->start_block, contrary to the VIDIOC_S_EDID spec
  (Documentation/userspace-api/media/v4l/vidioc-g-edid.rst), which
  requires -EINVAL for any start_block other than 0 since setting an
  EDID is all-or-nothing; added the same check already present in
  adv7604_s_edid(), tc358743_s_edid() and adv7842_s_edid() for the
  same requirement.

Changes in v6:
- Fix two correctness issues found by the automated review of v5:
  it6625_s_edid() called v4l2_phys_addr_validate() but discarded its
  return value, so a CEC physical address that failed topology
  validation (e.g. a gap like 1.0.1.0) still reached
  cec_s_phys_addr() and got broadcast on the CEC bus instead of being
  rejected; and it6625_parse_endpoint() pre-set the fwnode endpoint's
  bus_type to D-PHY before parsing, which (per
  include/media/v4l2-fwnode.h) makes the parser treat it as a hard
  requirement and reject any endpoint whose DT bus-type disagrees --
  every IT6626 C-PHY device tree failed to probe as a result.

One other v5 review finding was checked and is not being acted on:
- A concurrent VIDIOC_SUBDEV_S_EDID ioctl racing it6625_remove()'s
  cancel_delayed_work_sync() could in principle schedule
  hpd_delayed_work after teardown frees the driver state. Real in the
  abstract -- no lock serializes an in-flight ioctl against
  video_unregister_device() -- but the identical unlocked pattern
  (delayed work scheduled from the s_edid path, remove() doing only
  cancel_delayed_work_sync()) exists unfixed in tc358743.c and
  adv7604.c, and this is the same residual risk already dismissed in
  the v2/v3/v4 rounds of this series for the same reason: no peer
  driver adds extra synchronization for it either.

Changes in v5:
- Fix a kernel-stack-memory leak in it6625_edid_ram_show() and
  it6625_mipi_reg_show(): both printed an uninitialized on-stack
  register buffer to userspace via debugfs without checking whether
  the preceding I2C bulk read actually succeeded.
- Fix two related format-negotiation bugs: it6625_set_fmt()'s
  V4L2_SUBDEV_FORMAT_TRY branch never updated fmt->colorspace to
  match the new fmt->code, and it6625_get_fmt()'s TRY branch computed
  the returned colorspace from the active hardware state instead of
  the TRY state's own format, leaking active state into what should
  be an isolated TRY buffer -- store and read code and colorspace
  together in sd_state instead. Separately, it6625_set_fmt()'s
  active-format path released it6625_lock before programming the
  hardware, letting two concurrent S_FMT calls interleave and leave
  the hardware programmed for the wrong thread's format; add _locked
  variants of it6625_enable_stream()/it6625_set_mipi_config() and call
  them from inside set_fmt()'s existing lock scope so the whole
  update is now atomic.
- Fix it6625_s_edid(): per the VIDIOC_S_EDID spec, blocks == 0 must
  leave the EDID disabled ("no longer available"), but the driver
  disabled HPD and then fell through to the normal completion path,
  which unconditionally re-enabled it -- return immediately instead.
  Also stop a failed it6625_write_edid() from skipping the HPD
  re-enable entirely, which left HPD disabled permanently after any
  single failed S_EDID call.
- Take it6625_lock around it6625_mipi_reg_write()'s I2C write,
  matching every other register access in the driver.
- Derive IT6625_CID_HDMI_INFO's string from real state
  (it6625->csi_format and fps_from_bt_timings()) instead of returning
  a hardcoded "RGB444 10bit @ 60Hz" regardless of actual signal.
- Wire up the previously-unused reset-gpios line in probe(): acquire
  it via devm_gpiod_get_optional() and toggle it (assert briefly, then
  deassert and let it settle) before the first I2C access.

All found by the sashiko.dev automated review of v4. Three other v4
review findings were checked and are not being acted on:
- it6625_mipi_reg_show()'s raw register dump could destructively
  consume a pending CEC RX message via REG_CEC_RX_DATA (0x20) --
  checked with the hardware author: reading REG_CEC_RX_DATA is not
  destructive, only the explicit write-0 to REG_CEC_RX_DATA_LEN
  clears state. The v4 changelog's "likely clear-on-read" assumption
  for this same register was wrong.
- devm_kzalloc'd state + subdev devnode UAF-in-the-abstract on unbind
  -- same reasoning as the v2/v3 rounds: matches tc358743.c/adv7604.c/
  adv7842.c exactly, an accepted V4L2-subsystem-wide pattern, not a
  defect unique to this driver.
- Concurrent VIDIOC_SUBDEV_S_EDID racing it6625_remove()'s
  cancel_delayed_work_sync()/mutex_destroy() -- the same residual risk
  dismissed in the v3 round: real in the abstract, but no peer driver
  adds extra synchronization for it either, and the v2 round's fix
  (unregister the subdev first in remove()) already narrowed this to
  the same residual risk level every peer driver carries.

Changes in v4:
- Always acknowledge the CEC RX length register once the RX interrupt
  branch is entered, even when the reported length is invalid --
  previously the ack write only happened on valid lengths, so an
  invalid length left the interrupt asserted, which could storm the
  IRQ line.
- Fall back to a default format instead of returning -EINVAL from
  it6625_set_fmt() when the requested mbus code isn't recognized,
  matching the V4L2 subdev set_fmt convention (cf. adv7604.c). Take
  it6625_lock around it6625_get_fmt()'s ACTIVE-path reads of
  csi_format/mbus_fmt_code, which could otherwise observe a torn
  update from a concurrent set_fmt().
- Fix EDID ioctl spec conformance: it6625_g_edid() now clamps the
  requested block count and returns success instead of propagating an
  error when the request exceeds capacity; it6625_s_edid() now returns
  -E2BIG (not -EINVAL) with blocks set to the maximum, without
  attempting the write, when the request exceeds capacity; and
  it6625_read_edid()/it6625_write_edid()'s low-level bounds check now
  tests start_block and num_blocks individually before summing them,
  since the sum could otherwise overflow given the unsigned __u32
  fields of struct v4l2_edid.
- Harden the mipi_reg debugfs handlers: it6625_mipi_reg_write() now
  always parses from a local offset that starts at 0 instead of the
  real file offset, since this is a stateless one-write-one-command
  interface, not a seekable stream; it6625_mipi_reg_show() now takes
  it6625_lock around its raw register-bank read, matching every other
  banked-register access in the driver (the dumped range also includes
  REG_CEC_RX_DATA, which the CEC handler treats as clear-on-read, so an
  unlocked read could silently steal a pending CEC RX message).
- Mark the HDMI info control (IT6625_CID_HDMI_INFO) volatile:
  it6625_g_volatile_ctrl() already had a live case for it, but the
  control's v4l2_ctrl_config was missing V4L2_CTRL_FLAG_VOLATILE, so
  that case was never actually reached and the control's value was
  never refreshed.

All found by the sashiko.dev automated review of v3.

Separately, not a review finding: remove a redundant FW-start register
trigger from it6625_initial_setup() -- the chip's firmware starts
automatically on power-on, so the explicit software trigger was dead
weight.

Changes in v3:
- Finish the banked-register locking from v2: it6625_irq_infoframe_latch()
  and get_audio_sampling_rate() also read banked registers without
  it6625_lock; take the lock inside the CEC RX branch across the
  length read, data read and length-clear together (closing a TOCTOU
  where the length could go stale under lock contention), and stop the
  RX branch from using an early return that skipped a simultaneous CEC
  TX interrupt.
- Fix it6625_s_edid() incorrectly treating a successful EDID write as
  a failure: it6625_write_edid() returns a positive block count on
  success, not 0, so `if (err)` skipped the CEC phys-addr update and
  HPD re-enable on every successful write. Pre-existing since v1, not
  introduced by the v2 blocks==0 handling.
- Add real V4L2_SUBDEV_FORMAT_TRY support in get_fmt/set_fmt via
  sd_state, matching the pattern used by adv7604.c, and lock the
  csi_format/mbus_fmt_code commit in the ACTIVE path against
  concurrent S_FMT calls.
- Read the chip's real porch/sync-width registers
  (REG_H_FP_1..REG_V_BP_0) in it6625_get_detected_timings() instead of
  lumping the whole blanking interval into hsync/vsync, so detected
  timings can actually match the standard CEA/VESA tables.

All found by the sashiko.dev automated review of v2. Four other v2
review findings were checked against the code and are not being acted
on:
- "timer_container_of() doesn't exist" -- it does
  (include/linux/timer.h), the driver already builds clean with it.
- "devm_kzalloc'd state + subdev devnode risks a UAF on unbind" --
  true in the abstract, but it's the exact pattern used by every
  comparable in-tree driver (tc358743.c, adv7604.c, adv7842.c all
  devm_kzalloc their main state struct despite setting
  V4L2_SUBDEV_FL_HAS_DEVNODE too).
- "unregistering the subdev before disabling IRQ/work in remove()
  leaves sd->devnode dangling" -- checked the core:
  v4l2_device_unregister_subdev() only marks sd->devnode unregistered
  via video_unregister_device(), it does not free it; the struct is
  freed later via kref on last close, so the pointer stays valid.
- the residual "ioctl reschedules hpd_delayed_work concurrently with
  remove()" race -- real in the abstract (requires an ioctl already
  in flight at the exact moment of unbind), but no peer driver adds
  extra synchronization for this either (none set sd->devnode->lock),
  and the v2 fix (unregister first in remove()) already narrowed this
  down to the same residual risk level every peer driver carries.

Changes in v2:
- Fix premature v4l2_async_register_subdev(): move it to the end of
  probe() (after ctrl handler, CEC and initial hardware setup), and
  mirror the unregister order at the top of remove(), closing a
  use-after-free window where a concurrent ioctl could reschedule
  hpd_delayed_work during teardown.
- Take it6625_lock around the banked register reads in
  it6625_get_detected_timings() and the CEC RX path in
  it6625_cec_handler(), which could otherwise race with an in-progress
  EDID read/write and observe the wrong bank.
- Fix it6625_wait_for_status()'s poll interval exceeding the timeout
  budget, split the CEC RX/TX interrupt handling out of an else-if so
  simultaneous events aren't dropped, and wait for hardware to latch
  the CEC transmit trigger bit before releasing the lock.
- Stop it6625_set_fmt() from mutating active state on
  V4L2_SUBDEV_FORMAT_TRY, and handle edid->blocks == 0 in g_edid/s_edid
  per the V4L2 spec (capacity query / EDID clear).
- Zero-initialize the CEC rxmsg and debugfs mipi_reg write buffer to
  avoid leaking uninitialized stack bytes, and use designated
  initializers in the i2c_device_id table.

All found by the sashiko.dev automated review of v1.
---
 MAINTAINERS                        |    8 +
 drivers/media/i2c/Kconfig          |   18 +
 drivers/media/i2c/Makefile         |    1 +
 drivers/media/i2c/it6625.c         | 2394 ++++++++++++++++++++++++++++++++++++
 include/uapi/linux/it6625.h        |   25 +
 include/uapi/linux/v4l2-controls.h |    6 +
 6 files changed, 2452 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 3785b8c1de0a61b6e0be2f8b0bc506b6f23ec25b..0036fc35227ca5937bc1b894b29c4336507bcb9d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -13850,6 +13850,14 @@ T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
 F:	Documentation/devicetree/bindings/display/bridge/ite,it66121.yaml
 F:	drivers/gpu/drm/bridge/ite-it66121.c
 
+ITE IT6625 HDMI to MIPI MEDIA DRIVER
+M:	Hermes Wu <Hermes.Wu@ite.com.tw>
+S:	Maintained
+T:	git git://linuxtv.org/media.git
+F:	Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
+F:	drivers/media/i2c/it6625.c
+F:	include/uapi/linux/it6625.h
+
 IVTV VIDEO4LINUX DRIVER
 M:	Andy Walls <awalls@md.metrocast.net>
 L:	linux-media@vger.kernel.org
diff --git a/drivers/media/i2c/Kconfig b/drivers/media/i2c/Kconfig
index 5c52007f9cbeb77fa3adf3008428f4d1dc529203..c1b7a53fbe43a2669f9a562bd657a4fc09f6708d 100644
--- a/drivers/media/i2c/Kconfig
+++ b/drivers/media/i2c/Kconfig
@@ -1301,6 +1301,24 @@ config VIDEO_ISL7998X
 	  Support for Intersil ISL7998x analog to MIPI-CSI2 or
 	  BT.656 decoder.
 
+config VIDEO_IT6625
+	tristate "IT6625 HDMI to MIPI CSI bridge"
+	depends on VIDEO_DEV && I2C
+	depends on OF
+	select CEC_CORE
+	select MEDIA_CONTROLLER
+	select REGMAP_I2C
+	select V4L2_FWNODE
+	select VIDEO_V4L2_SUBDEV_API
+	help
+	  V4L2 subdevice driver for the ITE IT6625/IT6626 HDMI to MIPI
+	  CSI-2 bridge chips. IT6625 accepts an HDMI 2.0 input and
+	  IT6626 an HDMI 2.1 input, converting it to a MIPI CSI-2
+	  output. The driver also exposes an HDMI CEC adapter.
+
+	  To compile this driver as a module, choose M here: the
+	  module will be called it6625.
+
 config VIDEO_LT6911UXE
 	tristate "Lontium LT6911UXE decoder"
 	depends on ACPI && VIDEO_DEV && I2C
diff --git a/drivers/media/i2c/Makefile b/drivers/media/i2c/Makefile
index d04bd5724552e88fc2ad39f9bbaf9b4ce1763939..b54145f685d65e28aaaaf2be296766c9f913eea9 100644
--- a/drivers/media/i2c/Makefile
+++ b/drivers/media/i2c/Makefile
@@ -65,6 +65,7 @@ obj-$(CONFIG_VIDEO_IMX678) += imx678.o
 obj-$(CONFIG_VIDEO_IMX471) += imx471.o
 obj-$(CONFIG_VIDEO_IR_I2C) += ir-kbd-i2c.o
 obj-$(CONFIG_VIDEO_ISL7998X) += isl7998x.o
+obj-$(CONFIG_VIDEO_IT6625) += it6625.o
 obj-$(CONFIG_VIDEO_KS0127) += ks0127.o
 obj-$(CONFIG_VIDEO_LM3560) += lm3560.o
 obj-$(CONFIG_VIDEO_LM3646) += lm3646.o
diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
new file mode 100644
index 0000000000000000000000000000000000000000..80610cce196266ced10917f88fe4310f0f2a84fa
--- /dev/null
+++ b/drivers/media/i2c/it6625.c
@@ -0,0 +1,2394 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * it6625 - ite HDMI to MIPI bridge
+ */
+#include <linux/bitfield.h>
+#include <linux/clk.h>
+#include <linux/completion.h>
+#include <linux/debugfs.h>
+#include <linux/delay.h>
+#include <linux/gpio/consumer.h>
+#include <linux/hdmi.h>
+#include <linux/i2c.h>
+#include <linux/interrupt.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/of_graph.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+#include <linux/timer.h>
+#include <linux/v4l2-dv-timings.h>
+#include <linux/videodev2.h>
+#include <linux/workqueue.h>
+
+#include <media/cec.h>
+#include <media/v4l2-ctrls.h>
+#include <media/v4l2-device.h>
+#include <media/v4l2-dv-timings.h>
+#include <media/v4l2-event.h>
+#include <media/v4l2-fwnode.h>
+#include <uapi/linux/it6625.h>
+
+static int debug = 3;
+module_param(debug, int, 0644);
+MODULE_PARM_DESC(debug, "debug level (0-3)");
+
+#define REG_CHIP_ID_0 0x00
+#define REG_CHIP_ID_1 0x01
+#define REG_FW_VER_MAJOR 0x03
+#define REG_FW_VER_MINOR 0x04
+#define REG_PROTOCOL_VERSION 0x05
+#define B_PVER_MINOR  BIT(0)
+#define B_PVER_MAJOR  BIT(4)
+
+#define REG_CMD_SET 0x10
+#define CMD_SET_CEC_LA 0xC0
+#define CMD_SET_CEC_ENABLE 0xC1
+
+#define REG_EDID_START 0x20
+#define REG_CEC_RX_DATA 0x20
+#define REG_CEC_TX_DATA 0x30
+
+#define REG_H_ACTIVE_1 0x50
+#define REG_H_ACTIVE_0 0x51
+#define REG_V_ACTIVE_1 0x52
+#define REG_V_ACTIVE_0 0x53
+#define REG_H_TOTAL_1 0x54
+#define REG_H_TOTAL_0 0x55
+#define REG_V_TOTAL_1 0x56
+#define REG_V_TOTAL_0 0x57
+#define REG_VID_PCLK 0x58
+#define REG_H_FP_1 0x5C
+#define REG_H_FP_0 0x5D
+#define REG_H_SW_1 0x5E
+#define REG_H_SW_0 0x5F
+#define REG_H_BP_1 0x60
+#define REG_H_BP_0 0x61
+#define REG_V_FP_1 0x62
+#define REG_V_FP_0 0x63
+#define REG_V_SW_1 0x64
+#define REG_V_SW_0 0x65
+#define REG_V_BP_1 0x66
+#define REG_V_BP_0 0x67
+#define REG_VID_INFO 0x68
+#define B_INTERLACE  BIT(0)
+#define B_HSWPOL  BIT(1)
+#define B_VSWPOL  BIT(2)
+#define B_PIXEL_REP  BIT(4)
+
+#define REG_VIC 0x69
+#define REG_HDMI_VIDEO_INFO 0x6A
+#define B_COLOR_MODE  BIT(0)
+#define B_COLOR_DEPTH  BIT(4)
+#define REG_HDMI_AUDIO_INFO1 0x6B
+#define B_AUD_FS  BIT(0)
+
+#define REG_HDMI_AUDIO_INFO2 0x6C
+#define B_AUD_CH  BIT(0)
+#define B_AUD_WL  BIT(4)
+
+#define REG_HDMI_AUDIO_INFO3 0x6D
+#define B_AUD_TYPE  BIT(0)
+#define B_AUD_MS  BIT(2)
+#define B_AUD_3D  BIT(3)
+
+#define REG_AUDIO_FMT 0x6E
+#define B_I2S_WL  BIT(0)
+#define B_I2S_ALN BIT(2)
+#define B_I2S_DLY BIT(3)
+#define B_I2S_LR  BIT(4)
+#define B_I2S_SFT BIT(5)
+#define B_AUD_OUT_IF  BIT(6)
+
+#define REG_IF_LATCH_HB 0x6F
+#define REG_IF_DATA 0x70
+#define REG_EMP_DATA 0xA0
+#define REG_AVI_DATA 0xAE
+
+#define REG_TX_STATUS 0xE0
+
+#define REG_RX_STATUS 0xE2
+#define B_RX_5V BIT(0)
+#define B_RX_HPD BIT(1)
+#define B_RX_STABLE BIT(2)
+#define B_RX_HDMI BIT(3)
+#define B_RX_AVMUTE BIT(4)
+#define B_RX_AUD_ON BIT(5)
+
+#define REG_RX_HDCP_STS 0xE3
+#define B_HDCP1_AUTH_START BIT(0)
+#define B_HDCP2_AUTH_START BIT(1)
+#define B_HDCP_AUTH_DONE BIT(2)
+#define B_HDCP_ENC BIT(3)
+
+#define REG_CEC_STATUS 0xE4
+#define B_CEC_TX_DONE BIT(0)
+#define B_CEC_TX_NACK BIT(1)
+
+#define REG_CEC_RX_DATA_LEN 0xE5
+#define REG_CEC_TX_DATA_LEN 0xE6
+
+#define REG_SYS_MIPI_INT 0xEB
+#define B_MIPI_OUTPUT_ENABLE BIT(0)
+#define B_MIPI_VIDEO_UNSTABLE BIT(1)
+
+#define REG_RX_INT_STATUS1 0xEC
+#define B_HDMI_5V_CHG   BIT(0)
+#define B_HDMI_VID_CHG  BIT(1)
+#define B_HDMI_AUD_CHG  BIT(2)
+#define B_HDMI_CP_CHG   BIT(3)
+#define B_HDMI_IF_LATCH BIT(4)
+#define B_HDMI_NO_IF_LATCH  BIT(5)
+#define B_HDMI_EMP      BIT(6)
+#define B_HDMI_NO_EMP   BIT(7)
+
+#define REG_RX_INT_STATUS2 0xED
+#define B_HDMI_AVI      BIT(0)
+#define B_HDMI_NO_AVI   BIT(1)
+#define B_HDMI_VSIF     BIT(2)
+#define B_HDMI_NO_VSIF  BIT(3)
+#define B_HDMI_AVMUTE_CHG  BIT(4)
+
+#define REG_CHIP_CONTROL 0xF0
+#define B_HDMI_RESET  BIT(5)
+#define B_FW_START  BIT(6)
+
+#define REG_MIPI_CFG 0xF1
+#define M_MIPI_LANE  0x03
+#define B_MIPI_SPLIT  BIT(2)
+#define B_MIPI_SPLIT_CFG  BIT(3)
+#define B_MIPI_DPHY  BIT(4)
+#define B_MIPI_USE_DSI  BIT(5)
+#define B_MIPI_CONTINU_CLK  BIT(6)
+
+#define REG_MIPI_DATA_TYPE 0xF2
+#define CSI_RGB444          0x20
+#define CSI_RGB555          0x21
+#define CSI_RGB565          0x22
+#define CSI_RGB666          0x23
+#define CSI_RGB888          0x24
+#define CSI_YUV420_8b_L     0x1A
+#define CSI_YUV420_8b       0x1C
+#define CSI_YUV420_10b      0x1D
+#define CSI_YUV422_8b       0x1E
+#define CSI_YUV422_10b      0x1F
+#define CSI_RGB_10b         0x30
+#define CSI_RGB_12b         0x31
+#define CSI_YUV422_12b      0x32
+#define CSI_YUV420_10b_L    0x33
+#define CSI_YUV420_12b      0x34
+#define CSI_YUV444_8b       0x35
+#define CSI_YUV444_10b      0x36
+#define CSI_YUV444_12b      0x37
+
+#define REG_MIPI_CONTROL 0xF3
+#define B_MIPI_OUTPUT    BIT(0)
+
+#define REG_RX_CFG 0xF4
+#define B_MANUAL_HPD    BIT(0)
+#define B_HPD_HIGH    BIT(1)
+#define B_HPD_TOGGLE    BIT(3)
+
+#define REG_CSC_CFG 0xF5
+#define B_DYNAMIC_RANGE BIT(0)
+
+#define REG_MISC_CFG 0xF6
+#define B_BAUD_RATE BIT(0)
+#define B_DEBUG_MSG BIT(1)
+
+#define REG_HPD_DELAY 0xF7
+#define B_DELAY_COUNT BIT(0)
+#define B_DELAY_UNIT BIT(7)
+
+#define REG_INFO_BANK_SEL 0xFD
+#define CTL_BANK_EDID_READ 1
+#define CTL_BANK_EDID_WRITE 5
+
+#define REG_HOST_CTRL_INT 0xFE
+#define B_CMD_SET BIT(4)
+#define B_CEC_SEND_DATA BIT(5)
+#define B_CONFIG_UPDATE BIT(6)
+#define B_IF_BANK BIT(7)
+
+#define REG_MCU_INTERRUPT 0xFF
+#define B_SYS_INT_ACTIVE BIT(0)
+#define B_CEC_RX_RECEIVED BIT(1)
+#define B_CEC_TX_UPDATE BIT(2)
+
+#define EDID_NUM_BLOCKS_MAX 4
+#define EDID_BLOCK_SIZE 128
+
+#define I2C_MAX_XFER_SIZE  8
+#define POLL_INTERVAL_CEC_MS	10
+#define POLL_INTERVAL_MS	40
+
+#define AUD32K   0x03
+#define AUD44K   0x00
+#define AUD48K   0x02
+#define AUD64K   0x0B
+#define AUD88K   0x08
+#define AUD96K   0x0A
+#define AUD128K  0x2B
+#define AUD176K  0x0C
+#define AUD192K  0x0E
+#define AUD256K  0x1B
+#define AUD352K  0x0D
+#define AUD384K  0x05
+#define AUD512K  0x3B
+#define AUD705K  0x2D
+#define AUD768K  0x09
+#define AUD1024K 0x35
+#define AUD1411K 0x1D
+#define AUD1536K 0x15
+
+enum it6625_chip_type {
+	IT6625_CHIP = 0,
+	IT6626_CHIP = 1,
+};
+
+struct it6625 {
+	struct device *dev;
+	struct i2c_client *i2c_client;
+	struct regmap *it6625_regmap;
+	enum it6625_chip_type chip_type;
+
+	/* protects concurrent access to the chip's registers and state */
+	struct mutex it6625_lock;
+	/* serializes the complete VIDIOC_S_EDID sequence against itself */
+	struct mutex edid_lock;
+	/* serializes a full InfoFrame debugfs read transaction against itself */
+	struct mutex if_read_lock;
+	/*
+	 * protects if_active/if_type/if_snapshot/if_snapshot_err/
+	 * if_snapshot_done and the REG_MCU_INTERRUPT/REG_RX_INT_STATUS1/2/
+	 * REG_IF_LATCH_HB/REG_IF_DATA register group between the interrupt
+	 * path and the InfoFrame debugfs callback. Never held across
+	 * wait_for_completion_timeout(). Nests outside it6625_lock.
+	 */
+	struct mutex if_state_lock;
+
+	struct v4l2_subdev sd;
+	struct v4l2_mbus_config_mipi_csi2 bus;
+	struct video_device *vdev;
+	struct media_pad pad;
+	struct v4l2_ctrl_handler hdl;
+
+	/* controls */
+	struct v4l2_ctrl *ctrl_5v_detect;
+	struct v4l2_ctrl *ctrl_audio_sampling_rate;
+	struct v4l2_ctrl *ctrl_audio_present;
+	struct v4l2_ctrl *ctrl_link_freq;
+
+	struct delayed_work hpd_delayed_work;
+
+	struct timer_list timer;
+	struct work_struct polling_work;
+
+	struct v4l2_dv_timings timings;
+
+	u8 csi_lanes;
+	u8 port_num;
+	enum v4l2_mbus_type bus_type;
+	u8 csi_format;
+	u32 mbus_fmt_code;
+	/* number of EDID blocks currently loaded, protected by edid_lock */
+	u8 edid_blocks;
+
+	struct gpio_desc *reset_gpio;
+
+	struct cec_adapter *cec_adap;
+
+	struct dentry *debugfs_dir;
+
+	struct v4l2_debugfs_if *infoframes;
+	struct completion if_latched;
+	/* true while an InfoFrame debugfs request is outstanding */
+	bool if_active;
+	/* HDMI packet-type byte currently armed in REG_IF_LATCH_HB */
+	u32 if_type;
+	/* driver-private copy of REG_IF_DATA, captured at the genuine latch */
+	u8 if_snapshot[31];
+	/* it6625_read_bytes() result for the if_snapshot capture */
+	int if_snapshot_err;
+	/* set just before complete(), to disambiguate timeout vs. capture */
+	bool if_snapshot_done;
+};
+
+/*
+ * Index 0: D-PHY (4-lane). Index 1: C-PHY (3-trio) -- the confirmed
+ * hardware max C-PHY capability, tested single-port/three-trio.
+ */
+static const s64 it6625_link_freq[] = {
+	445500000,
+	2500000000LL,
+};
+
+/*
+ * Shared cap for every topology except the reference exception below:
+ * IT6625 (no C-PHY support at all), IT6626 running D-PHY, and IT6626
+ * running C-PHY with fewer than three trios. This is conservative
+ * scoping, not a claim that one-/two-trio C-PHY can't also support a
+ * higher rate -- they're simply unvalidated.
+ */
+static const struct v4l2_dv_timings_cap it6625_timings_cap = {
+	.type = V4L2_DV_BT_656_1120,
+	/* keep this initialization for compatibility with GCC < 4.4.6 */
+	.reserved = { 0 },
+
+	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 27000000, 300000000,
+			     V4L2_DV_BT_STD_CEA861 | V4L2_DV_BT_STD_DMT |
+			     V4L2_DV_BT_STD_GTF | V4L2_DV_BT_STD_CVT,
+			     V4L2_DV_BT_CAP_PROGRESSIVE | V4L2_DV_BT_CAP_INTERLACED |
+			     V4L2_DV_BT_CAP_REDUCED_BLANKING | V4L2_DV_BT_CAP_CUSTOM)
+};
+
+/*
+ * IT6626 C-PHY, three trios: raised pixel-clock ceiling (594 MHz vs
+ * the shared 300 MHz cap) for this topology's higher C-PHY capability.
+ */
+static const struct v4l2_dv_timings_cap it6626_cphy_3trio_timings_cap = {
+	.type = V4L2_DV_BT_656_1120,
+	.reserved = { 0 },
+
+	V4L2_INIT_BT_TIMINGS(640, 3840, 480, 2160, 27000000, 594000000,
+			     V4L2_DV_BT_STD_CEA861 | V4L2_DV_BT_STD_DMT |
+			     V4L2_DV_BT_STD_GTF | V4L2_DV_BT_STD_CVT,
+			     V4L2_DV_BT_CAP_PROGRESSIVE | V4L2_DV_BT_CAP_INTERLACED |
+			     V4L2_DV_BT_CAP_REDUCED_BLANKING | V4L2_DV_BT_CAP_CUSTOM)
+};
+
+static const struct v4l2_dv_timings_cap *
+it6625_get_timings_cap(struct it6625 *it6625)
+{
+	if (it6625->chip_type == IT6626_CHIP &&
+	    it6625->bus_type == V4L2_MBUS_CSI2_CPHY &&
+	    it6625->csi_lanes == 3)
+		return &it6626_cphy_3trio_timings_cap;
+
+	return &it6625_timings_cap;
+}
+
+static const struct it6625_format_info {
+	u8 csi_format;
+	u32 mbus_fmt_code;
+} it6625_formats[] = {
+	{ CSI_YUV422_8b, MEDIA_BUS_FMT_UYVY8_1X16 },
+	{ CSI_RGB888, MEDIA_BUS_FMT_RGB888_1X24 },
+	{ CSI_YUV444_8b, MEDIA_BUS_FMT_YUV8_1X24 },
+};
+
+static inline int it6625_csi_format_idx(u8 csi_format)
+{
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(it6625_formats); i++) {
+		if (it6625_formats[i].csi_format == csi_format)
+			return i;
+	}
+
+	return -EINVAL;
+}
+
+static inline int it6625_csi_mbus_code_idx(u32 mbus_fmt_code)
+{
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(it6625_formats); i++) {
+		if (it6625_formats[i].mbus_fmt_code == mbus_fmt_code)
+			return i;
+	}
+
+	return -EINVAL;
+}
+
+static inline struct it6625 *sd_to_6625(struct v4l2_subdev *sd)
+{
+	return container_of(sd, struct it6625, sd);
+}
+
+static const struct regmap_config it6625_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = 0xff,
+	.cache_type = REGCACHE_NONE,
+	.max_raw_read = I2C_MAX_XFER_SIZE,
+	.max_raw_write = I2C_MAX_XFER_SIZE,
+};
+
+static int it6625_regmap_i2c_init(struct i2c_client *client,
+				  struct it6625 *it6625)
+{
+	it6625->i2c_client = client;
+	it6625->dev = &client->dev;
+
+	it6625->it6625_regmap = devm_regmap_init_i2c(it6625->i2c_client,
+						     &it6625_regmap_config);
+	if (IS_ERR(it6625->it6625_regmap))
+		return PTR_ERR(it6625->it6625_regmap);
+
+	return 0;
+}
+
+static int it6625_read_byte(struct it6625 *it6625, u8 reg)
+{
+	unsigned int val;
+	int err;
+	struct device *dev = it6625->dev;
+
+	err = regmap_read(it6625->it6625_regmap, reg, &val);
+	if (err < 0) {
+		dev_err(dev, "reg[0x%x] read failed err: %d", reg, err);
+		return err;
+	}
+
+	return val;
+}
+
+static int it6625_write_byte(struct it6625 *it6625, u8 reg, u8 val)
+{
+	int err;
+	struct device *dev = it6625->dev;
+
+	err = regmap_write(it6625->it6625_regmap, reg, val);
+	if (err < 0) {
+		dev_err(dev, "reg[0x%x] write failed err: %d", reg, err);
+		return err;
+	}
+
+	return 0;
+}
+
+static int it6625_set_bits(struct it6625 *it6625, u8 reg, u8 mask, u8 val)
+{
+	int err;
+	struct device *dev = it6625->dev;
+
+	err = regmap_update_bits(it6625->it6625_regmap, reg, mask, val);
+	if (err < 0) {
+		dev_err(dev, "reg[0x%x] set bits failed err: %d", reg, err);
+		return err;
+	}
+
+	return 0;
+}
+
+static int it6625_read_bytes(struct it6625 *it6625, u8 reg, u8 *buf, int len)
+{
+	int err;
+	struct device *dev = it6625->dev;
+
+	err = regmap_bulk_read(it6625->it6625_regmap, reg, buf, len);
+	if (err < 0) {
+		dev_err(dev, "reg[0x%x] read failed err: %d", reg, err);
+		return err;
+	}
+
+	return 0;
+}
+
+static int it6625_write_bytes(struct it6625 *it6625, u8 reg, u8 *buf, int len)
+{
+	int err;
+	struct device *dev = it6625->dev;
+
+	err = regmap_bulk_write(it6625->it6625_regmap, reg, buf, len);
+	if (err < 0) {
+		dev_err(dev, "reg[0x%x] write failed err: %d", reg, err);
+		return err;
+	}
+
+	return 0;
+}
+
+static int it6625_wait_for_status(struct it6625 *it6625, u8 reg, u8 val,
+				  int timeout_ms)
+{
+	struct device *dev = it6625->dev;
+	int status;
+	int rval;
+	int sleep_ms = 10;
+	int timeout_round_ms = DIV_ROUND_UP(timeout_ms, sleep_ms) * sleep_ms;
+
+	status = read_poll_timeout(it6625_read_byte, rval, rval == val,
+				   sleep_ms * 1000,
+				   timeout_round_ms * 1000,
+				   false, it6625, reg);
+
+	dev_info(dev, "%s status = %d %d", __func__, status, (int)rval);
+	if (status < 0) {
+		dev_err(dev, "%s err status = %d", __func__, status);
+		return -ETIMEDOUT;
+	}
+
+	return 0;
+}
+
+static void it6625_write_command(struct it6625 *it6625, u8 *cmds, int cmd_len)
+{
+	it6625_write_bytes(it6625, REG_CMD_SET, cmds, cmd_len);
+	it6625_write_byte(it6625, REG_HOST_CTRL_INT, B_CMD_SET);
+	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+}
+
+static int it6625_update_config(struct it6625 *it6625)
+{
+	int err;
+
+	err = it6625_set_bits(it6625, REG_HOST_CTRL_INT,
+			      B_CONFIG_UPDATE, B_CONFIG_UPDATE);
+	if (err < 0)
+		return err;
+
+	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+}
+
+static int it6625_set_bank(struct it6625 *it6625, u8 bank)
+{
+	int err;
+
+	err = it6625_write_byte(it6625, REG_INFO_BANK_SEL, bank);
+	if (err < 0)
+		return err;
+
+	err = it6625_write_byte(it6625, REG_HOST_CTRL_INT, B_IF_BANK);
+	if (err < 0)
+		return err;
+
+	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+}
+
+static inline bool is_hdmi(struct it6625 *it6625)
+{
+	int val;
+
+	val = it6625_read_byte(it6625, REG_RX_STATUS);
+	return (val < 0) ? false : (val & B_RX_HDMI);
+}
+
+static inline bool hdmi_5v_power_present(struct it6625 *it6625)
+{
+	int val;
+
+	val = it6625_read_byte(it6625, REG_RX_STATUS);
+	return (val < 0) ? false : (val & B_RX_5V);
+}
+
+static inline bool no_signal(struct it6625 *it6625)
+{
+	int val;
+
+	val = it6625_read_byte(it6625, REG_RX_STATUS);
+	return (val < 0) ? true : !(val & B_RX_STABLE);
+}
+
+static inline bool audio_present(struct it6625 *it6625)
+{
+	int val;
+
+	val = it6625_read_byte(it6625, REG_RX_STATUS);
+	return (val < 0) ? false : (val & B_RX_AUD_ON);
+}
+
+static int get_audio_sampling_rate(struct it6625 *it6625)
+{
+	int fs_id;
+	int i, freq = 0;
+	const struct fs_id_map {
+		u8 fs_id;
+		u32 freq;
+	} s_fsid_map[] = {
+		{ AUD32K,    32000 },
+		{ AUD44K,    44100 },
+		{ AUD48K,    48000 },
+		{ AUD64K,    64000 },
+		{ AUD88K,    88200 },
+		{ AUD96K,    96000 },
+
+		{ AUD128K,  128000 },
+		{ AUD176K,  176400 },
+		{ AUD192K,  192000 },
+		{ AUD256K,  256000 },
+		{ AUD352K,  352800 },
+		{ AUD384K,  384000 },
+
+		{ AUD512K,  512000 },
+		{ AUD705K,  705600 },
+		{ AUD768K,  768000 },
+		{ AUD1024K, 1024000 },
+		{ AUD1411K, 1411200 },
+		{ AUD1536K, 1536000 },
+	};
+
+	if (no_signal(it6625) || !audio_present(it6625))
+		return 0;
+
+	guard(mutex)(&it6625->it6625_lock);
+
+	fs_id = it6625_read_byte(it6625, REG_HDMI_AUDIO_INFO1);
+	if (fs_id < 0)
+		return 0;
+
+	for (i = 0; i < ARRAY_SIZE(s_fsid_map); i++) {
+		if (s_fsid_map[i].fs_id == fs_id) {
+			freq = s_fsid_map[i].freq;
+			break;
+		}
+	}
+
+	return freq;
+}
+
+static u64 it6625_get_pclk(struct it6625 *it6625)
+{
+	u32 pclk;
+	u8 ck[4];
+	int ret;
+
+	ret = it6625_read_bytes(it6625, REG_VID_PCLK, ck, 4);
+	if (ret < 0) {
+		dev_err(it6625->dev, "failed to read pixel clock");
+		return 0;
+	}
+
+	pclk = ck[0];
+	pclk <<= 8;
+	pclk |= ck[1];
+	pclk <<= 8;
+	pclk |= ck[2];
+	pclk <<= 8;
+	pclk |= ck[3];
+
+	v4l2_dbg(1, debug, &it6625->sd, "%s: pclk=%u (%08x)",
+		 __func__, pclk, pclk);
+
+	return (u64)pclk * 1000;
+}
+
+static int it6625_read_edid(struct it6625 *it6625, u8 *edid, int start_block,
+			    int num_blocks)
+{
+	int i, bank_ctrl, err = 0;
+	struct device *dev = it6625->dev;
+
+	if (!edid) {
+		dev_err(dev, "edid buffer is NULL");
+		return -EINVAL;
+	}
+
+	if (start_block < 0 || num_blocks <= 0 ||
+	    start_block > EDID_NUM_BLOCKS_MAX ||
+	    num_blocks > EDID_NUM_BLOCKS_MAX ||
+	    start_block + num_blocks > EDID_NUM_BLOCKS_MAX) {
+		dev_err(dev,
+			"invalid block range: start_block=%d, num_blocks=%d",
+			start_block, num_blocks);
+		return -EINVAL;
+	}
+
+	guard(mutex)(&it6625->it6625_lock);
+	for (i = 0; i < num_blocks; i++) {
+		bank_ctrl = CTL_BANK_EDID_READ + start_block + i;
+		err = it6625_set_bank(it6625, bank_ctrl);
+		if (err < 0)
+			break;
+
+		err = it6625_read_bytes(it6625, REG_EDID_START,
+					edid + (i * 128), 128);
+		if (err < 0)
+			break;
+	}
+
+	it6625_set_bank(it6625, 0);
+
+	return err < 0 ? err : num_blocks;
+}
+
+static int it6625_write_edid(struct it6625 *it6625, u8 *edid, int start_block,
+			     int num_blocks)
+{
+	int i, bank_ctrl, err = 0;
+	struct device *dev = it6625->dev;
+
+	if (start_block < 0 || num_blocks <= 0 ||
+	    start_block > EDID_NUM_BLOCKS_MAX ||
+	    num_blocks > EDID_NUM_BLOCKS_MAX ||
+	    start_block + num_blocks > EDID_NUM_BLOCKS_MAX) {
+		dev_err(dev,
+			"invalid block range: start_block=%d, num_blocks=%d",
+			start_block, num_blocks);
+		return -EINVAL;
+	}
+
+	guard(mutex)(&it6625->it6625_lock);
+	for (i = 0; i < num_blocks; i++) {
+		bank_ctrl = CTL_BANK_EDID_WRITE + start_block + i;
+		err = it6625_set_bank(it6625, bank_ctrl);
+		if (err < 0)
+			break;
+
+		err = it6625_write_bytes(it6625, REG_EDID_START,
+					 edid + (i * 128), 128);
+		if (err < 0)
+			break;
+
+		err = it6625_update_config(it6625);
+		if (err < 0)
+			break;
+	}
+
+	it6625_set_bank(it6625, 0);
+
+	return err < 0 ? err : num_blocks;
+}
+
+static void it6625_enable_auto_hpd(struct it6625 *it6625)
+{
+	dev_dbg(it6625->dev, "%s: auto HPD", __func__);
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_set_bits(it6625, REG_RX_CFG, 0x03, 0x00);
+	it6625_update_config(it6625);
+}
+
+static void it6625_disable_hpd(struct it6625 *it6625)
+{
+	cancel_delayed_work_sync(&it6625->hpd_delayed_work);
+
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_set_bits(it6625, REG_RX_CFG, 0x03, 0x01);
+	it6625_update_config(it6625);
+}
+
+static void it6625_enable_hpd(struct it6625 *it6625)
+{
+	schedule_delayed_work(&it6625->hpd_delayed_work, HZ / 7);
+}
+
+static void it6625_hpd_delayed_work(struct work_struct *work)
+{
+	struct it6625 *it6625 = container_of(work,
+			struct it6625, hpd_delayed_work.work);
+	int val = 0;
+
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_set_bits(it6625, REG_RX_CFG, 0x03, val);
+	it6625_update_config(it6625);
+}
+
+static int it6625_get_detected_timings(struct it6625 *it6625,
+				       struct v4l2_dv_timings *timings)
+{
+	struct v4l2_bt_timings *bt = &timings->bt;
+	int val;
+	unsigned int width, height;
+	u8 buffer[4];
+	u8 buffer2[12];
+
+	if (no_signal(it6625)) {
+		dev_err(it6625->dev, "no signal detected");
+		return -ENOLINK;
+	}
+
+	guard(mutex)(&it6625->it6625_lock);
+
+	memset(timings, 0, sizeof(struct v4l2_dv_timings));
+	timings->type = V4L2_DV_BT_656_1120;
+	val = it6625_read_byte(it6625, REG_VID_INFO);
+	if (val < 0) {
+		dev_err(it6625->dev, "failed to read video info");
+		return -EIO;
+	}
+
+	bt->interlaced = val & B_INTERLACE ?
+			 V4L2_DV_INTERLACED : V4L2_DV_PROGRESSIVE;
+
+	if (it6625_read_bytes(it6625, REG_H_ACTIVE_1, buffer, 4) < 0)
+		return -EIO;
+
+	width = ((buffer[0] & 0xff) << 8) + buffer[1];
+	height = ((buffer[2] & 0xff) << 8) + buffer[3];
+
+	bt->width = width;
+	bt->height = height;
+
+	if (it6625_read_bytes(it6625, REG_H_FP_1, buffer2, 12) < 0)
+		return -EIO;
+
+	bt->hfrontporch = ((buffer2[0] & 0xff) << 8) + buffer2[1];
+	bt->hsync = ((buffer2[2] & 0xff) << 8) + buffer2[3];
+	bt->hbackporch = ((buffer2[4] & 0xff) << 8) + buffer2[5];
+	bt->vfrontporch = ((buffer2[6] & 0xff) << 8) + buffer2[7];
+	bt->vsync = ((buffer2[8] & 0xff) << 8) + buffer2[9];
+	bt->vbackporch = ((buffer2[10] & 0xff) << 8) + buffer2[11];
+
+	bt->pixelclock = it6625_get_pclk(it6625);
+	if (bt->interlaced == V4L2_DV_INTERLACED) {
+		bt->height *= 2;
+		bt->il_vsync = bt->vsync + 1;
+	}
+
+	return 0;
+}
+
+static void it6625_show_avi_infoframe(struct it6625 *it6625)
+{
+	struct device *dev = it6625->dev;
+	union hdmi_infoframe frame;
+	u8 buffer[HDMI_INFOFRAME_SIZE(AVI)];
+	u8 ver, len;
+	int ret;
+
+	if (!is_hdmi(it6625)) {
+		dev_err(dev, "not HDMI signal, skip AVI infoframe log");
+		return;
+	}
+
+	ret = it6625_read_bytes(it6625, REG_AVI_DATA, buffer + 1,
+				HDMI_INFOFRAME_SIZE(AVI) - 1);
+	if (ret < 0) {
+		dev_err(dev, "failed to read AVI infoframe data");
+		return;
+	}
+
+	len = buffer[1];
+	ver = buffer[2];
+
+	buffer[0] = HDMI_INFOFRAME_TYPE_AVI;
+	buffer[1] = ver;
+	buffer[2] = len;
+
+	ret = hdmi_infoframe_unpack(&frame, buffer, sizeof(buffer));
+	if (ret < 0) {
+		dev_err(dev, "unpack of AVI infoframe failed");
+		return;
+	}
+
+	hdmi_infoframe_log(KERN_INFO, dev, &frame);
+}
+
+static int it6625_s_ctrl_detect_hdmi_5v(struct v4l2_subdev *sd)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	return v4l2_ctrl_s_ctrl(it6625->ctrl_5v_detect,
+				hdmi_5v_power_present(it6625));
+}
+
+static int it6625_s_ctrl_audio_sampling_rate(struct v4l2_subdev *sd)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	return v4l2_ctrl_s_ctrl(it6625->ctrl_audio_sampling_rate,
+				get_audio_sampling_rate(it6625));
+}
+
+static int it6625_s_ctrl_audio_present(struct v4l2_subdev *sd)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	return v4l2_ctrl_s_ctrl(it6625->ctrl_audio_present,
+				audio_present(it6625));
+}
+
+static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
+{
+	int ret = 0;
+
+	ret |= it6625_s_ctrl_detect_hdmi_5v(sd);
+	ret |= it6625_s_ctrl_audio_sampling_rate(sd);
+	ret |= it6625_s_ctrl_audio_present(sd);
+
+	return 0;
+}
+
+static void it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+	int val;
+
+	lockdep_assert_held(&it6625->it6625_lock);
+
+	v4l2_dbg(3, debug, sd, "%s: %sable",
+		 __func__, enable ? "en" : "dis");
+
+	val = enable ? B_MIPI_OUTPUT : 0;
+	it6625_set_bits(it6625, REG_MIPI_CONTROL, B_MIPI_OUTPUT, val);
+	it6625_update_config(it6625);
+}
+
+static void it6625_enable_stream(struct it6625 *it6625, bool enable)
+{
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_enable_stream_locked(it6625, enable);
+}
+
+static void it6625_set_mipi_config_locked(struct it6625 *it6625, u32 cfg_val)
+{
+	u8 mipi_data_type;
+
+	lockdep_assert_held(&it6625->it6625_lock);
+
+	dev_dbg(it6625->dev, "mipi_data_type = 0x%x", cfg_val);
+
+	mipi_data_type = cfg_val & 0xFF;
+	it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, mipi_data_type);
+	it6625_update_config(it6625);
+}
+
+static inline unsigned int fps_from_bt_timings(const struct v4l2_bt_timings *t)
+{
+	if (!V4L2_DV_BT_FRAME_HEIGHT(t) || !V4L2_DV_BT_FRAME_WIDTH(t))
+		return 0;
+
+	return DIV_ROUND_CLOSEST((unsigned int)t->pixelclock,
+				 V4L2_DV_BT_FRAME_HEIGHT(t) *
+				 V4L2_DV_BT_FRAME_WIDTH(t));
+}
+
+static void it6625_initial_setup(struct it6625 *it6625)
+{
+	int val = 0;
+
+	guard(mutex)(&it6625->it6625_lock);
+
+	/*
+	 * REG_MIPI_CFG[0:2] lane count field: 1 lane -> 0, 2 lanes -> 1,
+	 * 3 lanes (C-PHY only) -> 3, 4 lanes (D-PHY only) -> 3.
+	 */
+	switch (it6625->csi_lanes) {
+	case 1:
+		val = FIELD_PREP(M_MIPI_LANE, 0);
+		break;
+	case 2:
+		val = FIELD_PREP(M_MIPI_LANE, 1);
+		break;
+	default:
+		val = FIELD_PREP(M_MIPI_LANE, 3);
+		break;
+	}
+
+	if (it6625->bus_type == V4L2_MBUS_CSI2_DPHY)
+		val |= FIELD_PREP(B_MIPI_DPHY, 1);
+
+	if (it6625->port_num == 2)
+		val |= FIELD_PREP(B_MIPI_SPLIT, 1);
+
+	it6625_write_byte(it6625, REG_MIPI_CFG, val);
+	it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, it6625->csi_format);
+	it6625_write_byte(it6625, REG_MIPI_CONTROL, 0x00);
+	it6625_write_byte(it6625, REG_RX_CFG, 0x00);
+
+	it6625_set_bits(it6625, REG_HOST_CTRL_INT, B_CONFIG_UPDATE, B_CONFIG_UPDATE);
+	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+}
+
+static int it6625_cec_adap_enable(struct cec_adapter *adap, bool enable)
+{
+	struct it6625 *it6625 = adap->priv;
+	u8 cmds[2];
+
+	cmds[0] = CMD_SET_CEC_ENABLE;
+	cmds[1] = enable ? 1 : 0;
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_write_command(it6625, cmds, sizeof(cmds));
+
+	return 0;
+}
+
+static void it6625_cec_reset_la(struct it6625 *it6625, bool keep_enabled)
+{
+	u8 cmds[2];
+
+	if (keep_enabled) {
+		cmds[0] = CMD_SET_CEC_LA;
+		cmds[1] = CEC_LOG_ADDR_UNREGISTERED;
+	} else {
+		cmds[0] = CMD_SET_CEC_ENABLE;
+		cmds[1] = 0;
+	}
+
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_write_command(it6625, cmds, sizeof(cmds));
+}
+
+static int it6625_cec_adap_log_addr(struct cec_adapter *adap, u8 log_addr)
+{
+	struct it6625 *it6625 = adap->priv;
+	u8 cmds[2] = {CMD_SET_CEC_LA, log_addr};
+
+	dev_dbg(it6625->dev, "%s: la=%d", __func__, log_addr);
+
+	if (log_addr == CEC_LOG_ADDR_INVALID) {
+		it6625_cec_reset_la(it6625, adap->is_enabled);
+		return 0;
+	}
+
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_write_command(it6625, cmds, sizeof(cmds));
+
+	return 0;
+}
+
+static int it6625_cec_adap_transmit(struct cec_adapter *adap, u8 attempts,
+				    u32 signal_free_time, struct cec_msg *msg)
+{
+	struct it6625 *it6625 = adap->priv;
+
+	guard(mutex)(&it6625->it6625_lock);
+	it6625_write_bytes(it6625, REG_CEC_TX_DATA, msg->msg, msg->len);
+	it6625_write_byte(it6625, REG_CEC_TX_DATA_LEN, msg->len);
+	it6625_set_bits(it6625, REG_HOST_CTRL_INT, B_CEC_SEND_DATA, B_CEC_SEND_DATA);
+	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+
+	return 0;
+}
+
+static const struct cec_adap_ops it6625_cec_adap_ops = {
+	.adap_enable = it6625_cec_adap_enable,
+	.adap_log_addr = it6625_cec_adap_log_addr,
+	.adap_transmit = it6625_cec_adap_transmit,
+};
+
+static void it6625_cec_handler(struct it6625 *it6625, u8 intstatus)
+{
+	struct cec_msg rxmsg = {};
+	int val = 0;
+
+	if (intstatus & B_CEC_RX_RECEIVED) {
+		scoped_guard(mutex, &it6625->it6625_lock) {
+			val = it6625_read_byte(it6625, REG_CEC_RX_DATA_LEN);
+			if (val > 0 && val <= CEC_MAX_MSG_SIZE)
+				it6625_read_bytes(it6625, REG_CEC_RX_DATA, &rxmsg.msg[0], val);
+			it6625_write_byte(it6625, REG_CEC_RX_DATA_LEN, 0);
+		}
+
+		if (val > 0 && val <= CEC_MAX_MSG_SIZE) {
+			rxmsg.len = val;
+			cec_received_msg(it6625->cec_adap, &rxmsg);
+		} else {
+			dev_err(it6625->dev, "invalid CEC RX length %d", val);
+		}
+	}
+
+	if (intstatus & B_CEC_TX_UPDATE) {
+		val = it6625_read_byte(it6625, REG_CEC_STATUS);
+		if (val < 0) {
+			dev_err(it6625->dev, "read CEC status failed");
+			return;
+		}
+
+		if (val & BIT(0)) {
+			cec_transmit_attempt_done(it6625->cec_adap,
+						  CEC_TX_STATUS_OK);
+		} else if (val & BIT(1)) {
+			cec_transmit_attempt_done(it6625->cec_adap,
+						  CEC_TX_STATUS_NACK);
+		} else {
+			dev_info(it6625->dev, "unknown CEC status %02X", val);
+			cec_transmit_attempt_done(it6625->cec_adap,
+						  CEC_TX_STATUS_NACK);
+		}
+	}
+}
+
+static void it6625_irq_format_change(struct it6625 *it6625)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+	struct v4l2_dv_timings timings;
+	const struct v4l2_event it6625_ev_fmt = {
+		.type = V4L2_EVENT_SOURCE_CHANGE,
+		.u.src_change.changes = V4L2_EVENT_SRC_CH_RESOLUTION,
+	};
+	int ret;
+
+	if (no_signal(it6625)) {
+		if (sd->devnode)
+			v4l2_subdev_notify_event(sd, &it6625_ev_fmt);
+		return;
+	}
+
+	ret = it6625_get_detected_timings(it6625, &timings);
+	if (ret < 0) {
+		v4l2_dbg(1, debug, sd, "Failed to get detected timings");
+		return;
+	}
+
+	if (sd->devnode)
+		v4l2_subdev_notify_event(sd, &it6625_ev_fmt);
+}
+
+static void it6625_irq_hdmi_audio_change(struct it6625 *it6625)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+
+	it6625_s_ctrl_audio_sampling_rate(sd);
+	it6625_s_ctrl_audio_present(sd);
+}
+
+static void it6625_get_timings(struct it6625 *it6625,
+			       struct v4l2_dv_timings *timings)
+{
+	guard(mutex)(&it6625->it6625_lock);
+	*timings = it6625->timings;
+}
+
+static void it6625_clear_timings(struct it6625 *it6625)
+{
+	guard(mutex)(&it6625->it6625_lock);
+	memset(&it6625->timings, 0, sizeof(it6625->timings));
+}
+
+static void it6625_irq_hdmi_5v_change(struct it6625 *it6625)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+
+	it6625_clear_timings(it6625);
+	it6625_v4l2_sd_ctrl_update(sd);
+}
+
+static void it6625_irq_hdcp_change(struct it6625 *it6625)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+	u8 cp_sts;
+
+	cp_sts = it6625_read_byte(it6625, REG_RX_HDCP_STS);
+	v4l2_info(sd, "HDCP change to %02X", cp_sts);
+}
+
+static void it6625_irq_infoframe_latch(struct it6625 *it6625)
+{
+	if (!it6625->if_active)
+		return;
+
+	it6625->if_active = false;
+
+	scoped_guard(mutex, &it6625->it6625_lock) {
+		it6625->if_snapshot_err =
+			it6625_read_bytes(it6625, REG_IF_DATA,
+					  it6625->if_snapshot, 31);
+	}
+	it6625->if_snapshot_done = true;
+	complete(&it6625->if_latched);
+}
+
+static void it6625_irq_emata_packet_latch(struct it6625 *it6625)
+{
+	u8 extend_packet[14];
+
+	it6625_read_bytes(it6625, REG_EMP_DATA, extend_packet, 13);
+}
+
+static void it6625_irq_avmute_change(struct it6625 *it6625)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+	int val;
+	u8 avmute;
+
+	val = it6625_read_byte(it6625, REG_RX_STATUS);
+	if (val < 0)
+		return;
+
+	avmute = (val & B_RX_AVMUTE) ? 1 : 0;
+	v4l2_info(sd, "AVMute change to %d", avmute);
+}
+
+static void it6625_dispatch_int_status1(struct it6625 *it6625, int int_sts1)
+{
+	if (int_sts1 & B_HDMI_5V_CHG)
+		it6625_irq_hdmi_5v_change(it6625);
+
+	if (int_sts1 & B_HDMI_VID_CHG)
+		it6625_irq_format_change(it6625);
+
+	if (int_sts1 & B_HDMI_AUD_CHG)
+		it6625_irq_hdmi_audio_change(it6625);
+
+	if (int_sts1 & B_HDMI_CP_CHG)
+		it6625_irq_hdcp_change(it6625);
+
+	if (int_sts1 & B_HDMI_IF_LATCH)
+		it6625_irq_infoframe_latch(it6625);
+
+	if (int_sts1 & B_HDMI_EMP)
+		it6625_irq_emata_packet_latch(it6625);
+}
+
+static void it6625_dispatch_int_status2(struct it6625 *it6625, int int_sts2)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+
+	if (int_sts2 & B_HDMI_AVI)
+		it6625_show_avi_infoframe(it6625);
+
+	if (int_sts2 & B_HDMI_NO_AVI)
+		v4l2_info(sd, "AVI-info stopped");
+
+	if (int_sts2 & B_HDMI_AVMUTE_CHG)
+		it6625_irq_avmute_change(it6625);
+}
+
+/* caller must already hold if_state_lock */
+static int it6625_drain_rx_int_status(struct it6625 *it6625)
+{
+	int val1, val2, err;
+
+	val1 = it6625_read_byte(it6625, REG_RX_INT_STATUS1);
+	val2 = it6625_read_byte(it6625, REG_RX_INT_STATUS2);
+
+	err = 0;
+	if (val1 < 0)
+		err = val1;
+	else if (val2 < 0)
+		err = val2;
+
+	if (val1 >= 0) {
+		int werr = it6625_write_byte(it6625, REG_RX_INT_STATUS1, 0x00);
+
+		if (werr && !err)
+			err = werr;
+		it6625_dispatch_int_status1(it6625, val1);
+	}
+
+	if (val2 >= 0) {
+		int werr = it6625_write_byte(it6625, REG_RX_INT_STATUS2, 0x00);
+
+		if (werr && !err)
+			err = werr;
+		it6625_dispatch_int_status2(it6625, val2);
+	}
+
+	return err;
+}
+
+/* caller must already hold if_state_lock */
+static int it6625_drain_interrupts(struct it6625 *it6625, bool *had_event)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+	int val, err;
+
+	val = it6625_read_byte(it6625, REG_MCU_INTERRUPT);
+	if (val < 0) {
+		if (had_event)
+			*had_event = false;
+		return val;
+	}
+	if (had_event)
+		*had_event = val > 0;
+	if (val == 0)
+		return 0;
+
+	err = it6625_write_byte(it6625, REG_MCU_INTERRUPT, val);
+
+	v4l2_dbg(1, debug, sd, "%s: INT = 0x%02X", __func__, val);
+
+	if (val & (B_CEC_RX_RECEIVED | B_CEC_TX_UPDATE) && it6625->cec_adap)
+		it6625_cec_handler(it6625, val & (B_CEC_RX_RECEIVED | B_CEC_TX_UPDATE));
+
+	if (val & B_SYS_INT_ACTIVE) {
+		int child_err = it6625_drain_rx_int_status(it6625);
+
+		if (child_err && !err)
+			err = child_err;
+	}
+
+	return err;
+}
+
+static bool it6625_interrupt_handler(struct it6625 *it6625)
+{
+	bool had_event = false;
+
+	guard(mutex)(&it6625->if_state_lock);
+	it6625_drain_interrupts(it6625, &had_event);
+	return had_event;
+}
+
+static irqreturn_t it6625_irq_handler(int unused, void *data)
+{
+	struct it6625 *it6625 = data;
+
+	return it6625_interrupt_handler(it6625) ? IRQ_HANDLED : IRQ_NONE;
+}
+
+static void it6625_irq_poll_timer(struct timer_list *t)
+{
+	struct it6625 *it6625 = timer_container_of(it6625, t, timer);
+	unsigned int msecs;
+
+	schedule_work(&it6625->polling_work);
+	/*
+	 * If CEC is present, then we need to poll more frequently,
+	 * otherwise we will miss CEC messages.
+	 */
+	msecs = it6625->cec_adap ? POLL_INTERVAL_CEC_MS : POLL_INTERVAL_MS;
+	mod_timer(&it6625->timer, jiffies + msecs_to_jiffies(msecs));
+}
+
+static void it6625_polling_work(struct work_struct *work)
+{
+	struct it6625 *it6625 = container_of(work, struct it6625,
+					polling_work);
+
+	it6625_interrupt_handler(it6625);
+}
+
+static const char *it6625_csi_format_name(u8 csi_format)
+{
+	switch (csi_format) {
+	case CSI_YUV422_8b:
+		return "YUV422 8bit";
+	case CSI_RGB888:
+		return "RGB888 8bit";
+	case CSI_YUV444_8b:
+		return "YUV444 8bit";
+	default:
+		return "unknown";
+	}
+}
+
+static int it6625_log_status(struct v4l2_subdev *sd)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	struct v4l2_dv_timings timings, configured_timings;
+	struct v4l2_bt_timings bt;
+	u8 csi_format;
+
+	if (it6625_get_detected_timings(it6625, &timings))
+		v4l2_info(sd, "No video detected");
+	else
+		v4l2_print_dv_timings(sd->name, "Detected format: ", &timings,
+				      true);
+
+	it6625_get_timings(it6625, &configured_timings);
+	v4l2_print_dv_timings(sd->name, "Configured format: ",
+			      &configured_timings, true);
+
+	/* snapshot together so the reported pair was actually configured together */
+	scoped_guard(mutex, &it6625->it6625_lock) {
+		csi_format = it6625->csi_format;
+		bt = it6625->timings.bt;
+	}
+
+	v4l2_info(sd, "CSI format: %s @ %uHz",
+		  it6625_csi_format_name(csi_format),
+		  fps_from_bt_timings(&bt));
+
+	it6625_show_avi_infoframe(it6625);
+
+	return 0;
+}
+
+static int it6625_isr(struct v4l2_subdev *sd, u32 status, bool *handled)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	schedule_work(&it6625->polling_work);
+	*handled = true;
+
+	return 0;
+}
+
+static int it6625_subscribe_event(struct v4l2_subdev *sd, struct v4l2_fh *fh,
+				  struct v4l2_event_subscription *sub)
+{
+	switch (sub->type) {
+	case V4L2_EVENT_SOURCE_CHANGE:
+		return v4l2_src_change_event_subdev_subscribe(sd, fh, sub);
+	case V4L2_EVENT_CTRL:
+		return v4l2_ctrl_subdev_subscribe_event(sd, fh, sub);
+	default:
+		return -EINVAL;
+	}
+}
+
+static int it6625_g_input_status(struct v4l2_subdev *sd, u32 *status)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	bool val;
+
+	val = no_signal(it6625);
+	*status = 0;
+	*status |= val ? V4L2_IN_ST_NO_SIGNAL : 0;
+	*status |= val ? V4L2_IN_ST_NO_SYNC : 0;
+
+	v4l2_dbg(1, debug, sd, "%s: status = 0x%x", __func__, *status);
+
+	return 0;
+}
+
+static int
+it6625_update_timings_if_changed(struct it6625 *it6625,
+				 const struct v4l2_dv_timings *timings)
+{
+	int ret;
+
+	guard(mutex)(&it6625->it6625_lock);
+	if (v4l2_match_dv_timings(&it6625->timings, timings, 0, false)) {
+		ret = 0;
+	} else if (!v4l2_valid_dv_timings(timings, it6625_get_timings_cap(it6625),
+					  NULL, NULL)) {
+		ret = -ERANGE;
+	} else {
+		it6625->timings = *timings;
+		ret = 1;
+	}
+
+	return ret;
+}
+
+static int it6625_enum_dv_timings(struct v4l2_subdev *sd,
+				  struct v4l2_enum_dv_timings *timings)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	if (timings->pad != 0)
+		return -EINVAL;
+
+	return v4l2_enum_dv_timings_cap(timings,
+					it6625_get_timings_cap(it6625), NULL, NULL);
+}
+
+static int it6625_dv_timings_cap(struct v4l2_subdev *sd,
+				 struct v4l2_dv_timings_cap *cap)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	if (cap->pad != 0)
+		return -EINVAL;
+
+	*cap = *it6625_get_timings_cap(it6625);
+
+	return 0;
+}
+
+static int it6625_s_stream(struct v4l2_subdev *sd, int enable)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	it6625_enable_stream(it6625, enable);
+	return 0;
+}
+
+static int it6625_enum_mbus_code(struct v4l2_subdev *sd,
+				 struct v4l2_subdev_state *sd_state,
+				 struct v4l2_subdev_mbus_code_enum *code)
+{
+	dev_dbg(sd->dev, "%s: index=%d", __func__, code->index);
+
+	if (code->index >= ARRAY_SIZE(it6625_formats))
+		return -EINVAL;
+
+	dev_dbg(sd->dev, "%s: code=0x%08x", __func__,
+		it6625_formats[code->index].mbus_fmt_code);
+	code->code = it6625_formats[code->index].mbus_fmt_code;
+
+	return 0;
+}
+
+static int it6625_get_mbus_config(struct v4l2_subdev *sd,
+				  unsigned int pad,
+				  struct v4l2_mbus_config *cfg)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	if (pad != 0)
+		return -EINVAL;
+
+	cfg->type = it6625->bus_type;
+	cfg->bus.mipi_csi2.flags = 0;
+	cfg->bus.mipi_csi2.num_data_lanes = it6625->csi_lanes;
+
+	return 0;
+}
+
+static int it6625_pad_s_dv_timings(struct v4l2_subdev *sd, unsigned int pad,
+				   struct v4l2_dv_timings *timings)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	int ret;
+
+	if (pad != 0)
+		return -EINVAL;
+
+	if (!timings)
+		return -EINVAL;
+
+	if (debug)
+		v4l2_print_dv_timings(sd->name, __func__, timings, false);
+
+	ret = it6625_update_timings_if_changed(it6625, timings);
+	if (ret == -ERANGE) {
+		v4l2_dbg(1, debug, sd, "%s: timings out of range", __func__);
+		return ret;
+	}
+
+	if (ret == 0)
+		v4l2_dbg(1, debug, sd, "%s: no change", __func__);
+
+	return 0;
+}
+
+static int it6625_pad_g_dv_timings(struct v4l2_subdev *sd, unsigned int pad,
+				   struct v4l2_dv_timings *timings)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	if (pad != 0)
+		return -EINVAL;
+
+	it6625_get_timings(it6625, timings);
+
+	return 0;
+}
+
+static int it6625_pad_query_dv_timings(struct v4l2_subdev *sd,
+				       unsigned int pad,
+				       struct v4l2_dv_timings *timings)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	int ret;
+
+	if (pad != 0)
+		return -EINVAL;
+
+	ret = it6625_get_detected_timings(it6625, timings);
+	if (ret)
+		return ret;
+
+	if (debug)
+		v4l2_print_dv_timings(sd->name, __func__, timings, false);
+
+	if (!v4l2_valid_dv_timings(timings, it6625_get_timings_cap(it6625), NULL, NULL)) {
+		v4l2_dbg(1, debug, sd, "%s: timings out of range", __func__);
+		return -ERANGE;
+	}
+
+	return 0;
+}
+
+static inline u32 format_to_colorspace(u8 csi_format)
+{
+	switch (csi_format) {
+	case CSI_RGB444:
+	case CSI_RGB555:
+	case CSI_RGB565:
+	case CSI_RGB666:
+	case CSI_RGB888:
+	case CSI_RGB_10b:
+	case CSI_RGB_12b:
+		return V4L2_COLORSPACE_SRGB;
+	case CSI_YUV420_8b_L:
+	case CSI_YUV420_8b:
+	case CSI_YUV420_10b:
+	case CSI_YUV422_8b:
+	case CSI_YUV422_10b:
+	case CSI_YUV422_12b:
+	case CSI_YUV420_10b_L:
+	case CSI_YUV420_12b:
+	case CSI_YUV444_8b:
+	case CSI_YUV444_10b:
+	case CSI_YUV444_12b:
+		return V4L2_COLORSPACE_REC709;
+	default:
+		return 0;
+	}
+}
+
+static int it6625_get_fmt(struct v4l2_subdev *sd,
+			  struct v4l2_subdev_state *sd_state,
+			  struct v4l2_subdev_format *format)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	struct v4l2_dv_timings timings;
+
+	if (format->pad != 0)
+		return -EINVAL;
+
+	it6625_get_timings(it6625, &timings);
+	format->format.width = timings.bt.width;
+	format->format.height = timings.bt.height;
+	format->format.field = timings.bt.interlaced == V4L2_DV_INTERLACED ?
+			       V4L2_FIELD_INTERLACED : V4L2_FIELD_NONE;
+
+	if (format->which == V4L2_SUBDEV_FORMAT_TRY) {
+		struct v4l2_mbus_framefmt *fmt;
+
+		fmt = v4l2_subdev_state_get_format(sd_state, format->pad);
+		format->format.code = fmt->code;
+		format->format.colorspace = fmt->colorspace;
+	} else {
+		scoped_guard(mutex, &it6625->it6625_lock) {
+			format->format.colorspace =
+				format_to_colorspace(it6625->csi_format);
+			format->format.code = it6625->mbus_fmt_code;
+		}
+	}
+
+	return 0;
+}
+
+static int it6625_set_fmt(struct v4l2_subdev *sd,
+			  struct v4l2_subdev_state *sd_state,
+			  struct v4l2_subdev_format *format)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	int ret;
+	u32 mbus_fmt_code = format->format.code;
+
+	ret = it6625_get_fmt(sd, sd_state, format);
+	format->format.code = mbus_fmt_code;
+
+	if (ret)
+		return ret;
+
+	ret = it6625_csi_mbus_code_idx(mbus_fmt_code);
+
+	if (ret < 0) {
+		v4l2_dbg(1, debug, sd,
+			 "%s: unsupported format code 0x%x, falling back to default",
+			 __func__, mbus_fmt_code);
+		ret = 0;
+		mbus_fmt_code = it6625_formats[ret].mbus_fmt_code;
+		format->format.code = mbus_fmt_code;
+	}
+
+	if (format->which == V4L2_SUBDEV_FORMAT_TRY) {
+		struct v4l2_mbus_framefmt *fmt;
+
+		fmt = v4l2_subdev_state_get_format(sd_state, format->pad);
+		fmt->code = format->format.code;
+		fmt->colorspace = format_to_colorspace(it6625_formats[ret].csi_format);
+		format->format.colorspace = fmt->colorspace;
+		v4l2_dbg(1, debug, sd, "%s: try format code = 0x%x",
+			 __func__, format->format.code);
+		return 0;
+	}
+
+	scoped_guard(mutex, &it6625->it6625_lock) {
+		it6625->csi_format = it6625_formats[ret].csi_format;
+		it6625->mbus_fmt_code = format->format.code;
+		it6625_enable_stream_locked(it6625, false);
+		it6625_set_mipi_config_locked(it6625, it6625->csi_format);
+	}
+
+	format->format.colorspace = format_to_colorspace(it6625_formats[ret].csi_format);
+
+	return 0;
+}
+
+static int it6625_g_edid(struct v4l2_subdev *sd,
+			 struct v4l2_subdev_edid *edid)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	int err;
+
+	if (edid->pad != 0)
+		return -EINVAL;
+
+	memset(edid->reserved, 0, sizeof(edid->reserved));
+
+	guard(mutex)(&it6625->edid_lock);
+
+	if (edid->start_block == 0 && edid->blocks == 0) {
+		edid->blocks = it6625->edid_blocks;
+		return 0;
+	}
+
+	if (it6625->edid_blocks == 0)
+		return -ENODATA;
+
+	if (edid->start_block >= it6625->edid_blocks || edid->blocks == 0)
+		return -EINVAL;
+
+	if (edid->blocks > it6625->edid_blocks - edid->start_block)
+		edid->blocks = it6625->edid_blocks - edid->start_block;
+
+	err = it6625_read_edid(it6625, edid->edid, edid->start_block,
+			       edid->blocks);
+
+	return (err < 0) ? err : 0;
+}
+
+static int it6625_s_edid(struct v4l2_subdev *sd,
+			 struct v4l2_subdev_edid *edid)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	int err;
+	u16 parent_pa = CEC_PHYS_ADDR_INVALID;
+
+	if (edid->pad != 0) {
+		v4l2_err(sd, "invalid pad %d", edid->pad);
+		return -EINVAL;
+	}
+
+	memset(edid->reserved, 0, sizeof(edid->reserved));
+
+	if (edid->start_block != 0) {
+		v4l2_err(sd, "start_block must be 0 for set edid");
+		return -EINVAL;
+	}
+
+	if (edid->blocks > EDID_NUM_BLOCKS_MAX) {
+		v4l2_err(sd, "too many edid blocks: %d", edid->blocks);
+		edid->blocks = EDID_NUM_BLOCKS_MAX;
+		return -E2BIG;
+	}
+
+	if (edid->blocks != 0) {
+		u16 pa = v4l2_get_edid_phys_addr(edid->edid,
+						 edid->blocks * 128, NULL);
+		err = v4l2_phys_addr_validate(pa, &parent_pa, NULL);
+		if (err) {
+			v4l2_err(sd, "invalid CEC physical address in EDID");
+			return err;
+		}
+	}
+
+	guard(mutex)(&it6625->edid_lock);
+
+	it6625_disable_hpd(it6625);
+	cec_phys_addr_invalidate(it6625->cec_adap);
+	it6625->edid_blocks = 0;
+
+	if (edid->blocks == 0)
+		return 0;
+
+	err = it6625_write_edid(it6625, edid->edid,
+				edid->start_block, edid->blocks);
+	if (err < 0) {
+		v4l2_err(sd, "write edid failed");
+		return err;
+	}
+
+	it6625->edid_blocks = edid->blocks;
+	cec_s_phys_addr(it6625->cec_adap, parent_pa, false);
+
+	if (hdmi_5v_power_present(it6625)) {
+		it6625_enable_hpd(it6625);
+		it6625_s_ctrl_detect_hdmi_5v(sd);
+	} else {
+		it6625_enable_auto_hpd(it6625);
+	}
+
+	return 0;
+}
+
+static const struct v4l2_subdev_core_ops it6625_core_ops = {
+	.log_status = it6625_log_status,
+	.interrupt_service_routine = it6625_isr,
+	.subscribe_event = it6625_subscribe_event,
+	.unsubscribe_event = v4l2_event_subdev_unsubscribe,
+};
+
+static const struct v4l2_subdev_video_ops it6625_video_ops = {
+	.g_input_status = it6625_g_input_status,
+	.s_stream = it6625_s_stream,
+};
+
+static const struct v4l2_subdev_pad_ops it6625_pad_ops = {
+	.enum_mbus_code = it6625_enum_mbus_code,
+	.set_fmt = it6625_set_fmt,
+	.get_fmt = it6625_get_fmt,
+	.get_edid = it6625_g_edid,
+	.set_edid = it6625_s_edid,
+	.enum_dv_timings = it6625_enum_dv_timings,
+	.dv_timings_cap = it6625_dv_timings_cap,
+	.get_mbus_config = it6625_get_mbus_config,
+	.s_dv_timings = it6625_pad_s_dv_timings,
+	.g_dv_timings = it6625_pad_g_dv_timings,
+	.query_dv_timings = it6625_pad_query_dv_timings,
+};
+
+static const struct v4l2_subdev_ops it6625_ops = {
+	.core = &it6625_core_ops,
+	.video = &it6625_video_ops,
+	.pad = &it6625_pad_ops,
+};
+
+static int it6625_init_state(struct v4l2_subdev *sd,
+			     struct v4l2_subdev_state *sd_state)
+{
+	struct v4l2_mbus_framefmt *fmt = v4l2_subdev_state_get_format(sd_state, 0);
+
+	fmt->code = it6625_formats[0].mbus_fmt_code;
+	fmt->colorspace = format_to_colorspace(it6625_formats[0].csi_format);
+
+	return 0;
+}
+
+static const struct v4l2_subdev_internal_ops it6625_internal_ops = {
+	.init_state = it6625_init_state,
+};
+
+static const struct v4l2_ctrl_config it6625_ctrl_audio_sampling_rate = {
+	.id = V4L2_CID_IT6625_AUDIO_SAMPLING_RATE,
+	.name = "Audio Sampling Rate",
+	.type = V4L2_CTRL_TYPE_INTEGER,
+	.min = 0,
+	.max = 1536000,
+	.step = 1,
+	.def = 0,
+	.flags = V4L2_CTRL_FLAG_READ_ONLY,
+};
+
+static const struct v4l2_ctrl_config it6625_ctrl_audio_present = {
+	.id = V4L2_CID_IT6625_AUDIO_PRESENT,
+	.name = "Audio Present",
+	.type = V4L2_CTRL_TYPE_BOOLEAN,
+	.min = 0,
+	.max = 1,
+	.step = 1,
+	.def = 0,
+	.flags = V4L2_CTRL_FLAG_READ_ONLY,
+};
+
+static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+	struct v4l2_ctrl_handler *hdl = &it6625->hdl;
+
+	v4l2_ctrl_handler_init(hdl, 4);
+	it6625->ctrl_5v_detect =
+		v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_DV_RX_POWER_PRESENT,
+				  0, 1, 0, 0);
+
+	it6625->ctrl_audio_sampling_rate =
+		v4l2_ctrl_new_custom(hdl,
+				     &it6625_ctrl_audio_sampling_rate,
+				     NULL);
+	it6625->ctrl_audio_present =
+		v4l2_ctrl_new_custom(hdl, &it6625_ctrl_audio_present, NULL);
+	it6625->ctrl_link_freq =
+		v4l2_ctrl_new_int_menu(hdl, NULL, V4L2_CID_LINK_FREQ,
+				       ARRAY_SIZE(it6625_link_freq) - 1,
+				       it6625->bus_type == V4L2_MBUS_CSI2_CPHY ? 1 : 0,
+				       it6625_link_freq);
+	if (hdl->error) {
+		v4l2_err(sd, "Failed to initialize controls");
+		v4l2_ctrl_handler_free(hdl);
+		return hdl->error;
+	}
+
+	sd->ctrl_handler = hdl;
+
+	return 0;
+}
+
+static void it6625_regdump_print(struct seq_file *s, const u8 *reg_buf)
+{
+	int i;
+
+	seq_puts(s, "     0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0A 0x0B 0x0C 0x0D 0x0E 0x0F\n");
+
+	for (i = 0; i < 256; i++) {
+		if (i % 16 == 0)
+			seq_printf(s, "[%02X] ", i & 0xF0);
+		seq_printf(s, "0x%02X ", reg_buf[i]);
+		if (i % 16 == 15)
+			seq_putc(s, '\n');
+	}
+}
+
+static int it6625_mipi_reg_show(struct seq_file *s, void *data)
+{
+	struct it6625 *it6625 = s->private;
+	u8 reg_buf[256];
+	int ret;
+
+	scoped_guard(mutex, &it6625->it6625_lock)
+		ret = it6625_read_bytes(it6625, 0x00, reg_buf, sizeof(reg_buf));
+	if (ret < 0)
+		return ret;
+	it6625_regdump_print(s, reg_buf);
+
+	return 0;
+}
+
+static int it6625_mipi_reg_open(struct inode *inode, struct file *file)
+{
+	return single_open(file, it6625_mipi_reg_show, inode->i_private);
+}
+
+static ssize_t it6625_mipi_reg_write(struct file *file,
+				     const char __user *user_buf,
+				     size_t count, loff_t *ppos)
+{
+	struct it6625 *it6625 = file_inode(file)->i_private;
+	char buf[32] = {};
+	unsigned int addr, val;
+	ssize_t len;
+	loff_t pos = 0;
+
+	len = simple_write_to_buffer(buf, sizeof(buf) - 1, &pos, user_buf, count);
+	if (len < 0)
+		return len;
+	buf[len] = '\0';
+
+	if (sscanf(buf, "%X %X", &addr, &val) != 2)
+		return -EINVAL;
+
+	scoped_guard(mutex, &it6625->it6625_lock)
+		it6625_write_byte(it6625, addr, val);
+
+	return count;
+}
+
+static const struct file_operations it6625_mipi_reg_fops = {
+	.owner = THIS_MODULE,
+	.open = it6625_mipi_reg_open,
+	.read = seq_read,
+	.write = it6625_mipi_reg_write,
+	.llseek = seq_lseek,
+	.release = single_release,
+};
+
+/*
+ * Maps a V4L2_DEBUGFS_IF_* framework flag to the actual HDMI packet-type
+ * header byte REG_IF_LATCH_HB expects to arm that InfoFrame type.
+ */
+static int it6625_if_packet_type(u32 type)
+{
+	switch (type) {
+	case V4L2_DEBUGFS_IF_AVI:
+		return 0x82;
+	case V4L2_DEBUGFS_IF_AUDIO:
+		return 0x84;
+	case V4L2_DEBUGFS_IF_SPD:
+		return 0x83;
+	case V4L2_DEBUGFS_IF_HDMI:
+		return 0x81;
+	default:
+		return -EINVAL;
+	}
+}
+
+static ssize_t it6625_debugfs_if_read(u32 type, void *priv, struct file *filp,
+				      char __user *ubuf, size_t count,
+				      loff_t *ppos)
+{
+	struct v4l2_subdev *sd = priv;
+	struct it6625 *it6625 = sd_to_6625(sd);
+	u8 buf[32] = {};
+	int packet_type;
+	int err, err_reset;
+	bool captured;
+	int len;
+
+	packet_type = it6625_if_packet_type(type);
+	if (packet_type < 0)
+		return 0;
+
+	guard(mutex)(&it6625->if_read_lock);
+
+	scoped_guard(mutex, &it6625->if_state_lock) {
+		scoped_guard(mutex, &it6625->it6625_lock)
+			err = it6625_write_byte(it6625, REG_IF_LATCH_HB, 0);
+		if (err)
+			return err;
+
+		err = it6625_drain_interrupts(it6625, NULL);
+		if (err)
+			return err;
+
+		reinit_completion(&it6625->if_latched);
+
+		it6625->if_active = true;
+		it6625->if_type = packet_type;
+		it6625->if_snapshot_done = false;
+		it6625->if_snapshot_err = 0;
+
+		scoped_guard(mutex, &it6625->it6625_lock)
+			err = it6625_write_byte(it6625, REG_IF_LATCH_HB,
+						packet_type);
+		if (err) {
+			scoped_guard(mutex, &it6625->it6625_lock)
+				it6625_write_byte(it6625, REG_IF_LATCH_HB, 0);
+			it6625->if_active = false;
+			return err;
+		}
+	}
+
+	wait_for_completion_timeout(&it6625->if_latched, msecs_to_jiffies(100));
+
+	scoped_guard(mutex, &it6625->if_state_lock) {
+		captured = it6625->if_snapshot_done;
+		it6625->if_active = false;
+
+		scoped_guard(mutex, &it6625->it6625_lock)
+			err_reset = it6625_write_byte(it6625, REG_IF_LATCH_HB, 0);
+
+		if (!captured) {
+			if (err_reset)
+				return err_reset;
+			return 0;
+		}
+
+		if (!it6625->if_snapshot_err) {
+			buf[0] = packet_type;
+			memcpy(&buf[1], it6625->if_snapshot, 31);
+		}
+
+		err = it6625->if_snapshot_err ? it6625->if_snapshot_err : err_reset;
+		if (err)
+			return err;
+	}
+
+	len = buf[2] ? buf[2] + 4 : -ENOENT;
+	if (len > (int)sizeof(buf))
+		len = -ENOENT;
+	if (len < 0)
+		return 0;
+	return simple_read_from_buffer(ubuf, count, ppos, buf, len);
+}
+
+static void it6625_debugfs_init(struct it6625 *it6625, struct i2c_client *client)
+{
+	it6625->debugfs_dir = debugfs_create_dir(dev_name(&client->dev), NULL);
+
+	debugfs_create_file("mipi_reg", 0600, it6625->debugfs_dir, it6625,
+			    &it6625_mipi_reg_fops);
+
+	it6625->infoframes = v4l2_debugfs_if_alloc(it6625->debugfs_dir,
+						   V4L2_DEBUGFS_IF_AVI | V4L2_DEBUGFS_IF_AUDIO |
+						   V4L2_DEBUGFS_IF_SPD | V4L2_DEBUGFS_IF_HDMI,
+						   &it6625->sd, it6625_debugfs_if_read);
+}
+
+static void it6625_init_data(struct it6625 *it6625)
+{
+	static struct v4l2_dv_timings default_timing =
+			V4L2_DV_BT_CEA_1920X1080P60;
+
+	it6625->csi_lanes = 4;
+	it6625->port_num = 1;
+	it6625->bus_type = V4L2_MBUS_CSI2_DPHY;
+	it6625->csi_format = it6625_formats[0].csi_format;
+	it6625->mbus_fmt_code = it6625_formats[0].mbus_fmt_code;
+	it6625->timings = default_timing;
+	/* firmware ships with a verified 2-block default EDID in EDID RAM */
+	it6625->edid_blocks = 2;
+}
+
+static int it6625_parse_endpoint(struct it6625 *it6625)
+{
+	struct device *dev = it6625->dev;
+	/*
+	 * Pre-setting bus_type here makes v4l2_fwnode_endpoint_alloc_parse()
+	 * treat it as a hard requirement and reject any endpoint whose DT
+	 * bus-type disagrees, so this must stay V4L2_MBUS_UNKNOWN to let it
+	 * autodetect C-PHY vs D-PHY from the endpoint itself.
+	 */
+	struct v4l2_fwnode_endpoint endpoint = { .bus_type = V4L2_MBUS_UNKNOWN };
+	struct device_node *ep = NULL;
+	unsigned int max_lanes;
+	unsigned int port;
+	int ret;
+
+	/*
+	 * port@0 and port@1 are the two CSI-2 output ports MIPI0/MIPI1
+	 * (port@2 is the HDMI input). This chip series can drive both
+	 * simultaneously in split or mirror mode, so port_num counts how
+	 * many of MIPI0/MIPI1 have an endpoint wired up. This driver only
+	 * wires up a single source pad, so lane/bus-type configuration is
+	 * parsed from whichever of the two is found first.
+	 */
+	it6625->port_num = 0;
+	for (port = 0; port < 2; port++) {
+		struct device_node *port_ep =
+			of_graph_get_endpoint_by_regs(dev->of_node, port, -1);
+
+		if (!port_ep)
+			continue;
+
+		it6625->port_num++;
+		if (!ep)
+			ep = port_ep;
+		else
+			of_node_put(port_ep);
+	}
+
+	if (!ep) {
+		it6625->port_num = 1;
+		dev_dbg(dev, "no CSI-2 endpoint node found, using default %u CSI lanes",
+			it6625->csi_lanes);
+		return 0;
+	}
+
+	ret = v4l2_fwnode_endpoint_alloc_parse(of_fwnode_handle(ep), &endpoint);
+	of_node_put(ep);
+	if (ret) {
+		dev_err(dev, "failed to parse endpoint: %d", ret);
+		return ret;
+	}
+
+	if (endpoint.bus_type != V4L2_MBUS_CSI2_DPHY &&
+	    endpoint.bus_type != V4L2_MBUS_CSI2_CPHY) {
+		dev_err(dev, "unsupported bus type %d, expected CSI-2 D-PHY or C-PHY",
+			endpoint.bus_type);
+		v4l2_fwnode_endpoint_free(&endpoint);
+		return -EINVAL;
+	}
+
+	if (endpoint.bus_type == V4L2_MBUS_CSI2_CPHY &&
+	    it6625->chip_type != IT6626_CHIP) {
+		dev_err(dev, "IT6625 does not support C-PHY, only IT6626 does");
+		v4l2_fwnode_endpoint_free(&endpoint);
+		return -EINVAL;
+	}
+
+	max_lanes = (endpoint.bus_type == V4L2_MBUS_CSI2_CPHY) ? 3 : 4;
+
+	if (endpoint.bus.mipi_csi2.num_data_lanes == 0 ||
+	    endpoint.bus.mipi_csi2.num_data_lanes > max_lanes) {
+		dev_err(dev,
+			"invalid number of CSI data lanes: %u (max %u for this bus type)",
+			endpoint.bus.mipi_csi2.num_data_lanes, max_lanes);
+		v4l2_fwnode_endpoint_free(&endpoint);
+		return -EINVAL;
+	}
+
+	it6625->csi_lanes = endpoint.bus.mipi_csi2.num_data_lanes;
+	it6625->bus_type = endpoint.bus_type;
+	v4l2_fwnode_endpoint_free(&endpoint);
+
+	return 0;
+}
+
+static int it6625_parse_dt(struct it6625 *it6625)
+{
+	return it6625_parse_endpoint(it6625);
+}
+
+static int it6625_init_v4l2_subdev(struct it6625 *it6625)
+{
+	struct v4l2_subdev *sd = &it6625->sd;
+	int err;
+
+	sd->dev = it6625->dev;
+
+	v4l2_i2c_subdev_init(sd, it6625->i2c_client, &it6625_ops);
+	sd->internal_ops = &it6625_internal_ops;
+	sd->flags |= V4L2_SUBDEV_FL_HAS_DEVNODE | V4L2_SUBDEV_FL_HAS_EVENTS;
+	if (it6625_v4l2_init_controls(sd)) {
+		dev_err(it6625->dev, "Failed to initialize v4l2 controls");
+		return -ENOMEM;
+	}
+
+	it6625->pad.flags = MEDIA_PAD_FL_SOURCE;
+	sd->entity.function = MEDIA_ENT_F_CAM_SENSOR;
+	err = media_entity_pads_init(&sd->entity, 1, &it6625->pad);
+	if (err < 0) {
+		dev_err(it6625->dev, "%s %d err=%d", __func__, __LINE__, err);
+		v4l2_ctrl_handler_free(sd->ctrl_handler);
+		return err;
+	}
+
+	return 0;
+}
+
+static int it6625_check_device(struct it6625 *it6625)
+{
+	static const u8 chip_ids[][2] = {
+		{ 0x66, 0x25 },
+		{ 0x66, 0x26 },
+	};
+	int chip_id0, chip_id1;
+
+	chip_id0 = it6625_read_byte(it6625, REG_CHIP_ID_0);
+	chip_id1 = it6625_read_byte(it6625, REG_CHIP_ID_1);
+	if (chip_id0 != chip_ids[it6625->chip_type][0] ||
+	    chip_id1 != chip_ids[it6625->chip_type][1]) {
+		dev_err(it6625->dev,
+			"chip ID mismatch: got 0x%02x%02x, expected 0x%02x%02x",
+			chip_id0, chip_id1,
+			chip_ids[it6625->chip_type][0],
+			chip_ids[it6625->chip_type][1]);
+		return -ENODEV;
+	}
+
+	return 0;
+}
+
+static int it6625_probe(struct i2c_client *client)
+{
+	struct it6625 *it6625;
+	struct v4l2_subdev *sd;
+	int err;
+
+	if (!i2c_check_functionality(client->adapter, I2C_FUNC_SMBUS_BYTE_DATA))
+		return -EIO;
+
+	it6625 = devm_kzalloc(&client->dev, sizeof(struct it6625), GFP_KERNEL);
+	if (!it6625)
+		return -ENOMEM;
+
+	it6625->chip_type = (uintptr_t)i2c_get_match_data(client);
+
+	it6625->reset_gpio = devm_gpiod_get_optional(&client->dev, "reset",
+						     GPIOD_OUT_HIGH);
+	if (IS_ERR(it6625->reset_gpio))
+		return PTR_ERR(it6625->reset_gpio);
+
+	if (it6625->reset_gpio) {
+		usleep_range(1000, 2000);
+		gpiod_set_value_cansleep(it6625->reset_gpio, 0);
+		usleep_range(10000, 11000);
+	}
+
+	err = it6625_regmap_i2c_init(client, it6625);
+	if (err)
+		return err;
+
+	err = it6625_check_device(it6625);
+	if (err)
+		return err;
+
+	it6625_init_data(it6625);
+
+	err = it6625_parse_dt(it6625);
+	if (err)
+		return err;
+
+	mutex_init(&it6625->it6625_lock);
+	mutex_init(&it6625->edid_lock);
+	mutex_init(&it6625->if_read_lock);
+	mutex_init(&it6625->if_state_lock);
+	init_completion(&it6625->if_latched);
+	INIT_DELAYED_WORK(&it6625->hpd_delayed_work, it6625_hpd_delayed_work);
+	INIT_WORK(&it6625->polling_work, it6625_polling_work);
+
+	if (client->irq) {
+		err = devm_request_threaded_irq(&client->dev, client->irq,
+						NULL, it6625_irq_handler,
+						IRQF_ONESHOT |
+						IRQF_NO_AUTOEN,
+						"it6625", it6625);
+		if (err)
+			goto err_clean_work_queues;
+	} else {
+		dev_info(it6625->dev, "no IRQ, falling back to polling");
+		timer_setup(&it6625->timer, it6625_irq_poll_timer, 0);
+	}
+
+	sd = &it6625->sd;
+	err = it6625_init_v4l2_subdev(it6625);
+	if (err)
+		goto err_clean_work_queues;
+
+	err = v4l2_ctrl_handler_setup(sd->ctrl_handler);
+	if (err)
+		goto err_clean_hdl;
+
+	it6625->cec_adap = cec_allocate_adapter(&it6625_cec_adap_ops,
+						it6625, dev_name(it6625->dev),
+						CEC_CAP_DEFAULTS |
+						CEC_CAP_MONITOR_ALL |
+						CEC_CAP_PHYS_ADDR,
+						1);
+	if (IS_ERR(it6625->cec_adap)) {
+		err = PTR_ERR(it6625->cec_adap);
+		dev_err(it6625->dev, "%s %d", __func__, __LINE__);
+		goto err_clean_hdl;
+	}
+
+	err = cec_register_adapter(it6625->cec_adap, &client->dev);
+	if (err < 0) {
+		dev_err(it6625->dev, "%s: failed to register the cec device", __func__);
+		cec_delete_adapter(it6625->cec_adap);
+		it6625->cec_adap = NULL;
+		goto err_clean_hdl;
+	}
+
+	it6625_debugfs_init(it6625, client);
+
+	it6625_initial_setup(it6625);
+	it6625_v4l2_sd_ctrl_update(sd);
+
+	err = v4l2_async_register_subdev(sd);
+	if (err < 0) {
+		dev_err(it6625->dev, "%s %d err=%d", __func__, __LINE__, err);
+		goto err_clean_debugfs;
+	}
+
+	if (client->irq)
+		enable_irq(client->irq);
+	else
+		mod_timer(&it6625->timer, jiffies + msecs_to_jiffies(POLL_INTERVAL_MS));
+
+	return 0;
+
+err_clean_debugfs:
+	v4l2_debugfs_if_free(it6625->infoframes);
+	debugfs_remove_recursive(it6625->debugfs_dir);
+	cec_unregister_adapter(it6625->cec_adap);
+err_clean_hdl:
+	media_entity_cleanup(&sd->entity);
+	v4l2_ctrl_handler_free(&it6625->hdl);
+
+err_clean_work_queues:
+	if (!client->irq)
+		timer_shutdown_sync(&it6625->timer);
+	cancel_work_sync(&it6625->polling_work);
+	cancel_delayed_work_sync(&it6625->hpd_delayed_work);
+	mutex_destroy(&it6625->it6625_lock);
+	mutex_destroy(&it6625->edid_lock);
+	mutex_destroy(&it6625->if_read_lock);
+	mutex_destroy(&it6625->if_state_lock);
+	return err;
+}
+
+static void it6625_remove(struct i2c_client *client)
+{
+	struct v4l2_subdev *sd = i2c_get_clientdata(client);
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	v4l2_debugfs_if_free(it6625->infoframes);
+
+	if (client->irq)
+		disable_irq(client->irq);
+	else
+		timer_shutdown_sync(&it6625->timer);
+
+	cancel_work_sync(&it6625->polling_work);
+	cancel_delayed_work_sync(&it6625->hpd_delayed_work);
+
+	v4l2_async_unregister_subdev(sd);
+	v4l2_device_unregister_subdev(sd);
+
+	debugfs_remove_recursive(it6625->debugfs_dir);
+	cec_unregister_adapter(it6625->cec_adap);
+	mutex_destroy(&it6625->it6625_lock);
+	mutex_destroy(&it6625->edid_lock);
+	mutex_destroy(&it6625->if_read_lock);
+	mutex_destroy(&it6625->if_state_lock);
+	media_entity_cleanup(&sd->entity);
+	v4l2_ctrl_handler_free(&it6625->hdl);
+}
+
+static const struct i2c_device_id it6625_id[] = {
+	{ .name = "it6625", .driver_data = IT6625_CHIP },
+	{ .name = "it6626", .driver_data = IT6626_CHIP },
+	{}
+};
+MODULE_DEVICE_TABLE(i2c, it6625_id);
+
+static const struct of_device_id it6625_of_match[] = {
+	{ .compatible = "ite,it6625", .data = (void *)IT6625_CHIP },
+	{ .compatible = "ite,it6626", .data = (void *)IT6626_CHIP },
+	{},
+};
+MODULE_DEVICE_TABLE(of, it6625_of_match);
+
+static struct i2c_driver it6625_driver = {
+	.driver = {
+		.name = "it6625",
+		.of_match_table = it6625_of_match,
+	},
+	.probe = it6625_probe,
+	.remove = it6625_remove,
+	.id_table = it6625_id,
+};
+module_i2c_driver(it6625_driver);
+
+MODULE_DESCRIPTION("iTE it6625/it6626 HDMI to MIPI CSI bridge driver");
+MODULE_AUTHOR("Hermes Wu <Hermes.wu@ite.com.tw>");
+MODULE_LICENSE("GPL");
diff --git a/include/uapi/linux/it6625.h b/include/uapi/linux/it6625.h
new file mode 100644
index 0000000000000000000000000000000000000000..a895658aaf6a80d3fb624cdece33c5135161c72d
--- /dev/null
+++ b/include/uapi/linux/it6625.h
@@ -0,0 +1,25 @@
+/* SPDX-License-Identifier: GPL-2.0+ WITH Linux-syscall-note */
+/*
+ * Controls header for IT6625/IT6626 driver
+ */
+
+#ifndef _UAPI_LINUX_IT6625_H
+#define _UAPI_LINUX_IT6625_H
+
+#include <linux/v4l2-controls.h>
+
+/*
+ * Currently detected HDMI audio sampling rate, in Hz. Read-only.
+ * 0 means the rate is unavailable/unknown: no audio is currently
+ * present on the input, the hardware reported a sample-rate id this
+ * driver doesn't recognize, or the status read itself failed. Never a
+ * literal 0 Hz sample rate.
+ */
+#define V4L2_CID_IT6625_AUDIO_SAMPLING_RATE	(V4L2_CID_USER_IT6625_BASE + 0)
+
+/*
+ * Whether HDMI audio is currently present on the input. Read-only.
+ */
+#define V4L2_CID_IT6625_AUDIO_PRESENT		(V4L2_CID_USER_IT6625_BASE + 1)
+
+#endif /* _UAPI_LINUX_IT6625_H */
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index affec0ab4781507be761cb791ff737460acf9cb7..6aa2a57753ae5aacb433201d68d51bb345ca0229 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -234,6 +234,12 @@ enum v4l2_colorfx {
  */
 #define V4L2_CID_USER_MALI_C55_BASE		(V4L2_CID_USER_BASE + 0x1230)
 
+/*
+ * The base for IT6625/IT6626 driver controls.
+ * We reserve 16 controls for this driver.
+ */
+#define V4L2_CID_USER_IT6625_BASE		(V4L2_CID_USER_BASE + 0x1240)
+
 /* MPEG-class control IDs */
 /* The MPEG controls are applicable to all codec controls
  * and the 'MPEG' part of the define is historical */

-- 
2.34.1

