From: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Subject: [PATCH v2 0/4] drm: Add Fresco Logic FL2000 USB display driver
Date: Wed, 11 Nov 2026 22:34:07 -0500
Message-Id: <20261111-fl2000-upstream-v2-0-201f87708cb0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4XM2prpoCS68j8MC1qmMIZX2kI0h
 H+34NrlSc49d4XAXjjAPVvB8yJBxiEBnTKwbTU0rKRODIRUaI1X5TpCRDVPIXquepU7S6wdYk0
 XSKvJs5P3UXyWPw6zebGNe2Y3Wglx9J/jctG797++aIXKGF3kbA3leHs0fSXd2Y49lNu2fQHeN
 hYQwAAAAA==
X-Change-ID: 20261105-fl2000-upstream-3fc2e1f00d24
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794454449; l=11996;
 i=angelcrispinvaldivia@gmail.com; s=20261106; h=from:subject:message-id;
 bh=43XFtzRhNur/WmEhZyMLx1W6oUchF58B4Xxb7Xh6Oew=;
 b=6eS/0cY+n6GgAFIAeTl4cTS1SX+Q+YmchIP4g7VWVNef0XgvbyxNdwmzvMhzgw8O2Tmnkg0HB
 ZkJlqdWodaoDFY4FMHd2+GagVdjrD10kl7TbwZGEjvgCuULgFZZLY44
X-Developer-Key: i=angelcrispinvaldivia@gmail.com; a=ed25519;
 pk=80bQU/p2R0pLIfdfJaB5I/2obI+RxQHondq5DEM0tbg=
X-Endpoint-Received: by B4 Relay for angelcrispinvaldivia@gmail.com/20261106 with auth_id=1425
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds a DRM driver for USB display adapters built around the
Fresco Logic FL2000DX (USB ID 1d5c:2000). These are sold under many
brands as cheap USB 3.0 to VGA/HDMI dongles; the HDMI variants pair the
FL2000 with an ITE IT66121 HDMI transmitter on the FL2000's I2C bus.
Today these adapters only work on Linux with out-of-tree drivers.

The driver started as Artem Mygaiev's out-of-tree fl2000_drm driver,
itself partly based on Fresco Logic's reference driver; their copyright
lines are kept. I ported it to current kernels, fixed the problems found
on real hardware (EDID, crashes on disconnect, frames that were never
terminated, imported buffers read from the wrong VRAM), added the analog
VGA output and cleaned it up for submission.

I intend to maintain this driver for the long term: patch 1 adds a
MAINTAINERS entry with me as maintainer, I have the hardware to test
on, and I will keep following review and bug reports on dri-devel.

The series builds the driver up in four steps, each of which compiles
on its own:

  1. USB driver, FL2000 register access (regmap) and I2C adapter
  2. IT66121 HDMI transmitter bridge
  3. frame streaming over bulk URBs
  4. the KMS pipeline, which makes the display usable, including the
     analog VGA output of adapters that have both connectors

v1 was an RFC. This version answers its review and is meant to be
applied, but some design points are still open and I would like your
view on them; the first one could change the series:

1. IT66121 support. The series carries its own small IT66121 bridge
   (fl2000_it66121.c) instead of reusing drivers/gpu/drm/bridge/
   ite-it66121.c, because I could not find a way to use the in-tree
   driver on a PC: it depends on OF (x86 distribution kernels have no
   CONFIG_OF), reads bus-width and its next bridge through of_graph,
   requires a reset GPIO the FL2000 boards do not have, and DRM has no
   bridge lookup without OF. It also reads the EDID through its DDC
   engine, which on these boards is not connected to the monitor (the
   EDID is read with the FL2000 I2C engine instead).
   Reusing it would take converting ite-it66121 to the fwnode API with an
   optional reset GPIO, a fwnode-based bridge lookup in drm_bridge.c, and
   a small bridge of this driver providing the EDID. Is that the direction
   you would like, or is a private IT66121 bridge acceptable for a USB
   device like this one?

2. Hotplug. The bridge attaches with DRM_BRIDGE_ATTACH_NO_CONNECTOR and
   the HDMI connector comes from drm_bridge_connector. The bridge
   reports DETECT and EDID only: the IT66121 interrupt reaches the host
   through the FL2000 interrupt endpoint, which makes the driver send a
   hotplug event for the device, so there is no DRM_BRIDGE_OP_HPD and
   the connector is also polled. Would reporting HPD with
   drm_bridge_hpd_notify() from that path be preferred?

