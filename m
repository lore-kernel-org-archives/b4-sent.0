From: =?utf-8?q?Burak_G=C3=B6nc=C3=BC?= <burakgon12@gmail.com>
Subject: [PATCH v2 0/2] drm/i915/cx0: TCSS power for the non-TC C20 PHY on
 PTL port B
Date: Thu, 15 Oct 2026 01:26:39 +0300
Message-Id: <20261015-ptl-port-b-tcss-v2-0-e00ce882402d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0Jm7Zi2IKIr72FY0KHCGKCkU4mGc
 HcB1y5f8v77M4gL7ASuyQzBTSzshxXMIQFqq6FxyPXKYJTJtVI5jrHD0YeIFiOJYGE1WTrVl8I
 pWFdjcA9+78V7+WN52aejuGU2o2WJPnz2y0lv3v/6pFGjyVR+VmlmqE5vTV9xdyTfQ7ksyxcro
 k0QwAAAAA==
X-Change-ID: 20261006-ptl-port-b-tcss-8b1cbc5d98e0
To: intel-gfx@lists.freedesktop.org, intel-xe@lists.freedesktop.org
Cc: Jani Nikula <jani.nikula@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, Imre Deak <imre.deak@intel.com>, 
 Mika Kahola <mika.kahola@intel.com>, 
 =?utf-8?q?Burak_G=C3=B6nc=C3=BC?= <burakgon12@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016806; l=2674;
 i=burakgon12@gmail.com; s=20261006; h=from:subject:message-id;
 bh=SZC/slVBzdiGwyNX2y2/FuFPqz2qwCdGx6MS51/RG4o=;
 b=wxwZT4WiAlKRD0t3ezMCw88gnTXU+WGrWyaFowg3QlItaO1sa+Cugj4uiuok9EGxxjYrxzXte
 eXS7Wc+p5Y7CS/R7xaJiVZgBdIT/qpowLyJEhn294ksPLaSWVRPJm48
X-Developer-Key: i=burakgon12@gmail.com; a=ed25519;
 pk=qcexQajnoYGkNqFOy3eFqTzvqTOR/P++ksapi6qUbvw=
X-Endpoint-Received: by B4 Relay for burakgon12@gmail.com/20261006 with auth_id=1126
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On PTL, port B is driven by a C20 PHY that sits in the Type-C
subsystem, but nothing in the driver requests TCSS power for it; only
the firmware does, when it lights a display on the port at boot. The
ASUS Zenbook Duo UX8407AA drives its second internal panel from port B.
After a power-on with the detachable keyboard lying on that panel, the
first enable of the panel fails and can hang the machine (gitlab issue
9196).

Patch 2 requests TCSS power for such a PHY around its PLL enable and
disable. Patch 1 first serializes the TCSS mailbox handshake of
Wa_14020908590, which patch 2 reuses and which the TC ports could
already race on.

Two questions from v1 are still open:

- Does port B's C20 PHY on PTL always need the TCSS power request when
  it is used as a non-TC port, as this series assumes, or does this
  belong in the port's power well / AUX handling, or in a board quirk?
- Should the request be held for as long as the port is in use rather
  than per PLL enable/disable? Releasing it while the panel is off puts
  the hardware back into the state an unpatched kernel has; holding it
  showed no measurable difference in package power or PC10/LPI
  residency on this machine.

EDITME: v2 test results on the hardware.

Compile-tested on drm-tip with W=1 for i915 and xe (clang). HDMI/DP on
port B could not be tested, as this board only drives eDP there.

An LLM-based assistant helped with the investigation and with writing
the patches; I tested them on the hardware and reviewed them.

---
Changes in v2:
- New patch 1: serialize the TCSS mailbox with a display-wide mutex; it
  was covered only by each TC port's own lock (Sashiko review)
- Patch 2: also wait for the TCSS power state to clear when the request
  is released, as the TC PHY code does (Sashiko review)
- Drop the RFC prefix
- Link to v1: https://patch.msgid.link/20261006-ptl-port-b-tcss-v1-1-240670342cd3@gmail.com

---
Burak Göncü (2):
      drm/i915/tc: serialize the TCSS power request mailbox
      drm/i915/cx0: request TCSS power for the non-TC C20 PHY on PTL port B

 drivers/gpu/drm/i915/display/intel_cx0_phy.c       | 37 ++++++++++++++++++++++
 drivers/gpu/drm/i915/display/intel_display_core.h  |  5 +++
 .../gpu/drm/i915/display/intel_display_driver.c    |  1 +
 drivers/gpu/drm/i915/display/intel_tc.c            | 33 +++++++++++++++++--
 drivers/gpu/drm/i915/display/intel_tc.h            |  1 +
 5 files changed, 74 insertions(+), 3 deletions(-)
---
base-commit: daeb062fc40f727fafefed080c6d12a5ad1d0d12
change-id: 20261006-ptl-port-b-tcss-8b1cbc5d98e0

Best regards,
--  
Burak Göncü <burakgon12@gmail.com>

