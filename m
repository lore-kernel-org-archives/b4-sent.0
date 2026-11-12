From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] pmdomain: rockchip: fix the probe error and
 deferral paths
Date: Thu, 12 Nov 2026 08:23:28 +0000
Message-Id: <20261112-pmdomain-rockchip-v2-0-5cd942a23df7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OS27EIBBEr2KxDhFgaGyvco9oFjQ0Y5L4E/BYi
 UZz9+DxPpuWSqp+9e6sUE5U2NDcWaY9lbTMNaiXhvnRzVfiKdTMlFAgpRR8ncIyuTTzvPhPP6a
 Vt7q3TpGNIRpW/9ZMMf08me+XM5cbfpDfDtDRGFPZlvz7HN3l0fuPv0suOGAfHRA618HbtRa+X
 v0yscvjHMj0favu27nKVrf5sZoPjVdReEMIYGR9tlpHgFargPV2xgF0JqKVhxa6QrxSp7QNjdX
 WkOvQdCAB29YL7SL2FnwUsZJCHwK0EavC4w/gnlXvRgEAAA==
X-Change-ID: 20261110-pmdomain-rockchip-3497a2e7fdf5
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Igor Pecovnik <igor@armbian.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471809; l=5076;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=bdn8cYKKzKlZzz1UfUin4coRd279HYZJRzRpgBrt3p4=;
 b=85fXcymigcazjcdaZJGpvrxzTEvntfsmiXgH3L8DtL0aIS9YckTLoTa3z70D3YMPl1clEnnBl
 8nvbJ4WDTlpBqhDCtp1nc5ldIu7WjGvAyD2U/owR8dnZdVkzi+esN9R
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for what happens when a Rockchip power domain clock is not
available yet and rockchip_pm_domain_probe() defers. They are based on
patch 1/2 "pmdomain: rockchip: Only put clocks that have been
successfully obtained" of Yao Zi's series [1], which fixes the
WARN_ON_ONCE() in __clk_put() on that path and has to be applied first.

1. The error cleanup removes the parent/child links before the domains.
   pm_genpd_remove() refuses a domain that is still a parent, and on
   RK3588 (RKVDEC0/1 are children of both VCODEC and VDPU) no ordering
   avoids that, so devm freed domains that were still on gpd_list.
2. Errors are reported once, where they happen, with dev_err_probe().
   A deferral is no longer printed as an error, once per probe attempt
   by rockchip_pm_add_one_domain() and once or twice by its callers,
   its reason is recorded for devices_deferred, and the paths that
   relied on the callers' message (clk_bulk_prepare(), pm_qos) now say
   what failed.

Patch 2 supersedes patch 2/2 "pmdomain: rockchip: Don't log when
of_clk_get() fails with -EPROBE_DEFER" of [1]. That patch keeps the
callers' messages and skips them for -EPROBE_DEFER, as v1 of this patch
did; in the review of v1 Sebastian asked to drop the callers' messages
and use dev_err_probe() in the error paths instead, which is what patch
2 does, including the of_clk_get() path that 2/2 of [1] converts.

Tested on an Orange Pi 5 (RK3588S) with v1 of this series on a v7.3
based kernel, with a test device tree that gives PD_FEC a clock which
only appears about 26 s into boot. PD_FEC is nested under PD_VI and is
reached after 18 domains and their links were registered, so every
deferral runs the cleanup with nested domains present. devices_deferred
shows "failed to get clk at index 5", there is no "failed to remove
domain", list or slab corruption report (booted with page_poison=1
init_on_free=1), no "-517" error lines, and the controller binds later
with each of the 26 domains listed once in pm_genpd_summary. The same
late clock on PD_NPU (the first domain, so nothing is registered yet
when it defers) was only booted without these two patches; those boots
are where the "-517" lines quoted in patch 2 come from. A host-side
model of the probe and cleanup on the board's DTB, deferring at each
domain in turn, leaves freed domains on gpd_list at 24 of 26 failure
points without patch 1 and at none with it.

[1] https://lore.kernel.org/r/20261105001257.1368266-1-me@ziyao.cc

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code of both patches and the commit messages, and I
reviewed every change and tested it as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v2:
- Dropped 1/3 "pmdomain: rockchip: put only the clocks that were got on
  error" (Igor Pecovnik) in favour of Yao Zi's earlier fix for the same
  bug, 1/2 of [1] (same Fixes tag, the same clocks are put). The series
  is now based on that patch, and the dev_err_probe() for a failed
  of_clk_get() that was part of the dropped patch is now in 2/2.
- 2/2 (was 3/3): drop the "failed to handle (subdomain) node" messages
  from the callers instead of skipping them for -EPROBE_DEFER, and
  report each error once where it happens with dev_err_probe(),
  including the clk_bulk_prepare() and pm_qos paths that relied on the
  callers' message; new subject (Sebastian Reichel)
- 2/2: a failed syscon_node_to_regmap() for a pm_qos node now returns
  its own error (it can be -EPROBE_DEFER) instead of -ENODEV
- 1/2 (was 2/3): unchanged
- Cc Yao Zi
- Not re-tested on the board. For the tested case (-EPROBE_DEFER from
  of_clk_get()) v2 differs from what was tested only in where the
  clocks are put (the err_put_clocks label, 1/2 of [1], instead of next
  to of_clk_get()) and in the callers' messages, which v1 skipped for
  -EPROBE_DEFER and v2 no longer has. The other changes in 2/2 are on
  error paths the test did not reach. v2 is build-tested (W=1, arm64).
- Based on v7.4-rc2; with 1/2 of [1] the series applies to the pmdomain
  fixes branch as is. On the next branch, 1/2 of [1] conflicts with
  "pmdomain: rockchip: cycle an optional power-domain reset on power-on"
  (a reset_control_put() added after the changed line), and 2/2
  conflicts with it in context only; git am -3 resolves the latter.
- Link to v1: https://patch.msgid.link/20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com

---
Arun Iyengar (2):
      pmdomain: rockchip: remove subdomain links before the domains on error
      pmdomain: rockchip: report domain errors once, with dev_err_probe()

 drivers/pmdomain/rockchip/pm-domains.c | 144 ++++++++++++++++++++-------------
 1 file changed, 89 insertions(+), 55 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261110-pmdomain-rockchip-3497a2e7fdf5
prerequisite-patch-id: c2f0c5eb6651baa744f66342db63485a6685fb71

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

