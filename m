From: Kylie C <kyliepc@proton.me>
Date: Thu, 22 Oct 2026 09:30:38 -0400
Subject: [PATCH] drm/amd/display: Don't select zero V_TOTAL_MIN/MAX on DCN2
 seamless boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-dcn2-seamless-vtotal-v1-1-6ceb87f98629@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZOS/QRifiq8gOXZNpZHbSdEMYe
 3erHr/D/29gklUMLs0GWVY1nVOFbxuI95BugsrVQI5O3hEhx0RoEp6TmOFa5hImPHSe3ZmJx+4
 INX1lGfX92177v20ZHhLL9wX7/gE8A/SNeAAAAA==
X-Change-ID: 20261022-dcn2-seamless-vtotal-351d08d2df54
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Kylie C <kyliepc@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792675851; l=1577;
 i=kyliepc@proton.me; s=20261022; h=from:subject:message-id;
 bh=E3b6PcfPUilGy4eYSVtJ/EqKpq1VZvJ1nhCA//JGxdU=;
 b=LrrKoFxk1Om3OmiLoo28vF48JCMXdd3ru7QQl5pl++6C/ufZ2XgsqRdZquDPC+Mz+7FliTljS
 bJleZsBuTJpBZSVEvjnsQC44W2F3xz+jUZhp6SP2UKYfKJSE1EcInDA
X-Developer-Key: i=kyliepc@proton.me; a=ed25519;
 pk=T/yRT5OdlaWnEmvYU6894i5NEH44SmsyRlMNTde5DDs=
X-Endpoint-Received: by B4 Relay for kyliepc@proton.me/20261022 with auth_id=1285
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initialize V_TOTAL_MIN/MAX to V_TOTAL before enabling the selectors if
they are still 0, as optc1_program_timing() does without seamless boot.

Tested on Renoir (DCN 2.1) eDP with amdgpu.seamless=1.

This removes the flash between the bios logo & plymouth on my laptop.

Signed-off-by: Kylie C <kyliepc@proton.me>
---
Fixes the black screen when enabling amdgpu.seamless=1 on Renoir APU

With this plymouth smooth boot is possible on this hardware
---
 drivers/gpu/drm/amd/display/dc/optc/dcn20/dcn20_optc.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/dc/optc/dcn20/dcn20_optc.c b/drivers/gpu/drm/amd/display/dc/optc/dcn20/dcn20_optc.c
index 73cc8a713..2cdfe3d7a 100644
--- a/drivers/gpu/drm/amd/display/dc/optc/dcn20/dcn20_optc.c
+++ b/drivers/gpu/drm/amd/display/dc/optc/dcn20/dcn20_optc.c
@@ -449,6 +449,13 @@ void optc2_lock_doublebuffer_disable(struct timing_generator *optc)
 void optc2_setup_manual_trigger(struct timing_generator *optc)
 {
 	struct optc *optc1 = DCN10TG_FROM_TG(optc);
+	uint32_t v_total, v_total_max;
+
+	REG_GET(OTG_V_TOTAL_MAX, OTG_V_TOTAL_MAX, &v_total_max);
+	if (!v_total_max) {
+		REG_GET(OTG_V_TOTAL, OTG_V_TOTAL, &v_total);
+		optc->funcs->set_vtotal_min_max(optc, v_total, v_total);
+	}
 
 	/* Set the min/max selectors unconditionally so that
 	 * DMCUB fw may change OTG timings when necessary

---
base-commit: 77f548b127c6de34ce271fa09ba270cb1ef9f2da
change-id: 20261022-dcn2-seamless-vtotal-351d08d2df54

Best regards,
--  
Kylie C <kyliepc@proton.me>