3. Pixel conversion. The stream converts with its own small line
   converters instead of drm_fb_xrgb8888_to_*(). The framebuffer is
   usually imported from the primary GPU and sits in write-combined
   VRAM; the format helpers read such I/O memory with memcpy_fromio(),
   which takes ~88 ms per 1080p frame, while drm_memcpy_from_wc() into a
   cached line buffer takes ~8 ms. The converters also apply the
   FL2000's 32-bit word swap and only touch the damaged rectangle of a
   shadow frame. Would a helper that reads its source through
   drm_memcpy_from_wc() be welcome, so this could go away?

4. VGA detection. The chip has a single monitor sense input, which on
   the adapter I have follows whichever monitor is plugged in, HDMI or
   VGA. The VGA connector therefore reports a monitor when the chip
   senses one and the IT66121 hot plug line is low, which means a
   monitor on VGA is not reported while one is on HDMI (clone mode
   needs video=VGA-1:e). Is this an acceptable way to do it, and is
   there a better signal I should look for in the chip?

The rest of the pipeline follows the current helpers: regular atomic
plane/CRTC/encoder objects with managed initialisation, GEM SHMEM with
shadow-plane access and fbdev emulation through drm_client_setup().
There is no cursor plane and no vblank support. On the USB side the
driver matches interface 0 and claims the other two, everything hangs
off that binding, and resets and system sleep do not unbind it.

Other known limitations: XRGB8888 goes out as RGB888, and modes the USB
link can only carry in RGB565 (2560x1080 on USB 3.0, 640x480 on USB 2.0,
as there is no compression) need a framebuffer in that format. RGB565
was seen working at 1280x720 on HDMI and 1024x768 on VGA, but those
larger modes have not been tried; and adapters with a VGA connector
only, without an IT66121, are not supported: the analog output is only
added next to the HDMI one.

Tested on x86_64 (amdgpu laptop, GNOME Wayland) with a UGREEN USB 3.0
adapter with HDMI and VGA connectors: a 1920x1080 monitor on HDMI, and
an old 1366x768 monitor without a usable EDID on VGA. EDID, mode
setting in XRGB8888 and RGB565, plugging and unplugging monitors,
system sleep, USB resets and the desktop work, with one frame per
refresh on the link. With Mutter 51.1, which renders in XRGB2101010
when it can, the missing 10-bit formats make it copy the frames on the
GPU instead, and that copy path leaks a framebuffer per frame (Mutter
issue #5101; the fix is on Mutter's stable branch for its next release,
51.2).
The unplug, unbind, module removal and USB reset paths were also run
under KASAN and lockdep against an emulated FL2000 on raw_gadget and
dummy_hcd. Every patch builds without warnings with W=1 on top of
drm-misc-next, sparse is clean, and the series passes checkpatch
--strict.

Tool use, as described in Documentation/process/generated-content.rst: I
used an AI coding assistant (Claude Code with Anthropic Claude models)
extensively while preparing this series. It helped port the driver to the
current APIs, clean it up to kernel style, write the shadow-frame
streaming, track down and fix the hangs on unplug,
and draft the commit messages and this letter. I reviewed the result and
tested it on the hardware described above; the Signed-off-by lines are
mine. The series was generated and checked (per-patch builds, checkpatch)
by scripts in the out-of-tree repository this driver is developed in.

---
Changes in v2:
- Sent as a regular series: v1 was an RFC.
- From the review of Thomas Zimmermann:
  - No cursor plane, and no blending in the driver.
  - No vblank timer, and so no vblank support.
  - The EDID is not kept: it is read from the monitor on every probe.
  - The formats are XRGB8888, converted to RGB888, and RGB565, sent as
    it is. The 10-bit ones went: they are not native (the device takes
    RGB888 or RGB565), and they were only converted down. What the USB
    link cannot carry at a mode fails in the atomic check of the plane;
    the CRTC no longer picks a format. (This makes Mutter 51.1 copy its
    frames through a path that leaks, as said above.)
  - The limits are what the timing registers hold, 12 bits (4095).
  - mode_fixup adjusts the clock, mode_valid returns MODE_* codes, the
    helpers are used as drop-ins, and the plane helper goes first in the
    plane check.
  - The interrupt endpoint is only polled once the device is registered,
    and after system sleep once the state is restored, so no state about
    that in the driver. The chips themselves are still set up before
    restoring the state, as restoring it writes to them.
  - Forcing the monitor sense went to the HDMI encoder, and the CRTC
    only enables the interrupts about frames.
  - struct fl2000_device, sorted driver flags, drm_dbg(), fewer
    comments.
