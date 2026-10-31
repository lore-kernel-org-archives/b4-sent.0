From: =?utf-8?q?Diego_Nogu=C3=AAs?= <diego.sure@gmail.com>
Date: Sat, 31 Oct 2026 01:18:18 +0100
Subject: [PATCH RFC] drm/dp_tunnel: Allow BWA when the DP IN adapter does
 not advertise it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261031-dp-tunnel-bwa-flag-v1-1-f94ed3179349@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA2ND3ZQC3ZLSvLzUHN2k8kTdtJzEdF0jM3ODJJMUE2NjC0MloMaCotS
 0zAqwodFKQW7OSrEQweLSpKzU5BKQcUq1tQCFoZ1/ewAAAA==
X-Change-ID: 20261031-dp-tunnel-bwa-flag-2670b4d43381
To: Imre Deak <imre.deak@intel.com>, dri-devel@lists.freedesktop.org, 
 Uma Shankar <uma.shankar@intel.com>, 
 =?utf-8?q?Ville_Syrj=C3=A4l=C3=A4?= <ville.syrjala@linux.intel.com>
Cc: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Mika Westerberg <westeri@kernel.org>, intel-gfx@lists.freedesktop.org, 
 intel-xe@lists.freedesktop.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Diego_Nogu=C3=AAs?= <diego.sure@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793405899; l=6834;
 i=diego.sure@gmail.com; s=b4-20261031; h=from:subject:message-id;
 bh=mivr+SD0evGwt3zL4mnf5pZMx3+T3P91Jk3Y8+rPi2I=;
 b=TFlG30J/phmGFERmnvySjH3MkQNzNZWjt2ZwkbnYQX22jKOlNextfnyQ3fgsyqyGd6PScReG7
 vV1ayZvGw4xAHQGe/8mXouN1F4dDhKQ/zx6ASxcNE7yp+sGGSz1ssFO
X-Developer-Key: i=diego.sure@gmail.com; a=ed25519;
 pk=WA/ONeOf+US6DvvErKh2UIwm8jr+CuW7fzfTaCoLGvM=
X-Endpoint-Received: by B4 Relay for diego.sure@gmail.com/b4-20261031 with auth_id=1368
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On an Alder Lake host (i7-1265U) with a Thunderbolt 4 dock (Dell WD22TB4,
Goshen Ridge) driving two 4K@60 monitors through two DP tunnels, the
monitor whose tunnel is created second is limited to 4K@30. Which monitor
is affected depends only on the order in which they are powered on.

The thunderbolt driver enables the BW allocation mode (BWA) on both DP IN
adapters: it sets the CM BWA support (DP_USB4_DRIVER_BW_CAPABILITY), a
group ID and the estimated BW. The DP IN adapter, however, never sets
DP_IN_BW_ALLOCATION_MODE_SUPPORT in DP_TUNNELING_CAPABILITIES (0xe000d
reads 0x01), so tunnel_regs_are_valid() rejects the tunnel with:

  DPTUN: A non-zero group ID is only allowed with BWA support

i915 then falls back to the static allocation. The first tunnel reserves
the full DPRX bandwidth (HBR3 x4, 25920 Mb/s), although its stream needs
about 8.4 Gb/s, and the thunderbolt driver reduces the second tunnel to
HBR x4 (8640 Mb/s), which is not enough for 4K@60.

The DP IN adapter does handle the BWA registers. Setting
DP_DISPLAY_DRIVER_BW_ALLOCATION_MODE_ENABLE in
DP_DPTX_BW_ALLOCATION_MODE_CONTROL by hand sets DPME in the adapter's
ADP_DP_CS_8, and a following write to DP_REQUEST_BW reaches the
thunderbolt driver as a DP_BW notification, gets allocated and is
acknowledged with DP_BW_REQUEST_SUCCEEDED. Reading back
DP_DPTX_BW_ALLOCATION_MODE_CONTROL returns 0, which the helpers already
tolerate. The adapter identifies itself as OUI 98-4f-ee, DevID "TR",
HW rev 13.0, SW rev 2.1.

The connection manager programs a non-zero group ID only right after
enabling BWA on a DP IN adapter that supports it (see
tb_dp_bandwidth_alloc_mode_enable()). So when the USB4 driver advertises
BWA support and a group ID is assigned, treat the tunnel as BWA capable
even if the DP IN adapter does not set DP_IN_BW_ALLOCATION_MODE_SUPPORT.
Nothing changes for adapters that set the flag or for tunnels without a
group ID; the only affected case is the one rejected today.

With this change, and an unmodified thunderbolt driver, i915 enables BWA
on both tunnels and allocates 8500 Mb/s for the stream behind the dock's
MST hub (using DSC) and 13000 Mb/s for the other one, so both monitors
run at 4K@60 in either power-on order.

Fixes: 295654f7e554 ("drm/dp: Add support for DP tunneling")
Closes: https://gitlab.freedesktop.org/drm/i915/kernel/-/work_items/17742
Cc: Imre Deak <imre.deak@intel.com>
Cc: Mika Westerberg <westeri@kernel.org>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Diego Noguês <diego.sure@gmail.com>
---
RFC, for two reasons:

