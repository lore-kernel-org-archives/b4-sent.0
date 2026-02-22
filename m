From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH RFC 0/2] drm/panel: Add panel driver for ChipWealth
 CH13726A based panels
Date: Sun, 22 Feb 2026 16:26:21 -0600
Message-Id: <20260222-ch13726a-v1-0-e501d78e105a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02OywrCMBBFf6XM2kBn0kkfW8EPcCsu0sxUs7DVt
 BZF/HeLiri8Dw7nAaOmqCM02QOSznGMQ78EXGUQjr4/qImyZKCcXE6Um3BEW5LzhuvgXFkJW6l
 guZ+TdvH2Ru1gu1nD/lMmvVwX7PRdWj+qCcPpFKcm67RWq9I6T8iMLIhFJZY8h6LgwK1IWaPr4
 F+nyX4y/t6bWXsZkvHIFl0VqG6pmRH2z+cLoxZ8i90AAAA=
X-Change-ID: 20260220-ch13726a-59c6678d53d8
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771799301; l=1537;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=TCIGixUhPyc/6Ro93xL9qSO+umxyc2HQT+H3bVMe/C0=;
 b=rvuCTiLbZy3EM+/1YR1yOEHTd5chLZ1ZaOcCiH44aWtS8Ub3VDjbZAJYDn05lS5aPLW4eZFRM
 3aMBaFSNf5VA8zRTx3VrpliWirfgwajVbtDo9kt0dOUUQkxxOep19Cd
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is marked RFC because there is no ongoing maintainer to
list. I am willing to put in the effort to get this submitted in a good
and maintainable state, but I cannot promise ongoing support for it. I
see that Neil Armstrong is listed at the general panel maintainer. Is it
okay to list you in the binding? If not, is there someone willing to
take over once this is approved for merge? There are three more new
panel drivers related to AYN qcs8550 support as well.

This driver is based on the one by Teguh Sobirin [0], cut down to only
support the AYN Thor bottom panel.

[0] https://github.com/AYNTechnologies/linux/commit/d0ff75b09e66023c5f88992706dee4601aa7a437

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (1):
      dt-bindings: display: panel: Add ChipWealth CH13726A AMOLED driver bindings

Teguh Sobirin (1):
      drm/panel: Add panel driver for ChipWealth CH13726A based panels

 .../display/panel/chipwealth,ch13726a.yaml         |  66 +++++
 drivers/gpu/drm/panel/Kconfig                      |  11 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c  | 296 +++++++++++++++++++++
 4 files changed, 374 insertions(+)
---
base-commit: fe9e3edb6a215515d1148d32a5c445c5bdd7916f
change-id: 20260220-ch13726a-59c6678d53d8
prerequisite-change-id: 20260220-ayn-vendor-a153168c29b2:v1
prerequisite-patch-id: 042cab8f04748207ba5395dd0f23c445955aaa2b

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