- Convert each damage rectangle of the plane instead of their bounding
  box. A compositor that copies into a rotation of buffers only keeps
  the damage current, and the pixels between the rectangles could bring
  back older content.
- Bind through interface 0 and claim the other two with
  usb_driver_claim_interface(), with everything hanging off that
  binding, instead of keeping shared state on the usb_device: unloading
  the module or unbinding the driver left it all behind, pointing into
  freed memory. This answers question 3 of v1, which is gone. There is
  no component framework any more, the bridge is attached directly, and
  the DRM device hangs off the interface.
- USB resets no longer unbind the driver (.pre_reset/.post_reset).
- Keep the stream as long as the DRM device, and guard everything that
  reaches a register with drm_dev_enter() or drm_bridge_enter().
- Really probe for the IT66121: the detection had its return values
  inverted and always "found" the chip at the first address, without any
  transfer.
- Reject modes larger than the limits in the CRTC check. The core only
  applies max_width/max_height to probed modes, and a mode with an off-
  screen primary plane could wrap the 32-bit buffer size.
- Do not write the old shadow frame with a new geometry after a failed
  mode set.
- Remove the EDID read through the IT66121 DDC engine, which never
  completes on these boards and cannot work behind an I2C engine that
  reads whole dwords (each read of the DDC status pops the DDC FIFO).
  The DDC bus release stays.
- Honour the plane's source rectangle: a framebuffer larger than the
  mode froze the output.
- No phantom VGA monitor from the forced monitor sense when HDMI is
  unplugged.
- Acknowledge the IT66121 from the FL2000 interrupt and unmask its hot
  plug, instead of polling it over USB ten times a second. Enable the
  monitor interrupts at probe, not at the first mode set.
- Keep FL2000 resets and I2C control register writes out of running I2C
  operations.
- Smaller fixes: URB submission retries bounded (-EAGAIN looped
  forever), no pointer in urb->transfer_buffer,
  flush_kernel_vmap_range() before sending a frame, I2C message
  validation through the adapter quirks, a lost status event when
  clearing the LBUF flags, interrupt URB interval and endpoint, a NULL
  dereference on allocation failure, suspend error handling.

Most of these come from the Sashiko review of v1.

- Link to v1: https://patch.msgid.link/20261105-fl2000-upstream-v1-0-bb163ecb2309@gmail.com

---
Angel Gabriel Crispin Valdivia (4):
      drm/fl2000: Add USB driver with register and I2C access
      drm/fl2000: Add ITE IT66121 HDMI transmitter support
      drm/fl2000: Add frame streaming
      drm/fl2000: Add KMS display pipeline

 MAINTAINERS                                  |   7 +
 drivers/gpu/drm/Kconfig                      |   1 +
 drivers/gpu/drm/Makefile                     |   1 +
 drivers/gpu/drm/fl2000/Kconfig               |  19 +
 drivers/gpu/drm/fl2000/Makefile              |  13 +
 drivers/gpu/drm/fl2000/fl2000.h              | 159 +++++
 drivers/gpu/drm/fl2000/fl2000_drm.c          | 902 +++++++++++++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_drv.c          | 222 +++++++
 drivers/gpu/drm/fl2000/fl2000_i2c.c          | 179 ++++++
 drivers/gpu/drm/fl2000/fl2000_interrupt.c    | 226 +++++++
 drivers/gpu/drm/fl2000/fl2000_it66121.c      | 799 ++++++++++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_it66121.h      |  18 +
 drivers/gpu/drm/fl2000/fl2000_it66121_regs.h | 284 +++++++++
 drivers/gpu/drm/fl2000/fl2000_registers.c    | 315 ++++++++++
 drivers/gpu/drm/fl2000/fl2000_registers.h    | 276 ++++++++
 drivers/gpu/drm/fl2000/fl2000_streaming.c    | 807 ++++++++++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_vga.c          | 223 +++++++
 17 files changed, 4451 insertions(+)
---
base-commit: 41ecf852c07391687beb129e12a231760b5d783f
change-id: 20261105-fl2000-upstream-3fc2e1f00d24

Best regards,
--  
Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>

