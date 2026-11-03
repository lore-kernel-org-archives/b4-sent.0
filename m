From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 13:28:05 -0600
Subject: [PATCH 5/5] drm/nouveau: don't let an IRQ_HPD hide a plug or
 unplug event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-fixes-v1-5-892f4bd357cd@thelittleman.net>
References: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
In-Reply-To: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>, Ben Skeggs <bskeggs@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 "David R. Hedges" <linuxdev844@thelittleman.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793734092; l=1736;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=tP85nBIrptt737aDB86qPgSupi2I6nalDmVpTjCbdVo=;
 b=XrppRfVCwBqBGeUwfkz8GLy3LuTrae24FAi6dAaSGrRH9AN/7b/thlU74Ss42oEYKgGLOI7M+
 be1rwk3vWEvCfRM2HKXHOwK6PvMEO1zHF6IZ3apGnLWEA6nS05gtEAi
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nouveau_dp_irq() passes an IRQ_HPD to the HPD worker as
NVIF_CONN_EVENT_V0_IRQ, adding NVIF_CONN_EVENT_V0_PLUG when the sink
count has changed, or NVIF_CONN_EVENT_V0_UNPLUG when servicing an MST
hub fails.  A real plug or unplug can also be pending in the same bits
by the time the worker runs.  nouveau_display_hpd_work() skips
connector detection for anything with the IRQ bit set, though, as long
as nouveau_dp_link_check() reports the link as fine, which it does
whenever there's no trained link to look at, so those plug and unplug
events are dropped.

Only take the link check shortcut for an IRQ_HPD on its own.

Fixes: 016dacb60e6d ("drm/nouveau/kms: pass event mask to hpd handler")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/nouveau_display.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/nouveau/nouveau_display.c b/drivers/gpu/drm/nouveau/nouveau_display.c
index d71dcfc6ee66..4398cf0fc541 100644
--- a/drivers/gpu/drm/nouveau/nouveau_display.c
+++ b/drivers/gpu/drm/nouveau/nouveau_display.c
@@ -462,7 +462,12 @@ nouveau_display_hpd_work(struct work_struct *work)
 			    !!(bits & NVIF_CONN_EVENT_V0_UNPLUG),
 			    !!(bits & NVIF_CONN_EVENT_V0_IRQ));
 
-		if (bits & NVIF_CONN_EVENT_V0_IRQ) {
+		/* A plug or unplug event pending alongside the IRQ, such as a
+		 * sink count change reported by nouveau_dp_irq(), still needs
+		 * connector detection.
+		 */
+		if ((bits & NVIF_CONN_EVENT_V0_IRQ) &&
+		    !(bits & (NVIF_CONN_EVENT_V0_PLUG | NVIF_CONN_EVENT_V0_UNPLUG))) {
 			if (nouveau_dp_link_check(nv_connector))
 				continue;
 		}

-- 
2.55.0