- I don't know whether DP_IN_BW_ALLOCATION_MODE_SUPPORT is left clear on
  purpose on this adapter (for instance because of a known BWA issue on
  Alder Lake). If so, please say so and this patch should be dropped.
- If the approach is fine, a DPCD quirk keyed on the adapter's ID
  (OUI 98-4f-ee, DevID "TR") may be preferred over relaxing the check for
  every adapter. I can rework it that way.

If it is accepted, I think it is a candidate for stable (v6.9+).

Tested on a Dell Latitude 5430 (i7-1265U, BIOS 1.41.0) with a Dell
WD22TB4 (package 01.01.03.01, USB4 NVM 41.81), a P2415Q on the dock's
Thunderbolt port (SST) and a U2718Q on a dock DP port (behind the dock's
VMM5331 MST hub). Kernel: Ubuntu 7.0.0-38, whose drm_dp_tunnel.c is
identical to v7.0 and to current drm-tip, with only the patched
drm_display_helper module, over two weeks of daily use:

- Both power-on orders, with thunderbolt dyndbg and drm.debug=0x4: both
  monitors at 4K@60. With the stock module, whichever monitor comes up
  second is limited to 4K@30.
- Five dock unplug/replug cycles (the dock is shared with another
  machine): both monitors at 4K@60 every time.
- s2idle suspend/resume: BWA is enabled again on both tunnels after
  resume (13000 and 8750 Mb/s allocated, group 21750/34500 Mb/s), and both
  monitors run at 4K@60. With the stock module, the second tunnel is
  limited to 4K@30 again after resume.

Unrelated to this patch, and reproduced the same way with the stock
module: after s2idle resume the thunderbolt driver re-pairs the DP IN and
DP OUT adapters the other way round, so the MST hub moves from DDI TC1 to
DDI TC2. i915 then logs "Sending link address failed with -5" and "Step 2
of creating MST payload ... failed: -22", and the external displays stay
dark until the outputs are configured again from userspace. I can report
that separately.

Not tested: other hosts (Tiger Lake, Meteor Lake and later), other docks,
the xe driver.

Tool use: I used an AI coding assistant (Claude Code, model
claude-opus-5-5). I asked it why the second monitor was stuck at 30 Hz and
how to fix it in the kernel. It read the thunderbolt and drm_dp_tunnel
sources, analyzed the logs I captured, wrote the shell scripts I used for
the manual DPCD reads and writes, proposed this change and drafted this
description. I ran all the tests on my hardware and reviewed the change.
---
 drivers/gpu/drm/display/drm_dp_tunnel.c | 22 ++++++++++++++++++----
 1 file changed, 18 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/display/drm_dp_tunnel.c b/drivers/gpu/drm/display/drm_dp_tunnel.c
index d29ad4116e64..71dfa4714795 100644
--- a/drivers/gpu/drm/display/drm_dp_tunnel.c
+++ b/drivers/gpu/drm/display/drm_dp_tunnel.c
@@ -317,13 +317,27 @@ static int tunnel_reg_max_dprx_lane_count(const struct drm_dp_tunnel_regs *regs)
 
 static bool tunnel_reg_bw_alloc_supported(const struct drm_dp_tunnel_regs *regs)
 {
-	u8 cap_mask = DP_TUNNELING_SUPPORT | DP_IN_BW_ALLOCATION_MODE_SUPPORT;
+	u8 caps = tunnel_reg(regs, DP_TUNNELING_CAPABILITIES);
 
-	if ((tunnel_reg(regs, DP_TUNNELING_CAPABILITIES) & cap_mask) != cap_mask)
+	if (!(caps & DP_TUNNELING_SUPPORT))
 		return false;
 
-	return tunnel_reg(regs, DP_USB4_DRIVER_BW_CAPABILITY) &
-	       DP_USB4_DRIVER_BW_ALLOCATION_MODE_SUPPORT;
+	if (!(tunnel_reg(regs, DP_USB4_DRIVER_BW_CAPABILITY) &
+	      DP_USB4_DRIVER_BW_ALLOCATION_MODE_SUPPORT))
+		return false;
+
+	/*
+	 * Some DP IN adapters (at least on Alder Lake) don't set
+	 * DP_IN_BW_ALLOCATION_MODE_SUPPORT, although they do support the BW
+	 * allocation mode. The USB4 Connection Manager assigns a group ID
+	 * only after enabling the BW allocation mode on the DP IN adapter,
+	 * so accept a non-zero group ID as an indication of support.
+	 */
+	if (!(caps & DP_IN_BW_ALLOCATION_MODE_SUPPORT) &&
+	    !tunnel_reg_drv_group_id(regs))
+		return false;
+
+	return true;
 }
 
 static bool tunnel_reg_bw_alloc_enabled(const struct drm_dp_tunnel_regs *regs)

---
base-commit: 24a19b953e2a3d0ea5a8c4951a0ab8f32720c907
change-id: 20261031-dp-tunnel-bwa-flag-2670b4d43381

Best regards,
--  
Diego Noguês <diego.sure@gmail.com>

