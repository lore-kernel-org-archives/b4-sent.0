From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Subject: [PATCH meta-virtualization 0/2] Two small changes for podman
Date: Thu, 23 Apr 2026 23:02:03 +0200
Message-Id: <20260423-podman-fixes-v1-0-3ffa0badf612@belden.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMuI6mkC/x2MsQqDQAxAf0UyN2CjqHQrXTp26CYOwYttoJ5yd
 xVR/PeGjo/HeztECSoRLtkOQRaNOnmD8ymD/s3+JajOGCinKi+pwHlyI3scdJWIjRBTXZV9MTi
 wZA7yF1a0MEpiXDSkL39042Tnrn1cn7c7dMfxA7IICa16AAAA
To: meta-virtualization@lists.yoctoproject.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776978137; l=513;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=l9xKUXmdY3AVrlbSL89+dTSiInclADC2i2QxT4/r3/Q=;
 b=SfKeMvuKnnvpm0rEmgZ8P4es4c/5ozTRTO2xC7mJOIMBeOnhdZSPx2pNyfaqlgqEviOZ3sC+L
 2WmWUKtvf21DklZFD8woejFZDUHEqZrVOIpj3c21wuVQsoVr13zhGDf
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

First one is a bugfix and the second one more of a cosmetic change.

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
Patrick Vogelaar (2):
      podman: fix PV to right version
      podman: update SRC_URI

 recipes-containers/podman/podman_git.bb | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
---
base-commit: 2e0704ee9282e4e86c13180334cb7ce118e55dd9
change-id: 20260423-podman-fixes-8e2a2764c3fd

Best regards,
-- 
Patrick Vogelaar <patrick.vogelaar@belden.com>

