From: Sam Day <me@samcday.com>
Date: Sat, 27 Jun 2026 22:18:45 +1000
Subject: [PATCH RFC] drm/msm/mdss: keep mdp1-mem interconnect alive during
 suspend on SDM845
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260627-rfc-sdm845-interconnect-collapse-workaround-v1-1-608a38de3715@samcday.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NPQ7CMAxA4atUnrHUlhIqVqQegBUxBMcBi+JUT
 vmRqt6diPFb3lsgswlnOFQLGL8lS9KCZlMB3b3eGCUUQ1u3rnbtHi0S5vDsux2KzmyUVJlmpDS
 OfsqMn2QPb+mlAa++odh3jvw2QilOxlG+/9sZTsMRLuv6A65c+oGCAAAA
X-Change-ID: 20260627-rfc-sdm845-interconnect-collapse-workaround-ba1cf846ca3f
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782562727; l=3411;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=BMiudGPsxROy8BnSvYjoc4O7qJ+BrrRqh/a8bYRWcC0=;
 b=PsiWZuMwX4x8LrKzl/Bcpfpzq6k3TOSP+hKPP+Lr33iH54+T1jbS5Lx9oIUOWAal8GqgdqqRe
 4sGzPTD4htnBmYL4x356+P81ZtZfsL07HxZUmvi3bp68XLqVc1LCe6q
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the peak vote for mdp1-mem is allowed to drop to zero, it seems to
cause the fabric to collapse that path entirely, which causes the device
to bus stall and fatally reset.

This issue was identified specifically on sdm845-oneplus-fajita, so this
workaround is applied narrowly to SDM845's MDSS.

---
This RFC patch is a spiritual successor to the "Addressing stability
issues on SDM845 with the -next tree" series sent by David and Petr 6
months ago.

As Dmitry pointed out, the patch introduces leakages to the runtime PM
refcounting. In practice, this means that MDSS never actually gets
suspended, which is why the patch appeared to "fix" the issue.

The deeper root cause is that, when msm_mdss_disable() runs and unvotes
the mdp1-mem interconnect bandwidth, that seems to collapse the fabric
entirely and causes the bus stall -> hang -> reboot behaviour.

I've confirmed that a tiny non-zero peak bandwidth vote keeps the fabric
alive and avoids the issue.

Of course, this is still a fairly egregious hack, but it *does* allow
blanking to suspend and resume DSI + DPU + MDSS properly without the bus
stall.

Here's what I've validated with instrumentation:

 * DSI host disable, IRQ disable, PLL state save, host power-off, link
   clock disable, regulator disable, SFPB disable, and PHY disable all
   complete successfully before the fatal reset occurrs.
 * DPU runtime suspend also completes. The bandwidth accounting was
   checked and confirmed to reach runtime suspend with 0 refs, with no
   pending frame state.
 * The device survives through MDSS clock disabling and mdp0-mem
   zero voting, it's really just the mdp1-mem zero vote that is isolated
   as the cause of the stall + reset.

So, I'm not really sure where to go from here. I'm sure that this
workaround is not suitable for inclusion upstream as it still seems to
be papering over an underlying issue... But it's unclear to me if this is
some kind of hardware quirk on SDM845, a problem with the SDM845 DT
wiring, a driver issue, or something else entirely.

I'd appreciate any advice on how to further diagnose this issue and what
direction to take from here.

Kind regards,
-Sam

Link: https://lore.kernel.org/phone-devel/20251213-stability-discussion-v1-0-b25df8453526@ixit.cz/
Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/gpu/drm/msm/msm_mdss.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/msm/msm_mdss.c b/drivers/gpu/drm/msm/msm_mdss.c
index 9087c4b290db..c635380b2ac3 100644
--- a/drivers/gpu/drm/msm/msm_mdss.c
+++ b/drivers/gpu/drm/msm/msm_mdss.c
@@ -284,8 +284,12 @@ static int msm_mdss_disable(struct msm_mdss *msm_mdss)
 
 	clk_bulk_disable_unprepare(msm_mdss->num_clocks, msm_mdss->clocks);
 
-	for (i = 0; i < msm_mdss->num_mdp_paths; i++)
-		icc_set_bw(msm_mdss->mdp_path[i], 0, 0);
+	for (i = 0; i < msm_mdss->num_mdp_paths; i++) {
+		if (of_device_is_compatible(msm_mdss->dev->of_node, "qcom,sdm845-mdss") && i == 1)
+			icc_set_bw(msm_mdss->mdp_path[i], 0, 1);
+		else
+			icc_set_bw(msm_mdss->mdp_path[i], 0, 0);
+	}
 
 	if (msm_mdss->reg_bus_path)
 		icc_set_bw(msm_mdss->reg_bus_path, 0, 0);

---
base-commit: 5a66900afbd6b2a063eebad35294038a654de2b0
change-id: 20260627-rfc-sdm845-interconnect-collapse-workaround-ba1cf846ca3f

Best regards,
-- 
Sam Day <me@samcday.com>

