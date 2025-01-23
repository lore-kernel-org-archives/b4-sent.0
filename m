From: =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
Date: Thu, 23 Jan 2025 17:34:25 +0100
Subject: =?utf-8?q?=5BPATCH=5D_MAINTAINERS=3A_Remove_Noralf_Tr=C3=B8nnes_?=
 =?utf-8?q?as_driver_maintainer?=
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250123-remove-myself-as-maintainer-v1-1-cc3ab7cd98ae@tronnes.org>
X-B4-Tracking: v=1; b=H4sIAJBvkmcC/x3MQQqDQAxG4atI1g2MwUHwKtLF2P62AWcsSZEW8
 e4OLt7i27ydHKZwGpqdDJu6rqWivTX0eKfyAuuzmiRIDK0IG/K6gfPfscycnHPS8q3BuI9dmKS
 LaQqR6uFjmPV33cf7cZwk2hpgbQAAAA==
X-Change-ID: 20250122-remove-myself-as-maintainer-7540b245ab05
To: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org
Cc: =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737650092; l=2162;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=sRUeNf6klT+wIBzNm//9sMgiGRipBFhrw3r7FEK3L0s=;
 b=OrBeu5/cX00/bMfAe91MyuliFg1iUdvlj4rGD1GChl6gzYjhRa7sDL/NR6VJW/ATi4IQjdlve
 Un9PJWdyd3SDm6Ld0OJc4I7GylzXT7vxa1x5YOzbfQzSgkyjFSC8gt8
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Relay for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove myself as maintainer for gud, mi0283qt, panel-mipi-dbi and repaper.
My fatigue illness has finally closed the door on doing development of
even moderate complexity so it's sad to let this go.

Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
 MAINTAINERS | 12 ++++--------
 1 file changed, 4 insertions(+), 8 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4b038382481f99e336a2de0d2249537ec6781463..ed86d884ee0dfeede2ee185f7779380d04c5080b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -7173,8 +7173,7 @@ F:	Documentation/devicetree/bindings/display/panel/panel-edp.yaml
 F:	drivers/gpu/drm/panel/panel-edp.c
 
 DRM DRIVER FOR GENERIC USB DISPLAY
-M:	Noralf Trønnes <noralf@tronnes.org>
-S:	Maintained
+S:	Orphan
 W:	https://github.com/notro/gud/wiki
 T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
 F:	drivers/gpu/drm/gud/
@@ -7279,15 +7278,13 @@ T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
 F:	drivers/gpu/drm/mgag200/
 
 DRM DRIVER FOR MI0283QT
-M:	Noralf Trønnes <noralf@tronnes.org>
-S:	Maintained
+S:	Orphan
 T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
 F:	Documentation/devicetree/bindings/display/multi-inno,mi0283qt.txt
 F:	drivers/gpu/drm/tiny/mi0283qt.c
 
 DRM DRIVER FOR MIPI DBI compatible panels
-M:	Noralf Trønnes <noralf@tronnes.org>
-S:	Maintained
+S:	Orphan
 W:	https://github.com/notro/panel-mipi-dbi/wiki
 T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
 F:	Documentation/devicetree/bindings/display/panel/panel-mipi-dbi-spi.yaml
@@ -7384,8 +7381,7 @@ F:	Documentation/devicetree/bindings/display/bridge/ps8640.yaml
 F:	drivers/gpu/drm/bridge/parade-ps8640.c
 
 DRM DRIVER FOR PERVASIVE DISPLAYS REPAPER PANELS
-M:	Noralf Trønnes <noralf@tronnes.org>
-S:	Maintained
+S:	Orphan
 T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
 F:	Documentation/devicetree/bindings/display/repaper.txt
 F:	drivers/gpu/drm/tiny/repaper.c

---
base-commit: a9301e5bef12f8989a02d886109f13e89e1e51b0
change-id: 20250122-remove-myself-as-maintainer-7540b245ab05

Best regards,
-- 
Noralf Trønnes <noralf@tronnes.org>

