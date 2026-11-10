From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/3] pmdomain: rockchip: fix the probe error and deferral
 paths
Date: Tue, 10 Nov 2026 07:11:27 +0000
Message-Id: <20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw7CIBBA0V9pZl0SwAfRX2m6QBhkbHgE1JgQ/
 l2qy7O4t0HFQljhOjUo+KZKKQ6IeQLjdbwjIzsMksuzEIKzHGwKmiIryWzGU2aH40VpicpZd4L
 R5YKOPr/nsv5dX7cHmuc+gt6/gIeeoHUAAAA=
X-Change-ID: 20261110-pmdomain-rockchip-3497a2e7fdf5
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Pecovnik <igor@armbian.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294687; l=2416;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=QoAWdAEzgzL2QuwNz+wZsYoa/Z9SPuRCylTlgEE4RjA=;
 b=hCUZhEAiVVHPN/W3DReqR0LhracBQIiJ4fAnU+xZMyzjHjLbDahebbYCC/AKHaoQzU/BzHuRw
 ZlMANOkzg5rDQdFKewNmpFmG51NPTFrZVQtx0WuhpcE1gMJ81cTt/D8
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three fixes for what happens when a Rockchip power domain clock is not
available yet and rockchip_pm_domain_probe() defers:

1. (Igor Pecovnik) Only the clocks that were obtained are put; the
   ERR_PTR() of the failing one triggered the WARN_ON_ONCE() in
   __clk_put(), and the deferral reason was not recorded.
2. The error cleanup removes the parent/child links before the domains.
   pm_genpd_remove() refuses a domain that is still a parent, and on
   RK3588 (RKVDEC0/1 are children of both VDEC and VDPU) no ordering
   avoids that, so devm freed domains that were still on gpd_list.
3. A deferral is no longer printed as an error by the callers, once
   per probe attempt and twice for a nested domain.

Tested on an Orange Pi 5 (RK3588S) with test device trees that give a
power domain a clock which only appears about 26 s into boot, once on
PD_NPU (a top level domain) and once on PD_FEC (nested under PD_VI,
after 18 domains and their links were registered). With the series,
devices_deferred shows "failed to get clk at index 5", there is no
"failed to remove domain", list or slab corruption report (booted with
page_poison=1 init_on_free=1), no "-517" error lines, and the controller
binds later with each of the 26 domains listed once in
pm_genpd_summary. A host-side model of the probe and cleanup on the
board's DTB, deferring at each domain in turn, leaves freed domains on
gpd_list at 24 of 26 failure points without patch 2 and at none with
it. Normal boots are unchanged.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code of patches 2 and 3 and the commit messages, and I
reviewed and tested every change as described above. Patch 1 is Igor's
change with a rewritten commit message.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (2):
      pmdomain: rockchip: remove subdomain links before the domains on error
      pmdomain: rockchip: do not report probe deferral of a domain as an error

Igor Pecovnik (1):
      pmdomain: rockchip: put only the clocks that were got on error

 drivers/pmdomain/rockchip/pm-domains.c | 73 +++++++++++++++++++++++++++++-----
 1 file changed, 62 insertions(+), 11 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261110-pmdomain-rockchip-3497a2e7fdf5

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

